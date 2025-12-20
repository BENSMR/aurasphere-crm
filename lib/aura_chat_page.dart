// lib/aura_chat_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/aura_ai_service.dart';

class AuraChatPage extends StatefulWidget {
  const AuraChatPage({super.key});

  @override
  State<AuraChatPage> createState() => _AuraChatPageState();
}

class _AuraChatPageState extends State<AuraChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  String _userLang = 'en';

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    try {
      final prefs = await Supabase.instance.client
          .from('user_preferences')
          .select('language')
          .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
          .maybeSingle();
      if (mounted) {
        setState(() => _userLang = prefs?['language'] ?? 'en');
        _addMessage(_getWelcomeMessage(), false);
      }
    } catch (e) {
      // Default to English
      if (mounted) {
        _addMessage(_getWelcomeMessage(), false);
      }
    }
  }

  String _getWelcomeMessage() {
    switch (_userLang) {
      case 'fr':
        return 'Bonjour! Je suis Aura. Essayez: "Créer facture pour Acme Corp 1500 EUR"';
      case 'it':
        return 'Ciao! Sono Aura. Prova: "Crea fattura per Acme Corp 1500 EUR"';
      case 'de':
        return 'Hallo! Ich bin Aura. Versuchen Sie: "Rechnung für Acme Corp 1500 EUR erstellen"';
      case 'es':
        return 'Hola! Soy Aura. Prueba: "Crear factura para Acme Corp 1500 EUR"';
      case 'mt':
        return 'Bonġu! Jien Aura. Ipprova: "Oħloq fattura għal Acme Corp 1500 EUR"';
      case 'ar':
        return 'مرحباً! أنا أورا. جرب: "إنشاء فاتورة ل Acme Corp 1500 EUR"';
      default:
        return 'Hi! I\'m Aura. Try: "Create invoice for Acme Corp 1500 EUR"';
    }
  }

  String _getErrorMessage() {
    switch (_userLang) {
      case 'fr':
        return '🤔 Je peux aider avec:\n• "Facture Ahmed 300 AED"\n• "Dépense taxi 45 EUR"\n• "Liste factures"';
      case 'it':
        return '🤔 Posso aiutare con:\n• "Fattura Ahmed 300 AED"\n• "Spesa taxi 45 EUR"\n• "Lista fatture"';
      case 'de':
        return '🤔 Ich kann helfen mit:\n• "Rechnung Ahmed 300 AED"\n• "Ausgabe Taxi 45 EUR"\n• "Liste Rechnungen"';
      case 'es':
        return '🤔 Puedo ayudar con:\n• "Factura Ahmed 300 AED"\n• "Gasto taxi 45 EUR"\n• "Lista facturas"';
      case 'mt':
        return '🤔 Nista\' ngħin bi:\n• "Fattura Ahmed 300 AED"\n• "Spiża taxi 45 EUR"\n• "Lista fatturi"';
      case 'ar':
        return '🤔 يمكنني المساعدة في:\n• "فاتورة Ahmed 300 AED"\n• "مصروف سيارة أجرة 45 EUR"\n• "قائمة الفواتير"';
      default:
        return '🤔 I can help with:\n• "Bill Ahmed 300 AED"\n• "Expense taxi 45 EUR"\n• "List invoices"';
    }
  }

  void _addMessage(String text, bool isUser) {
    if (mounted) {
      setState(() {
        _messages.add({'text': text, 'isUser': isUser});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    _inputController.clear();
    _addMessage(input, true);

    // Show AI thinking
    if (mounted) {
      setState(() {
        _messages.add({'text': '...', 'isUser': false});
      });
    }

    try {
      // Process with AI agent
      final command = await AuraAiService.parseCommand(input, _userLang);
      
      if (command != null) {
        final result = await AuraAiService.executeAction(command);
        
        if (mounted) {
          setState(() {
            _messages.removeLast(); // Remove "..." message
          });
        }

        if (result['success'] == true) {
          _addMessage('✅ ${result['message']}', false);
          
          // If listing data, show it
          if (result['data'] != null) {
            final data = result['data'] as List;
            if (data.isEmpty) {
              _addMessage('No items found.', false);
            } else {
              for (var item in data.take(5)) {
                _addMessage('• ${_formatItem(item, command['action'])}', false);
              }
            }
          }
        } else {
          _addMessage('✗ Error: ${result['error']}', false);
        }
      } else {
        if (mounted) {
          setState(() {
            _messages.removeLast(); // Remove "..." message
          });
        }
        _addMessage(_getErrorMessage(), false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last['text'] == '...') {
            _messages.removeLast();
          }
        });
      }
      _addMessage('Error: $e', false);
    }
  }

  String _formatItem(Map<String, dynamic> item, String action) {
    switch (action) {
      case 'list_invoices':
        return '${item['invoice_number'] ?? item['number'] ?? 'N/A'} - ${item['clients']?['name'] ?? 'Unknown'} - ${item['amount']} ${item['currency']}';
      case 'list_clients':
        return '${item['name']} (${item['email'] ?? 'No email'})';
      case 'list_expenses':
        return '${item['description']} - ${item['amount']} ${item['currency']}';
      default:
        return item.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 8),
            Text('Aura AI Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Ask Aura anything...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
