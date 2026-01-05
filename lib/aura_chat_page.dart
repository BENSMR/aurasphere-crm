// lib/aura_chat_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/aura_ai_service.dart';
import 'services/ai_automation_service.dart';

class AuraChatPage extends StatefulWidget {
  final String? selectedAgent; // Optional: pre-select an agent
  const AuraChatPage({this.selectedAgent, super.key});

  @override
  State<AuraChatPage> createState() => _AuraChatPageState();
}

class _AuraChatPageState extends State<AuraChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  String _userLang = 'en';
  final supabase = Supabase.instance.client;
  final automationService = AIAutomationService();
  String? _selectedAgent; // Track selected agent
  String? _orgId;

  @override
  void initState() {
    super.initState();
    _selectedAgent = widget.selectedAgent;
    if (supabase.auth.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    } else {
      _initializeChat();
    }
  }

  Future<void> _initializeChat() async {
    try {
      final org = await supabase.from('organizations').select('id').single();
      _orgId = org['id'];
      await _loadUserLanguage();
    } catch (e) {
      print('❌ Error initializing chat: $e');
    }
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
      // Check if agent is enabled and quotas are respected
      if (_orgId != null && _selectedAgent != null) {
        final quotaCheck = await automationService.checkCallAllowed(
          orgId: _orgId!,
          agentName: _selectedAgent!,
        );

        if (!quotaCheck['allowed']) {
          if (mounted) {
            setState(() {
              _messages.removeLast(); // Remove "..." message
            });
          }
          _addMessage('⚠️ ${quotaCheck['reason']}', false);
          return;
        }
      }

      // Process with AI agent
      final command = await AuraAiService.parseCommand(input, _userLang);
      
      if (command != null) {
        final result = await AuraAiService.executeAction(command);
        
        if (mounted) {
          setState(() {
            _messages.removeLast(); // Remove "..." message
          });
        }

        // Log the API call for cost tracking
        if (_orgId != null && _selectedAgent != null) {
          await automationService.logApiCall(
            orgId: _orgId!,
            agentName: _selectedAgent!,
            action: command['action'] ?? 'unknown',
            tokensUsed: 150, // Estimate
            estimatedCost: 0.001, // Estimate
          );
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

  // AI Agents configuration
  Map<String, Map<String, dynamic>> get _agents => {
    'cfo': {
      'title': '💰 CFO Agent',
      'description': 'Financial analysis, invoicing, tax compliance & budgeting',
      'color': Colors.green,
      'subtitle': 'Chief Financial Officer'
    },
    'ceo': {
      'title': '🎯 CEO Agent',
      'description': 'Business strategy, KPI analysis, growth recommendations',
      'color': Colors.blue,
      'subtitle': 'Chief Executive Officer'
    },
    'marketing': {
      'title': '📢 Marketing Agent',
      'description': 'Campaign automation, lead generation, brand messaging',
      'color': Colors.orange,
      'subtitle': 'Marketing Manager'
    },
    'sales': {
      'title': '💼 Sales Agent',
      'description': 'Lead qualification, pipeline management, deal tracking',
      'color': Colors.purple,
      'subtitle': 'Sales Director'
    },
    'admin': {
      'title': '⚙️ Admin Agent',
      'description': 'Team management, permissions, system configuration',
      'color': Colors.red,
      'subtitle': 'System Administrator'
    },
  };

  // Build agent selector
  Widget _buildAgentSelector() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.smart_toy, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 24),
            const Text(
              'Select Your AI Agent',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose an AI specialist to help with your business tasks',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ..._agents.entries.map((entry) {
              final agentKey = entry.key;
              final agent = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedAgent = agentKey);
                    _addMessage('✨ ${agent['subtitle']} activated. How can I help?', false);
                  },
                  child: Card(
                    elevation: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(width: 4, color: agent['color']),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            agent['title'],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            agent['subtitle'],
                            style: TextStyle(color: agent['color'], fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            agent['description'],
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() => _selectedAgent = agentKey);
                                _addMessage('✨ ${agent['subtitle']} activated. How can I help?', false);
                              },
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Select'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Defensive auth check: prevent render if not authenticated
    if (supabase.auth.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Redirecting to login...')),
      );
    }

    // Show agent selector if no agent selected
    if (_selectedAgent == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.white),
              SizedBox(width: 8),
              Text('Aura AI Agents'),
            ],
          ),
        ),
        body: _buildAgentSelector(),
      );
    }

    // Show chat with selected agent
    final agentInfo = _agents[_selectedAgent];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agentInfo?['title'] ?? 'AI Assistant'),
                Text(
                  agentInfo?['subtitle'] ?? '',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _selectedAgent = null),
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            label: const Text('Switch Agent', style: TextStyle(color: Colors.white)),
          ),
        ],
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
