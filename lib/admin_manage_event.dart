import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class AdminEvent extends StatefulWidget {
  const AdminEvent({super.key});

  @override
  State<AdminEvent> createState() => _AdminEventState();
}

class _AdminEventState extends State<AdminEvent> {
  final database = FirebaseDatabase.instance.ref();
  final storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _walletAmountController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _requireWallet = false;
  XFile? _imageFile;
  String? _eventId; // To store the ID of the event being modified
  bool _isModifying = false; // Flag to track if modifying or creating

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _walletAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }


  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final eventName = _nameController.text.trim();
        final storageRef = storage.ref().child('event_images/$userId/$eventName');
        final uploadTask = await storageRef.putFile(File(_imageFile!.path));
        final imageUrl = await uploadTask.ref.getDownloadURL();
        // ignore: use_build_context_synchronously
        final formattedTime = _selectedTime?.format(context) ?? '';

        // Corrected line: remove 'await'
        final newEventRef = database.child('events').push(); 
        await newEventRef.set({
          'name': eventName,
          'description': _descriptionController.text.trim(),
          'date': _dateController.text.trim(),
          'time': formattedTime,
          'location': _locationController.text.trim(),
          'maxParticipants': int.parse(_maxParticipantsController.text.trim()),
          'requireWallet': _requireWallet,
          'walletAmount': _requireWallet ? int.parse(_walletAmountController.text.trim()) : 0,
          'imageUrl': imageUrl,
          'participants': 0, // Initialize participant count to 0
        });
          // Show a success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully!')),
          );
        }
        // Clear the form and reset state
        _formKey.currentState!.reset();
        setState(() {
          _imageFile = null;
          _requireWallet = false;
        });
      } catch (e) {
        // Show an error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating event: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateEvent() async {
    if (_formKey.currentState!.validate() && _eventId != null) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final eventName = _nameController.text.trim();
        String imageUrl = '';

        // Upload image if a new one is selected, otherwise keep the original
        if (_imageFile != null) {
          final storageRef = storage.ref().child('event_images/$userId/$eventName');
          final uploadTask = await storageRef.putFile(File(_imageFile!.path));
          imageUrl = await uploadTask.ref.getDownloadURL();
        } else {
          // Retrieve the original image URL from the database
          final eventSnapshot = await database.child('events/$_eventId').get();
          if (eventSnapshot.exists) {
            final eventData = Map<String, dynamic>.from(eventSnapshot.value as Map);
            imageUrl = eventData['imageUrl'];
          }
        }

        await database.child('events/$_eventId').update({
          'name': eventName,
          'description': _descriptionController.text.trim(),
          'date': _dateController.text.trim(),
          'location': _locationController.text.trim(),
          'maxParticipants': int.parse(_maxParticipantsController.text.trim()),
          'requireWallet': _requireWallet,
          'walletAmount': _requireWallet ? int.parse(_walletAmountController.text.trim()) : 0,
          'imageUrl': imageUrl, // Use the retrieved or new image URL
        });

        // Show a success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event updated successfully!')),
          );
        }
        // Clear the form and reset state
        _formKey.currentState!.reset();
        setState(() {
          _imageFile = null;
          _requireWallet = false;
          _eventId = null;
          _isModifying = false;
        });
      } catch (e) {
        // Show an error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating event: $e')),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  // Function to display the list of events for modification
  Future<void> _showEventList() async {
    final eventSnapshot = await database.child('events').get();
    if (eventSnapshot.exists) {
      final eventMap = Map<String, dynamic>.from(eventSnapshot.value as Map);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Select Event to Modify'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: eventMap.length,
                  itemBuilder: (context, index) {
                    final eventId = eventMap.keys.elementAt(index);
                    final eventData = Map<String, dynamic>.from(eventMap[eventId]);
                    return ListTile(
                      title: Text(eventData['name']),
                      onTap: () {
                        if (mounted) {  // Add a mounted check here
                          _loadEventData(eventId, eventData);
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  },
                ),
              ),
            );
          },
        );
      } 
    } else {
      // Show a message if no events are found
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No events found.')),
        );
      }
    }
  }

  // Function to load event data into the form for modification
  void _loadEventData(String eventId, Map<String, dynamic> eventData) {
    setState(() {
      _eventId = eventId;
      _isModifying = true;
      _nameController.text = eventData['name'];
      _descriptionController.text = eventData['description'];
      _dateController.text = eventData['date'];
      _locationController.text = eventData['location'];
      _maxParticipantsController.text = eventData['maxParticipants'].toString();
      _requireWallet = eventData['requireWallet'];
      _walletAmountController.text = eventData['walletAmount'].toString();
      // Handle image loading if needed
    });
  }

  // Function to delete an event
  Future<void> _deleteEvent() async {
    if (_eventId != null) {
      try {
        await database.child('events/$_eventId').remove();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event deleted successfully!')),
          );
        }
        // Clear the form and reset state
        _formKey.currentState!.reset();
        setState(() {
          _imageFile = null;
          _requireWallet = false;
          _eventId = null;
          _isModifying = false;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting event: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Event'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Radio buttons to choose between creating and modifying
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Create Event'),
                  Radio<bool>(
                    value: false,
                    groupValue: _isModifying,
                    onChanged: (value) {
                      setState(() {
                        _isModifying = value!;
                        _formKey.currentState!.reset(); // Clear form when switching
                        _imageFile = null;
                        _requireWallet = false;
                        _eventId = null;
                      });
                    },
                  ),
                  const Text('Modify Event'),
                  Radio<bool>(
                    value: true,
                    groupValue: _isModifying,
                    onChanged: (value) {
                      setState(() {
                        _isModifying = value!;
                        _formKey.currentState!.reset(); // Clear form when switching
                        _imageFile = null;
                        _requireWallet = false;
                        _eventId = null;
                      });
                      _showEventList(); // Show event list when modifying
                    },
                  ),
                ],
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Event Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter event name';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(labelText: 'Date'),
                      onTap: () => _selectDate(context), // Call the date picker
                      readOnly: true, // Prevent manual editing
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    ElevatedButton(
                      onPressed: () => _selectTime(context),
                      child: const Text('Select Time'),
                    ),
                    if (_selectedTime != null)
                      Text(
                        'Selected Time: ${_selectedTime!.format(context)}',
                      ),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter location';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _maxParticipantsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Participants'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter max participants';
                        }
                        return null;
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Require SukanCoin to participate'),
                      value: _requireWallet,
                      onChanged: (value) {
                        setState(() {
                          _requireWallet = value!;
                        });
                      },
                    ),
                    if (_requireWallet)
                      TextFormField(
                        controller: _walletAmountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'SukanCoin Amount'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter SukanCoin amount';
                          }
                          return null;
                        },
                      ),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Upload Image'),
                    ),
                    if (_imageFile != null)
                      Image.file(File(_imageFile!.path)),
                    // Show different buttons based on whether creating or modifying
                    if (_isModifying)
                      ElevatedButton(
                        onPressed: _updateEvent,
                        child: const Text('Update Event'),
                      )
                    else
                      ElevatedButton(
                        onPressed: _createEvent,
                        child: const Text('Create Event'),
                      ),
                    // Add a delete button for modifying events
                    if (_isModifying)
                      ElevatedButton(
                        onPressed: _deleteEvent,
                        child: const Text('Delete Event'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}