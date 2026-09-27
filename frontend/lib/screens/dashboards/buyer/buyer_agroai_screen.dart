import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_service.dart';

class BuyerAgroAIScreen extends StatefulWidget {
  const BuyerAgroAIScreen({super.key});

  @override
  State<BuyerAgroAIScreen> createState() => _BuyerAgroAIScreenState();
}

class _BuyerAgroAIScreenState extends State<BuyerAgroAIScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _attachTelemetry = false;
  bool _hasImageAttached = false;

  Future<void> _sendQuery(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() {
      String promptText = prompt;
      if (_hasImageAttached) promptText = '[📷 Image] ' + promptText;
      if (_attachTelemetry) promptText = '[📡 Telemetry] ' + promptText;
      
      _messages.add({'sender': 'user', 'text': promptText});
      _isLoading = true;
      _hasImageAttached = false;
      _attachTelemetry = false;
    });
    _queryController.clear();

    try {
      final response = await ApiService.queryAiAssistant(prompt);
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': response['answer'] ?? response['response'] ?? response['message'] ?? 'Advisory retrieved successfully.',
          'status': response['status'] ?? 'APPROVED'
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'ai',
          'text': 'Error communicating with AgroAI Guardrail service: ${e.toString()}',
          'status': 'ERROR'
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 80, left: 16, right: 16, bottom: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AgroAI Assistant',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'RAG-powered agricultural intelligence',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isUser = msg['sender'] == 'user';
                            final isRejected = msg['status'] == 'REJECTED';
                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(14),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isUser 
                                      ? const Color(0xFF16a34a) 
                                      : (isRejected ? const Color(0xFF7F1D1D) : Colors.white.withOpacity(0.08)),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  border: Border.all(color: isUser ? Colors.transparent : Colors.white12),
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: TextStyle(
                                    color: isRejected ? const Color(0xFFFCA5A5) : Colors.white, 
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 60,
                              child: LinearProgressIndicator(color: Color(0xFF6CF8BB), backgroundColor: Colors.white12),
                            ),
                          ),
                        ),
                      const Divider(color: Colors.white12, height: 1),
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            if (_attachTelemetry || _hasImageAttached)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6CF8BB).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF6CF8BB).withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_attachTelemetry) ...[
                                      const Icon(Icons.sensors, size: 14, color: Color(0xFF6CF8BB)),
                                      const SizedBox(width: 4),
                                      const Text('IoT Telemetry Attached', style: TextStyle(color: Color(0xFF6CF8BB), fontSize: 11)),
                                      if (_hasImageAttached) const SizedBox(width: 12),
                                    ],
                                    if (_hasImageAttached) ...[
                                      const Icon(Icons.image, size: 14, color: Color(0xFF6CF8BB)),
                                      const SizedBox(width: 4),
                                      const Text('Crop Image Attached', style: TextStyle(color: Color(0xFF6CF8BB), fontSize: 11)),
                                    ],
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => setState(() { _attachTelemetry = false; _hasImageAttached = false; }),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.camera_alt_rounded, color: _hasImageAttached ? const Color(0xFF6CF8BB) : Colors.white54),
                                  tooltip: 'Attach Crop Photo',
                                  onPressed: () => setState(() => _hasImageAttached = !_hasImageAttached),
                                ),
                                IconButton(
                                  icon: Icon(Icons.sensors_rounded, color: _attachTelemetry ? const Color(0xFF6CF8BB) : Colors.white54),
                                  tooltip: 'Attach Live IoT Storage Telemetry',
                                  onPressed: () => setState(() => _attachTelemetry = !_attachTelemetry),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: TextField(
                                      controller: _queryController,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      decoration: const InputDecoration(
                                        hintText: 'Message AgroAI...',
                                        hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                                        border: InputBorder.none,
                                      ),
                                      onSubmitted: (val) => _sendQuery(val),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF6CF8BB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.send_rounded, color: Color(0xFF0F172A), size: 20),
                                    onPressed: () => _sendQuery(_queryController.text),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}