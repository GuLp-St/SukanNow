import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Events extends StatefulWidget {
  const Events({super.key});

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  final database = FirebaseDatabase.instance.ref();
  final user = FirebaseAuth.instance.currentUser;
  List<Map<dynamic, dynamic>> registeredEvents = [];

  @override
  void initState() {
    super.initState();
    _loadRegisteredEvents();
  }

  Future<void> _loadRegisteredEvents() async {
    if (user != null) {
      final eventSnapshot = await database.child('events').get();
      if (eventSnapshot.exists) {
        final events = (eventSnapshot.value as Map<dynamic, dynamic>).entries;
        final filteredEvents = events.where((event) {
          final registeredUsers =
              (event.value as Map<dynamic, dynamic>)['registeredUsers']
                  as Map<dynamic, dynamic>?;
          return registeredUsers != null && registeredUsers.containsKey(user!.uid);
        }).toList();

        setState(() {
          registeredEvents = filteredEvents
              .map((e) => {e.key: e.value})
              .toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Events'),
      ),
      body: ListView.builder(
        itemCount: registeredEvents.length,
        itemBuilder: (context, index) {
          final eventKey = registeredEvents[index].keys.first;
          final event =
              registeredEvents[index][eventKey] as Map<dynamic, dynamic>;

          return Card(
            child: ListTile(
              leading: event['imageUrl'] != null
                  ? SizedBox(
                      width: 50,
                      height: 50,
                      child: Image.network(event['imageUrl'], fit: BoxFit.cover),
                    )
                  : const Icon(Icons.event),
              title: Text(event['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['date']),
                  if (event['time'] != null) Text(event['time']),
                  if (event['location'] != null) Text(event['location']),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}