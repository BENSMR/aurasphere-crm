/// Backend API proxy service
/// 
/// This service acts as a proxy for external API calls.
/// In production, use Supabase Edge Functions to handle these calls securely
/// without exposing API keys on the client side.
/// 
/// Usage:
/// 1. Create Edge Functions: groq-proxy, email-proxy, ocr-proxy
/// 2. Store API keys in Supabase secrets
/// 3. Update these methods to call your Edge Functions instead of direct APIs
library;

import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _logger = Logger();

class BackendApiProxy {
  static final BackendApiProxy _instance = BackendApiProxy._internal();
  
  factory BackendApiProxy() => _instance;
  
  BackendApiProxy._internal();

  final supabase = Supabase.instance.client;

  /// Call Groq LLM API through backend proxy
  /// Edge Function endpoint: /functions/v1/groq-proxy
  Future<Map<String, dynamic>> callGroqLLM({
    required String message,
    required String language,
    String model = 'mixtral-8x7b-32768',
  }) async {
    try {
      _logger.i('📤 Calling Groq LLM through backend proxy...');
      
      final response = await supabase.functions.invoke(
        'groq-proxy',
        body: {
          'message': message,
          'language': language,
          'model': model,
        },
      );

      _logger.i('✅ Groq LLM response received');
      return response as Map<String, dynamic>;
    } catch (e) {
      _logger.e('❌ Groq LLM proxy error: $e');
      rethrow;
    }
  }

  /// Send email through backend proxy
  /// Edge Function endpoint: /functions/v1/email-proxy
  Future<Map<String, dynamic>> sendEmail({
    required String to,
    required String subject,
    required String body,
    String? replyTo,
  }) async {
    try {
      _logger.i('📤 Sending email through backend proxy...');
      
      final response = await supabase.functions.invoke(
        'email-proxy',
        body: {
          'to': to,
          'subject': subject,
          'body': body,
          'replyTo': replyTo,
        },
      );

      _logger.i('✅ Email sent successfully');
      return response as Map<String, dynamic>;
    } catch (e) {
      _logger.e('❌ Email proxy error: $e');
      rethrow;
    }
  }

  /// Process image with OCR through backend proxy
  /// Edge Function endpoint: /functions/v1/ocr-proxy
  Future<Map<String, dynamic>> processImageOCR({
    required String imageBase64,
    String language = 'en',
  }) async {
    try {
      _logger.i('📤 Processing image with OCR through backend proxy...');
      
      final response = await supabase.functions.invoke(
        'ocr-proxy',
        body: {
          'imageBase64': imageBase64,
          'language': language,
        },
      );

      _logger.i('✅ OCR processing completed');
      return response as Map<String, dynamic>;
    } catch (e) {
      _logger.e('❌ OCR proxy error: $e');
      rethrow;
    }
  }
}

/// SETUP INSTRUCTIONS FOR SUPABASE EDGE FUNCTIONS:
/// 
/// 1. Initialize Supabase CLI:
///    ```bash
///    supabase functions new groq-proxy
///    supabase functions new email-proxy
///    supabase functions new ocr-proxy
///    ```
/// 
/// 2. Create supabase/functions/groq-proxy/index.ts:
///    ```typescript
///    import "https://esm.sh/v135/@supabase/supabase-js@2.43.4";
///    const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
///    
///    export const handler = async (req: Request) => {
///      const { message, language, model } = await req.json();
///      const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
///        method: "POST",
///        headers: {
///          "Authorization": `Bearer ${GROQ_API_KEY}`,
///          "Content-Type": "application/json",
///        },
///        body: JSON.stringify({ messages: [{ role: "user", content: message }], model }),
///      });
///      return new Response(await response.text());
///    };
///    ```
/// 
/// 3. Create supabase/functions/email-proxy/index.ts:
///    ```typescript
///    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
///    
///    export const handler = async (req: Request) => {
///      const { to, subject, body, replyTo } = await req.json();
///      const response = await fetch("https://api.resend.com/emails", {
///        method: "POST",
///        headers: {
///          "Authorization": `Bearer ${RESEND_API_KEY}`,
///          "Content-Type": "application/json",
///        },
///        body: JSON.stringify({ from: "noreply@aurasphere.io", to, subject, html: body, reply_to: replyTo }),
///      });
///      return new Response(await response.text());
///    };
///    ```
/// 
/// 4. Create supabase/functions/ocr-proxy/index.ts:
///    ```typescript
///    const OCR_API_KEY = Deno.env.get("OCR_API_KEY");
///    
///    export const handler = async (req: Request) => {
///      const { imageBase64, language } = await req.json();
///      const response = await fetch("https://api.ocr.space/parse", {
///        method: "POST",
///        headers: { "Content-Type": "application/json" },
///        body: JSON.stringify({
///          apikey: OCR_API_KEY,
///          base64Image: imageBase64,
///          language,
///        }),
///      });
///      return new Response(await response.text());
///    };
///    ```
/// 
/// 5. Store API keys as secrets:
///    ```bash
///    supabase secrets set GROQ_API_KEY=<your-key>
///    supabase secrets set RESEND_API_KEY=<your-key>
///    supabase secrets set OCR_API_KEY=<your-key>
///    ```
/// 
/// 6. Deploy:
///    ```bash
///    supabase functions deploy
///    ```
/// 
/// 7. Remove API keys from env_loader.dart (they're no longer needed in frontend)
