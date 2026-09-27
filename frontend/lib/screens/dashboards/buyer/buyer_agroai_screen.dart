// buyer_agroai_screen.dart
// TODO: Full AgroAI RAG chatbot screen — coming in a future sprint.
// Placeholder wired to the Buyer Dashboard bottom nav (index 3).

import 'dart:ui';
import 'package:flutter/material.dart';

class BuyerAgroAIScreen extends StatelessWidget {
  const BuyerAgroAIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'AGROAI · RAG',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AgroAI Assistant',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'RAG-powered agricultural intelligence',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.construction_rounded,
                              color: Color(0xFF7C3AED), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The AgroAI chat interface is under active development. It will use Retrieval-Augmented Generation (RAG) to answer market, crop, and logistics queries in real-time.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4C1D95),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Chat preview area (static)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coming Soon — Preview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // AI bubble
                    _chatBubble(
                      'Hello! I\'m AgroAI. Ask me about crop prices, market trends, or logistics routes in Cameroon.',
                      isAI: true,
                    ),
                    const SizedBox(height: 8),
                    // User bubble
                    _chatBubble(
                      'What\'s the best price for plantains in Yaoundé today?',
                      isAI: false,
                    ),
                    const SizedBox(height: 8),
                    // AI response bubble
                    _chatBubble(
                      '🔒 Live price feed coming soon. I\'ll be able to pull real-time PostGIS market data once integrated.',
                      isAI: true,
                    ),
                    const SizedBox(height: 14),
                    // Disabled input
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Ask AgroAI anything...',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(Icons.send_rounded,
                              color: Color(0xFFCBD5E1), size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Feature preview cards
          ...[
            {
              'icon': Icons.chat_bubble_rounded,
              'title': 'RAG Chat Engine',
              'subtitle': 'Ask questions, get context-aware agri answers',
              'color': const Color(0xFF7C3AED),
              'bg': const Color(0xFFFAF5FF),
            },
            {
              'icon': Icons.trending_up_rounded,
              'title': 'Price Forecasting',
              'subtitle': 'AI-powered commodity price predictions',
              'color': const Color(0xFF059669),
              'bg': const Color(0xFFECFDF5),
            },
            {
              'icon': Icons.route_rounded,
              'title': 'Logistics Optimizer',
              'subtitle': 'Optimal transport routing recommendations',
              'color': const Color(0xFFD97706),
              'bg': const Color(0xFFFFFBEB),
            },
          ].map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item['bg'] as Color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item['icon'] as IconData,
                              color: item['color'] as Color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['title'] as String,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text(item['subtitle'] as String,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Soon',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF94A3B8))),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _chatBubble(String text, {required bool isAI}) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isAI ? const Color(0xFFF5F3FF) : const Color(0xFF0F5132),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isAI ? 4 : 16),
            bottomRight: Radius.circular(isAI ? 16 : 4),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isAI ? const Color(0xFF1E1B4B) : Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
