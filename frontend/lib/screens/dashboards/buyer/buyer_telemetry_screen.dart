// buyer_telemetry_screen.dart
// TODO: Full IoT telemetry dashboard — coming in a future sprint.
// Placeholder wired to the Buyer Dashboard bottom nav (index 2).

import 'dart:ui';
import 'package:flutter/material.dart';

class BuyerTelemetryScreen extends StatelessWidget {
  const BuyerTelemetryScreen({super.key});

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
              color: const Color(0xFF0E7490).withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'IOT TELEMETRY',
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
                  border: Border.all(color: const Color(0xFFBAE6FD)),
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
                              colors: [Color(0xFF0E7490), Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.developer_board_rounded,
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
                                'ESP32 Telemetry Hub',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Live IoT sensor data from linked farm nodes',
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
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.construction_rounded,
                              color: Color(0xFF0E7490), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The Telemetry dashboard is under active development. Sensor readings from ESP32 nodes will stream in real-time here once integrated.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0C4A6E),
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

          // Metric preview cards (simulated)
          Row(
            children: [
              _metricCard('Temperature', '—°C', Icons.thermostat_rounded,
                  const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
              const SizedBox(width: 12),
              _metricCard('Humidity', '— %', Icons.water_drop_rounded,
                  const Color(0xFF0E7490), const Color(0xFFF0F9FF)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricCard('Soil pH', '—', Icons.science_rounded,
                  const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
              const SizedBox(width: 12),
              _metricCard('CO₂ Level', '— ppm', Icons.air_rounded,
                  const Color(0xFF059669), const Color(0xFFECFDF5)),
            ],
          ),
          const SizedBox(height: 16),

          // Features coming
          ...[
            {
              'icon': Icons.show_chart_rounded,
              'title': 'Live Sensor Graphs',
              'subtitle': 'Real-time chart feeds from each IoT node',
              'color': const Color(0xFF0E7490),
              'bg': const Color(0xFFF0F9FF),
            },
            {
              'icon': Icons.notifications_active_rounded,
              'title': 'Telemetry Alerts',
              'subtitle': 'Push alerts when thresholds are breached',
              'color': const Color(0xFFEA580C),
              'bg': const Color(0xFFFFF7ED),
            },
            {
              'icon': Icons.map_rounded,
              'title': 'Node Map View',
              'subtitle': 'Geographic layout of all farm IoT nodes',
              'color': const Color(0xFF7C3AED),
              'bg': const Color(0xFFF5F3FF),
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
                            color: (item['bg'] as Color),
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

  Widget _metricCard(String label, String value, IconData icon, Color color,
      Color bg) {
    return Expanded(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 10),
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
