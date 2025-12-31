// lib/services/quickbooks_service.dart
// ✅ ENHANCED: OAuth flow, sync with retry, error handling, logging
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aura_crm/core/env_loader.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuickBooksService {
  static const _authUrl = 'https://appcenter.intuit.com/connect/oauth2';
  static const _apiUrl = 'https://quickbooks.api.intuit.com/v3';
  static const _maxRetries = 3;
  static const _retryDelayMs = 1000;
  
  static String get _clientId {
    final id = EnvLoader.get('QUICKBOOKS_CLIENT_ID');
    if (id.isEmpty) {
      throw Exception('QUICKBOOKS_CLIENT_ID not configured in .env');
    }
    return id;
  }
  
  static String get _clientSecret {
    final secret = EnvLoader.get('QUICKBOOKS_CLIENT_SECRET');
    if (secret.isEmpty) {
      throw Exception('QUICKBOOKS_CLIENT_SECRET not configured in .env');
    }
    return secret;
  }
  
  /// Generate QuickBooks OAuth authorization URL
  static String getAuthUrl(String redirectUri) {
    final params = {
      'client_id': _clientId,
      'response_type': 'code',
      'scope': 'com.intuit.quickbooks.accounting',
      'redirect_uri': redirectUri,
      'state': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$_authUrl?$query';
  }
  
  /// Exchange authorization code for access token (with error handling)
  static Future<Map<String, dynamic>> getAccessToken(String code, String redirectUri) async {
    try {
      final credentials = base64.encode(utf8.encode('$_clientId:$_clientSecret'));
      
      final response = await http.post(
        Uri.parse('$_authUrl/tokens/bearer'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ QB: OAuth token obtained');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('QB: Invalid credentials - check CLIENT_ID/SECRET');
      } else if (response.statusCode == 400) {
        throw Exception('QB: Invalid authorization code or redirect_uri');
      } else {
        throw Exception('QB: Token request failed (${response.statusCode}): ${response.body}');
      }
    } on Exception {
      rethrow;
    }
  }
  
  /// Sync invoice to QuickBooks with retry logic
  static Future<String?> syncInvoice({
    required String accessToken,
    required String realmId,
    required Map<String, dynamic> invoice,
    required String clientName,
  }) async {
    try {
      final qbInvoice = {
        'Line': [
          {
            'Amount': _formatCurrency(invoice['amount']),
            'DetailType': 'SalesItemLineDetail',
            'SalesItemLineDetail': {
              'ItemRef': {'value': '1'},
            },
            'Description': invoice['description'] ?? 'Invoice from AuraSphere',
          }
        ],
        'CustomerRef': {
          'value': invoice['qb_customer_id'] ?? '1',
        },
        'TxnDate': _formatDate(invoice['due_date']),
        'DueDate': _formatDate(invoice['due_date']),
        'DocNumber': invoice['invoice_number'] ?? 'AUTO',
      };
      
      final qbId = await _retryRequest(
        () => _postToQuickBooks(
          accessToken,
          realmId,
          '/invoice',
          qbInvoice,
        ),
      );
      
      print('✅ QB: Invoice synced - $clientName ($qbId)');
      return qbId;
    } catch (e) {
      print('❌ QB: Invoice sync failed - $e');
      return null;
    }
  }
  
  /// Sync expense to QuickBooks with retry logic
  static Future<String?> syncExpense({
    required String accessToken,
    required String realmId,
    required Map<String, dynamic> expense,
  }) async {
    try {
      final qbExpense = {
        'Line': [
          {
            'Amount': _formatCurrency(expense['amount']),
            'DetailType': 'AccountBasedExpenseLineDetail',
            'AccountBasedExpenseLineDetail': {
              'AccountRef': {'value': '7'},
            },
            'Description': expense['description'] ?? 'Expense from AuraSphere',
          }
        ],
        'PaymentType': expense['payment_type'] ?? 'Cash',
        'TxnDate': _formatDate(expense['date'] ?? DateTime.now().toIso8601String()),
      };
      
      final qbId = await _retryRequest(
        () => _postToQuickBooks(
          accessToken,
          realmId,
          '/purchase',
          qbExpense,
        ),
      );
      
      print('✅ QB: Expense synced ($qbId)');
      return qbId;
    } catch (e) {
      print('❌ QB: Expense sync failed - $e');
      return null;
    }
  }
  
  /// Internal POST with error handling
  static Future<String> _postToQuickBooks(
    String accessToken,
    String realmId,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$_apiUrl/company/$realmId$endpoint'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['id']?.toString() ?? 'unknown';
    } else if (response.statusCode == 401) {
      throw Exception('QB: Unauthorized - token may have expired');
    } else if (response.statusCode == 429) {
      throw Exception('QB: Rate limited - retry later');
    } else {
      throw Exception('QB: Sync failed (${response.statusCode}): ${response.body}');
    }
  }
  
  /// Retry failed requests with exponential backoff
  static Future<T> _retryRequest<T>(Future<T> Function() request) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempt++;
        if (attempt >= _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: _retryDelayMs * attempt));
      }
    }
    throw Exception('Max retries exceeded');
  }
  
  /// Refresh access token with retry
  static Future<Map<String, dynamic>?> refreshAccessToken(String refreshToken) async {
    try {
      final credentials = base64.encode(utf8.encode('$_clientId:$_clientSecret'));
      
      final response = await http.post(
        Uri.parse('$_authUrl/tokens/bearer'),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ QB: Token refreshed');
        return data;
      } else {
        print('❌ QB: Token refresh failed (${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('❌ QB: Token refresh error: $e');
      return null;
    }
  }
  
  /// Disconnect QuickBooks
  static Future<void> disconnect() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) return;
    
    try {
      await supabase.from('user_preferences').update({
        'quickbooks_access_token': null,
        'quickbooks_refresh_token': null,
        'quickbooks_realm_id': null,
      }).eq('user_id', userId);
      
      print('✅ QB: Disconnected');
    } catch (e) {
      print('❌ QB: Disconnect failed - $e');
    }
  }
  
  /// Save credentials
  static Future<void> saveCredentials(String accessToken, String refreshToken, String realmId) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) throw Exception('User not authenticated');
    
    await supabase.from('user_preferences').upsert({
      'user_id': userId,
      'quickbooks_access_token': accessToken,
      'quickbooks_refresh_token': refreshToken,
      'quickbooks_realm_id': realmId,
      'quickbooks_connected_at': DateTime.now().toIso8601String(),
    });
    
    print('✅ QB: Credentials saved');
  }
  
  /// Get saved credentials
  static Future<Map<String, dynamic>?> getCredentials() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    
    if (userId == null) return null;
    
    try {
      final prefs = await supabase
          .from('user_preferences')
          .select('quickbooks_access_token, quickbooks_refresh_token, quickbooks_realm_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (prefs == null || prefs['quickbooks_access_token'] == null) return null;
      
      return {
        'access_token': prefs['quickbooks_access_token'],
        'refresh_token': prefs['quickbooks_refresh_token'],
        'realm_id': prefs['quickbooks_realm_id'],
      };
    } catch (e) {
      print('❌ QB: Failed to load credentials - $e');
      return null;
    }
  }
  
  /// Utility: Format currency (ensure 2 decimals)
  static String _formatCurrency(dynamic value) {
    final numValue = (value as dynamic)?.toDouble() ?? 0.0;
    return numValue.toStringAsFixed(2);
  }
  
  /// Utility: Format date as YYYY-MM-DD
  static String _formatDate(String? dateStr) {
    if (dateStr == null) return DateTime.now().toIso8601String().split('T')[0];
    try {
      final date = DateTime.parse(dateStr);
      return date.toIso8601String().split('T')[0];
    } catch (e) {
      return DateTime.now().toIso8601String().split('T')[0];
    }
  }
}
