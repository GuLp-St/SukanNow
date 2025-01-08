import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingDetailsPage extends StatelessWidget {
  final String sport;
  final DateTime date;
  final String court;
  final String time;
  final VoidCallback? onBookingConfirmed;

  const BookingDetailsPage({
    super.key,
    required this.sport,
    required this.date,
    required this.court,
    required this.time,
    this.onBookingConfirmed,
  });

Future<void> _confirmBooking(BuildContext context) async {
  final database = FirebaseDatabase.instance.ref();
  final dateString = DateFormat('yyyy-MM-dd').format(date);
  final userId = FirebaseAuth.instance.currentUser!.uid; 
  final contextForSnackbar = context; 

  try {
    await database
        .child(sport)
        .child(dateString)
        .child('court$court')
        .child(time)
        .set({
      'status': 'pending',
      'userId': userId, 
    });

    // Check if the widget is still mounted
    if (contextForSnackbar.mounted) {
      // Show a success message
      ScaffoldMessenger.of(contextForSnackbar).showSnackBar(
        const SnackBar(content: Text('Booking request sent!')),
      );

      // Navigate back to the previous screen
      Navigator.of(contextForSnackbar).pop();
    }

    onBookingConfirmed?.call(); 
  } catch (e) {
    // Check if the widget is still mounted
    if (contextForSnackbar.mounted) {
      // Show an error message
      ScaffoldMessenger.of(contextForSnackbar).showSnackBar(
        SnackBar(content: Text('Error confirming booking: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Sport: $sport'),
            Text('Date: ${date.toString()}'),
            Text('Court: $court'),
            Text('Time: $time'),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirm Booking"),
                      content:
                      const Text("Are you sure you want to book this court?"),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text("Confirm"),
                          onPressed: () {
                            _confirmBooking(context);
                            Navigator.of(context).pop(); // Close the dialog
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}