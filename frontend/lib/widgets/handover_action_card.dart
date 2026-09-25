import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/auth_provider.dart';
import 'package:frontend/services/draft_service.dart';
import 'package:frontend/services/platform_services.dart';

class HandoverActionCard extends StatelessWidget {
  final String orderId;
  final String role; // 'FARMER', 'TRANSPORTER', or 'BUYER'
  final String authToken;
  final VoidCallback onSuccess;

  const HandoverActionCard({
    super.key,
    required this.orderId,
    required this.role,
    required this.authToken,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    String buttonText = '';
    Color buttonColor = Colors.green;

    switch (role.toUpperCase()) {
      case 'FARMER':
        buttonText = 'Sign Off & Dispatch Lot';
        buttonColor = Colors.orange;
        break;
      case 'TRANSPORTER':
        buttonText = 'Confirm Cargo Arrival';
        buttonColor = Colors.blue;
        break;
      case 'BUYER':
        buttonText = 'Inspect & Release Escrow Funds';
        buttonColor = Colors.teal;
        break;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Handover Order: $orderId',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Current Stage Role: $role', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                onPressed: () async {
                  bool success = false;
                  ApiService api = ApiService();

                  if (role.toUpperCase() == 'FARMER') {
                    success = await api.farmerSignoffDispatch(orderId, authToken);
                  } else if (role.toUpperCase() == 'TRANSPORTER') {
                    success = await api.transporterConfirmDelivery(orderId, authToken);
                  } else if (role.toUpperCase() == 'BUYER') {
                    success = await api.buyerReleaseEscrow(orderId, authToken);
                  }

                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Handover signoff successful!')),
                      );
                      onSuccess();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signoff failed. Please check network/auth.')),
                      );
                    }
                  }
                },
                child: Text(buttonText, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}