import 'package:firebase_auth/firebase_auth.dart' as fba;
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'admin_manage_availability_page.dart';
import 'admin_manage_booking_page.dart';
import 'admin_manage_event.dart';
import 'admin_membership.dart';
import 'admin_statistics.dart';
import 'userpage.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final database = FirebaseDatabase.instance.ref();
  int _pendingBookingsCount = 0;
  int _pendingMembershipRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    // Listen for user changes
    fba.FirebaseAuth.instance.userChanges().listen((user) {
      if (mounted) {
        setState(() {});
      }
    });

    // Listen for changes in the database for bookings
    database.child('badminton').onChildChanged.listen((event) => _fetchPendingBookingsCount());
    database.child('futsal').onChildChanged.listen((event) => _fetchPendingBookingsCount());
    database.child('basketball').onChildChanged.listen((event) => _fetchPendingBookingsCount());
    database.child('pingpong').onChildChanged.listen((event) => _fetchPendingBookingsCount());

    // Listen for changes in the database for membership requests
    database.child('users').onChildChanged.listen((event) => _fetchPendingMembershipRequestsCount());

    _fetchPendingBookingsCount();
    _fetchPendingMembershipRequestsCount(); // Fetch initial count
  }

  Future<void> _fetchPendingBookingsCount() async {
    final sports = ['badminton', 'futsal', 'basketball', 'pingpong'];
    int count = 0;

    for (final sport in sports) {
      final snapshot = await database.child(sport).get();
      if (snapshot.exists) {
        final bookingsData = snapshot.value as Map<dynamic, dynamic>;
        bookingsData.forEach((date, courtsData) {
          (courtsData as Map<dynamic, dynamic>).forEach((court, sessionsData) {
            if (sessionsData is Map<dynamic, dynamic>) {
              sessionsData.forEach((time, sessionData) {
                if (sessionData is Map &&
                    sessionData['status'] == 'pending') {
                  count++;
                }
              });
            } else if (sessionsData is List) {
              for (var i = 0; i < sessionsData.length; i++) {
                final sessionData = sessionsData[i];
                if (sessionData is Map &&
                    sessionData['status'] == 'pending') {
                  count++;
                }
              }
            }
          });
        });
      }
    }

    setState(() {
      _pendingBookingsCount = count;
    });
  }

  Future<void> _fetchPendingMembershipRequestsCount() async {
    int count = 0;
    final snapshot = await database.child('users').get();
    if (snapshot.exists) {
      final usersData = snapshot.value as Map<dynamic, dynamic>;
      usersData.forEach((userId, userData) {
        if (userData['membership'] != null) {
          final membershipData = userData['membership'] as Map<dynamic, dynamic>;
          membershipData.forEach((activityKey, activityData) {
            if (activityData['request'] != null) {
              count++;
            }
            // Also check for cancellation requests if needed
            if (activityData['delete'] != null) {
              count++;
            }
          });
        }
      });
    }
    setState(() {
      _pendingMembershipRequestsCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Wrap UserAvatar with GestureDetector and add nickname
            StreamBuilder<fba.User?>(
              stream: fba.FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final user = snapshot.data;
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Same functionality as the IconButton
                          Navigator.push(
                            context,
                            MaterialPageRoute<ProfileScreen>(
                              builder: (context) => ProfileScreen(
                                appBar: AppBar(
                                  title: const Text('User Profile'),
                                ),
                                actions: [
                                  SignedOutAction((context) {
                                    Navigator.of(context).pop();
                                  })
                                ],
                              ),
                            ),
                          );
                        },
                        child: UserAvatar(
                          key: ValueKey(fba.FirebaseAuth.instance.currentUser?.photoURL),
                          auth: fba.FirebaseAuth.instance,
                          size: 30, // Adjust the size as needed
                        ),
                      ),
                      SizedBox(width: 10),
                      // Use a Column to arrange "Welcome Back" and nickname
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                        mainAxisSize: MainAxisSize.min, // Make the column as small as possible
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${user?.displayName ?? 'Guest'} (admin)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return const SizedBox.shrink(); // or a loading indicator
                }
              },
            ),
            GestureDetector(
              onTap: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmation'),
                      content: const Text(
                          'Enter User Mode?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to the HomeScreen (UserPage)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomeScreen()),
                            );
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/logo.png',
                  width: 45,
                ),
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminManageAvailabilityPage(),
                        ),
                      );
                    },
                    child: const Column( // Wrap text with Column
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Manage Court'),
                        Text('Availability'), // Separate text into two lines
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 20),
                SizedBox(
                  width: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminManageBookingPage(),
                            ),
                          );
                        },
                        child: const Column( // Wrap text with Column
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Manage Court'),
                            Text('Bookings'), // Separate text into two lines
                          ],
                        ),
                      ),
                      if (_pendingBookingsCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                            child: Text(
                              '$_pendingBookingsCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Rest of the buttons in a column
            Stack( // Wrap the ElevatedButton with a Stack
              alignment: Alignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminMembership(),
                      ),
                    );
                  },
                  child: const Text('Manage Membership'),
                ),
                if (_pendingMembershipRequestsCount > 0) // Add the counter
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: Text(
                        '$_pendingMembershipRequestsCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminEvent(),
                  ),
                );
              },
              child: const Text('Manage Event'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminStats(),
                  ),
                );
              },
              child: const Text('Statistics'),
            ),
          ],
        ),
      ),
    );
  }
}