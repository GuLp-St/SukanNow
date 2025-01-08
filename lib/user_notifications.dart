import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserNotifications extends StatefulWidget {
  const UserNotifications({super.key});

  @override
  State<UserNotifications> createState() => _UserNotificationsState();
}

class _UserNotificationsState extends State<UserNotifications> {
  final database = FirebaseDatabase.instance.ref();
  final userId = FirebaseAuth.instance.currentUser!.uid;
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final snapshot = await database.child('users/$userId/notifications').get();
    if (snapshot.exists) {
      final notificationsData = snapshot.value as Map<dynamic, dynamic>;

      // Convert the notifications to a list of maps with message and timestamp
      final notifications = notificationsData.entries.map((entry) {
        return {
          'message': entry.value['message'],
          'timestamp': entry.value['timestamp'],
        };
      }).toList();

      // Sort the notifications by timestamp in descending order (latest first)
      notifications.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _notifications = notifications.map((notification) {
          // Format the timestamp to a readable string
          final DateTime date =
              DateTime.fromMillisecondsSinceEpoch(notification['timestamp']);
          final formattedTime = DateFormat('HH:mm').format(date); // Example format: 13:24

          // Combine the formatted time and message
          return '$formattedTime - ${notification['message']}';
        }).toList();
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await database.child('users/$userId/notifications').remove();
      setState(() {
        _notifications = [];
      });

      // Show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read!')),
        );
      }
    } catch (e) {
      // Show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notifications as read: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Text('No notifications yet.'),
                  )
                : ListView.separated( 
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(
                      indent: 180, // Add indent to the divider
                      endIndent: 180, // Add endIndent to the divider
                      color: Colors.orange, // Set divider color to orange
                    ), 
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_notifications[index]),
                      );
                    },
                  ),
          ),
          Padding( // Button at the bottom
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark All as Read'),
            ),
          ),
        ],
      ),
    );
  }
}