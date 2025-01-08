import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AdminStats extends StatefulWidget {
  const AdminStats({super.key});

  @override
  State<AdminStats> createState() => _AdminStatsState();
}

class _AdminStatsState extends State<AdminStats> {
  final database = FirebaseDatabase.instance.ref();
  int _totalUsers = 0;
  int _totalBookings = 0;
  final Map<String, int> _eventParticipation = {};
  final Map<String, int> _membershipParticipation = {};
  final Map<String, Map<String, int>> _sportsParticipation = {};

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    // Fetch total users
    final usersSnapshot = await database.child('users').get();
    if (usersSnapshot.exists) {
      _totalUsers = (usersSnapshot.value as Map<dynamic, dynamic>).length;
    }

    // Fetch total bookings and sports participation
    final sports = ['badminton', 'futsal', 'basketball', 'pingpong'];
    // Fetch sports participation with this week/last week breakdown
    final now = DateTime.now();
    final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final thisWeekEnd = thisWeekStart.add(const Duration(days: 6));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekEnd.subtract(const Duration(days: 7));

    for (final sport in sports) {
      // Initialize counts for this week and last week to 0
      _sportsParticipation[sport] = {
        'This Week': 0,
        'Last Week': 0,
      };

      // Fetch unavailable dates for the sport
      final unavailableDatesSnapshot = await database.child('$sport/availability/dates').get();
      List<DateTime> unavailableDates = [];
      if (unavailableDatesSnapshot.exists) {
        unavailableDates = List<String>.from(unavailableDatesSnapshot.value as List<dynamic>)
            .map((date) => DateTime.parse(date))
            .toList();
      }

      final sportSnapshot = await database.child(sport).get();
      if (sportSnapshot.exists) {
        final sportData = sportSnapshot.value as Map<dynamic, dynamic>;
        sportData.forEach((date, courtsData) {
          // Skip this date if it's in the unavailable dates list
          if (unavailableDates.any((unavailableDate) => unavailableDate.toIso8601String().substring(0, 10) == date)) {
            return;
          }

          // Calculate total bookings correctly
          int thisWeekCount = 0;
          int lastWeekCount = 0;
          (courtsData as Map<dynamic, dynamic>).forEach((court, sessionsData) {
            if (sessionsData is Map<dynamic, dynamic>) {
              thisWeekCount += sessionsData.values.where((sessionData) => sessionData
              is Map && sessionData['status'] != 'open' && DateTime.parse(date).isAfter(thisWeekStart) && DateTime.parse(date).isBefore(thisWeekEnd)).length;
              lastWeekCount += sessionsData.values.where((sessionData) => sessionData is Map && sessionData['status'] != 'open' && DateTime.parse(date).isAfter(lastWeekStart) && DateTime.parse(date).isBefore(lastWeekEnd)).length;
              _totalBookings += sessionsData.values.where((sessionData) => sessionData is Map && sessionData['status'] != 'open').length;
            } else if (sessionsData is List) {
              thisWeekCount += sessionsData.where((sessionData) => sessionData is Map && sessionData['status'] != 'open' && DateTime.parse(date).isAfter(thisWeekStart) &&
                  DateTime.parse(date).isBefore(thisWeekEnd)).length;
              lastWeekCount += sessionsData.where((sessionData) => sessionData is Map && sessionData['status'] != 'open' && DateTime.parse(date).isAfter(lastWeekStart) && DateTime.parse(date).isBefore(lastWeekEnd)).length;
              _totalBookings += sessionsData.where((sessionData) => sessionData is Map && sessionData['status'] != 'open').length;
            }
          });
          _sportsParticipation[sport]!['This Week'] = _sportsParticipation[sport]!['This Week']! + thisWeekCount;
          _sportsParticipation[sport]!['Last Week'] = _sportsParticipation[sport]!['Last Week']! + lastWeekCount;
        });
      }
    }

    // Fetch event participation
    final eventsSnapshot = await database.child('events').get();
    if (eventsSnapshot.exists) {
      final eventsData = eventsSnapshot.value as Map<dynamic, dynamic>;
      eventsData.forEach((eventId, eventData) {
        if (eventData is Map<dynamic, dynamic>) {
          final registeredUsers = eventData['registeredUsers'] as Map<dynamic, dynamic>?;
          if (registeredUsers != null) {
            _eventParticipation.update(eventData['name'], (value) => value + registeredUsers.length,
                ifAbsent: () => registeredUsers.length);
          }
        }
      });
    }

    // Fetch membership participation with pass type breakdown
    final usersData = await database.child('users').get();
    if (usersData.exists) {
      (usersData.value as Map<dynamic, dynamic>).forEach((userId, userData) {
        if (userData is Map<dynamic, dynamic> && userData['membership'] != null) {
          final membershipData = userData['membership'] as Map<dynamic, dynamic>;
          membershipData.forEach((activityKey, activityData) {
            if (activityData is Map<dynamic, dynamic> && activityData['status'] == 'active') {
              final passType = activityData['type'] as String;
              final key = '$activityKey - $passType';
              _membershipParticipation.update(key, (value) => value + 1, ifAbsent: () => 1);
            }
          });
        }
      });
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatTile('Total Users', _totalUsers),
              _buildStatTile('Total Bookings', _totalBookings),
              const Divider(),
              const Text('Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildParticipationList(_eventParticipation),
              const Divider(),
              const Text('Membership', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _buildParticipationList(_membershipParticipation),
              const Divider(),
              const Text('Sports ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildSportsParticipationList(_sportsParticipation),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, int value) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      trailing: Text(value.toString(), style: const TextStyle(fontSize: 18)),
    );
  }

  Widget _buildParticipationList(Map<String, int> participationData) {
    return Column(
      children: participationData.entries.map((entry) {
        return ListTile(
          title: Text(entry.key),
          trailing: Text(entry.value.toString()),
        );
      }).toList(),
    );
  }

  Widget _buildSportsParticipationList(Map<String, Map<String, int>> participationData) {
    return Column(
      children: participationData.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text('This Week'),
              trailing: Text(entry.value['This Week'].toString()),
            ),
            ListTile(
              title: const Text('Last Week'),
              trailing: Text(entry.value['Last Week'].toString()),
            ),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }
}