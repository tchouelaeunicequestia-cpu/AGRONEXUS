// lib/screens/modals/buyer_checkout_modal.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BuyerCheckoutModal extends StatefulWidget {
  final int buyerId;
  final int farmerId;
  final double amount;
  final String produceTitle;

  const BuyerCheckoutModal({
    super.key,
    required this.buyerId,
    required this.farmerId,
    required this.amount,
    required this.produceTitle,
  });

  @override
  State<BuyerCheckoutModal> createState() => _BuyerCheckoutModalState();
}

class _BuyerCheckoutModalState extends State<BuyerCheckoutModal> {
  String _selectedProvider = 'MTN_MOMO'; // MTN_MOMO, ORANGE_MONEY, BANK_ACCOUNT
  final TextEditingController _phoneOrAccountController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _providers = [
    {
      'id': 'MTN_MOMO',
      'label': 'MTN Mobile Money',
      'prefix': '+237 67x...',
      'color': Colors.amber,
      'icon': Icons.phone_android_rounded,
    },
    {
      'id': 'ORANGE_MONEY',
      'label': 'Orange Money',
      'prefix': '+237 69x...',
      'color': Colors.deepOrange,
      'icon': Icons.phone_android_rounded,
    },
    {
      'id': 'BANK_ACCOUNT',
      'label': 'CEMAC Bank Account',
      'prefix': 'RIB / Account #',
      'color': const Color(0xFF003820),
      'icon': Icons.account_balance_rounded,
    },
  ];

  @override
  void dispose() {
    _phoneOrAccountController.dispose();
    super.dispose();
  }

  Future<void> _processEscrowLock() async {
    if (_phoneOrAccountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your payment phone or account number.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await ApiService.initializeEscrow(
        buyerId: widget.buyerId,
        farmerId: widget.farmerId,
        amount: widget.amount,
        provider: _selectedProvider,
        payerPhoneOrAccount: _phoneOrAccountController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context);
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Color(0xFF006C49)),
              SizedBox(width: 8),
              Text('Escrow Vault Secured', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reference: ${response['reference']}'),
              const SizedBox(height: 8),
              const Text('USSD payment prompt sent to your device. Funds are safely locked in AgroNexus Vault pending delivery confirmation.'),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003820), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}'), backgroundColor: Colors.red),
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
                const Text('CEMAC Secure Escrow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF003820))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Produce: ${widget.produceTitle} • ${widget.amount} XAF', style: const TextStyle(fontSize: 13, color: Color(0xFF404942))),
            const Divider(height: 24),
            const Text('Select Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF003820))),
            const SizedBox(height: 12),
            Column(
              children: _providers.map((p) {
                bool isSelected = _selectedProvider == p['id'];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE9FFED) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? const Color(0xFF006C49) : const Color(0xFFE2E8F0)),
                  ),
                  child: RadioListTile<String>(
                    title: Text(p['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(p['prefix'], style: const TextStyle(fontSize: 11)),
                    secondary: Icon(p['icon'], color: p['color']),
                    value: p['id'],
                    groupValue: _selectedProvider,
                    activeColor: const Color(0xFF006C49),
                    onChanged: (val) => setState(() => _selectedProvider = val!),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneOrAccountController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: _selectedProvider == 'BANK_ACCOUNT' ? 'Bank Account / RIB Number' : 'Mobile Money Phone Number',
                hintText: _selectedProvider == 'BANK_ACCOUNT' ? 'CM21 ...' : '+237 6...',
                prefixIcon: const Icon(Icons.payment_rounded),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003820),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _processEscrowLock,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Lock Funds in Escrow Vault', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}