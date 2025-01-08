import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SukanCoin extends StatefulWidget {
  const SukanCoin({super.key});

  @override
  State<SukanCoin> createState() => _SukanCoinState();
}

class _SukanCoinState extends State<SukanCoin> {
  final database = FirebaseDatabase.instance.ref();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  int _walletAmount = 0;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWalletAmount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletAmount() async {
    final snapshot = await database.child('users/$userId/wallet').get();
    if (snapshot.exists) {
      setState(() {
        _walletAmount = int.parse(snapshot.value.toString());
      });
    }
  }

  Future<void> _topUp(int amount) async {
    try {
      await database.child('users/$userId/wallet').set(_walletAmount + amount);
      await _fetchWalletAmount();

      // Show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Top up successful! New balance: $_walletAmount 🪙')),
        );
      }
    } catch (e) {
      // Show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error topping up: $e')),
        );
      }
    }
  }

  Future<void> _showPaymentDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Payment Method'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Choose your preferred payment method:'),
                const SizedBox(height: 20),
                _buildPaymentMethodButton('Bank Transfer', _showBankListDialog),
                _buildPaymentMethodButton('Online Payment', _showOnlinePaymentListDialog),
                _buildPaymentMethodButton('Credit/Debit Card', _showCardPaymentDialog),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentMethodButton(String text, Future<void> Function(BuildContext) onPressed) {
    return ElevatedButton(
      onPressed: () => onPressed(context),
      child: Text(text),
    );
  }

Future<void> _showBankListDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select Bank'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Choose your bank:'),
              const SizedBox(height: 20),
              InkWell( // Make Maybank ListTile clickable
                onTap: () {
                  // Simulate successful bank transfer
                  _topUp(int.parse(_amountController.text));
                  Navigator.of(context).pop(); // Close the bank list dialog
                  Navigator.of(context).pop(); // Close the payment method dialog
                },
                child: const ListTile(
                  leading: Icon(Icons.account_balance),
                  title: Text('Maybank'),
                ),
              ),
              InkWell( // Make CIMB Bank ListTile clickable
                onTap: () {
                  // Simulate successful bank transfer
                  _topUp(int.parse(_amountController.text));
                  Navigator.of(context).pop(); // Close the bank list dialog
                  Navigator.of(context).pop(); // Close the payment method dialog
                },
                child: const ListTile(
                  leading: Icon(Icons.account_balance),
                  title: Text('CIMB Bank'),
                ),
              ),
              InkWell( // Make Public Bank ListTile clickable
                onTap: () {
                  // Simulate successful bank transfer
                  _topUp(int.parse(_amountController.text));
                  Navigator.of(context).pop(); // Close the bank list dialog
                  Navigator.of(context).pop(); // Close the payment method dialog
                },
                child: const ListTile(
                  leading: Icon(Icons.account_balance),
                  title: Text('Public Bank'),
                ),
              ),
              // Add more banks as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

Future<void> _showOnlinePaymentListDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select Online Payment'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Choose your online payment method:'),
              const SizedBox(height: 20),
              InkWell( // Make Touch 'n Go eWallet ListTile clickable
                onTap: () {
                  // Simulate successful online payment
                  _topUp(int.parse(_amountController.text));
                  Navigator.of(context).pop(); // Close the online payment list dialog
                  Navigator.of(context).pop(); // Close the payment method dialog
                },
                child: const ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('Touch \'n Go eWallet'),
                ),
              ),
              InkWell( // Make GrabPay ListTile clickable
                onTap: () {
                  // Simulate successful online payment
                  _topUp(int.parse(_amountController.text));
                  Navigator.of(context).pop(); // Close the online payment list dialog
                  Navigator.of(context).pop(); // Close the payment method dialog
                },
                child: const ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('GrabPay'),
                ),
              ),
              InkWell( // Make Boost ListTile clickable
                onTap: () {
                  // Simulate successful online payment
                  _topUp(int.parse(_amountController.text));
                  Navigator.of(context).pop(); // Close the online payment list dialog
                  Navigator.of(context).pop(); // Close the payment method dialog
                },
                child: const ListTile(
                  leading: Icon(Icons.payment),
                  title: Text('Boost'),
                ),
              ),
              // Add more online payment options as needed
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
  Future<void> _showCardPaymentDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Card Details'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const Text('Enter your card details:'),
                const SizedBox(height: 20),
                const TextField(decoration: InputDecoration(hintText: 'Card Number')),
                const TextField(decoration: InputDecoration(hintText: 'Expiry Date (MM/YY)')),
                const TextField(decoration: InputDecoration(hintText: 'CVV')),
                // Add more card details fields as needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Simulate successful card payment
                _topUp(int.parse(_amountController.text));
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the payment method dialog
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SukanCoin'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Wallet Balance: $_walletAmount 🪙', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter amount to top up',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _showPaymentDialog(context),
              child: const Text('Top Up'),
            ),
          ],
        ),
      ),
    );
  }
}