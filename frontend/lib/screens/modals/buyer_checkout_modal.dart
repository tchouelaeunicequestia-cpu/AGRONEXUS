// lib/screens/modals/buyer_checkout_modal.dart
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class BuyerCheckoutModal extends StatefulWidget {
  final int buyerId;
  final int productId;
  final double quantity;
  final double? transportFee;
  final bool isSelfPickup;
  final String? deliveryAddress;
  final String produceTitle;

  const BuyerCheckoutModal({
    super.key,
    required this.buyerId,
    required this.productId,
    required this.quantity,
    this.transportFee,
    this.isSelfPickup = false,
    this.deliveryAddress,
    required this.produceTitle,
  });

  @override
  State<BuyerCheckoutModal> createState() => _BuyerCheckoutModalState();
}

class _BuyerCheckoutModalState extends State<BuyerCheckoutModal> {
  bool _isLoading = false;

  Future<void> _processEscrowLock() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.createEscrowOrder(
        buyerId: widget.buyerId,
        productId: widget.productId,
        quantity: widget.quantity,
        transportFee: widget.transportFee,
        isSelfPickup: widget.isSelfPickup,
        deliveryAddress: widget.deliveryAddress,
      );

      if (!mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Color(0xFF006C49)),
              SizedBox(width: 8),
              Text(
                'Escrow Vault Secured',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order: ${response['order']['orderCode']}'),
              const SizedBox(height: 8),
              Text('Status: ${response['order']['escrowStatus']}'),
              const SizedBox(height: 8),
              const Text(
                'The order has been created and its calculated amount is locked in the AgroNexus escrow vault pending delivery confirmation.',
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003820),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CEMAC Secure Escrow',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF003820),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Produce: ${widget.produceTitle} • ${widget.quantity} units',
              style: const TextStyle(fontSize: 13, color: Color(0xFF404942)),
            ),
            const Divider(height: 24),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003820),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _processEscrowLock,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Create Order & Lock Funds',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
