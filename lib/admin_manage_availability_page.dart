import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AdminManageAvailabilityPage extends StatefulWidget {
  const AdminManageAvailabilityPage({super.key});

  @override
  State<AdminManageAvailabilityPage> createState() => _AdminManageAvailabilityPageState();
}

class _AdminManageAvailabilityPageState extends State<AdminManageAvailabilityPage> {
  final database = FirebaseDatabase.instance.ref();
  final sports = ['badminton', 'futsal', 'basketball', 'pingpong'];
  String? _selectedSport;
  List<DateTime> _unavailableDates = [];

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchAvailability() async {
    if (_selectedSport == null) {
      setState(() {
        _unavailableDates = []; // Clear the list if no sport is selected
      });
      return;
    }

    final snapshot = await database.child('$_selectedSport/availability').get();
    if (snapshot.exists) {
      final availabilityData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _unavailableDates = List<String>.from(availabilityData['dates'] ?? [])
            .map((date) => DateTime.parse(date))
            .toList();
      });
    } else {
      // Handle the case where no availability data exists for the selected sport
      setState(() {
        _unavailableDates = []; // Clear the list if no data is found
      });
    }
  }

  Future<void> _updateAvailability() async {
    if (_selectedSport == null) {
      // Show an error message or handle the case where no sport is selected
      return;
    }

    try {
      await database.child('$_selectedSport/availability').update({
        'dates': _unavailableDates.map((date) => date.toIso8601String()).toList(),
      });
      // Show a success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated!')),
        );
      }
    } catch (e) {
      // Show an error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating availability: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sport Selection
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Sport'),
                value: _selectedSport,
                onChanged: (value) async {
                  setState(() => _selectedSport = value);
                  await _fetchAvailability(); // Fetch availability when sport is selected
                },
                items: sports.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Date Availability
              const Text('Unavailable Dates:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ..._unavailableDates.map((date) => ListTile(
                title: Text(date.toIso8601String().substring(0, 10)),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () => setState(() => _unavailableDates.remove(date)),
                ),
              )),
              ElevatedButton(
                onPressed: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null && !_unavailableDates.contains(pickedDate)) {
                    setState(() => _unavailableDates.add(pickedDate));
                  }
                },
                child: const Text('Add Unavailable Date'),
              ),
              const SizedBox(height: 30),

              // Update Button
              Center(
                child: ElevatedButton(
                  onPressed: _updateAvailability,
                  child: const Text('Update Availability'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}