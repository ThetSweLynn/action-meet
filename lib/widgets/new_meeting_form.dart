import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/smtp_mail_service.dart';

class NewMeetingForm extends StatefulWidget {
  final Map<String, dynamic>? existingMeeting;
  final String? documentId;

  const NewMeetingForm({super.key, this.existingMeeting, this.documentId});

  @override
  State<NewMeetingForm> createState() => _NewMeetingFormState();
}

class _NewMeetingFormState extends State<NewMeetingForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _linkController = TextEditingController();
  final _memberEmailController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _meetingType = 'onsite';
  final List<String> _members = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingMeeting != null) {
      final meeting = widget.existingMeeting!;
      _titleController.text = meeting['title'] ?? '';
      _placeController.text = meeting['place'] ?? '';
      _linkController.text = meeting['link'] ?? '';
      _selectedDate = (meeting['date'] as Timestamp?)?.toDate();
      _meetingType = meeting['type'] ?? 'onsite';
      if (meeting['members'] != null) {
        _members.addAll(List<String>.from(meeting['members']));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // After selecting date, prompt for time
      if (context.mounted) {
        _selectTime(context);
      }
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

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You must be logged in')),
          );
          return;
        }

        final meetingData = {
          'title': _titleController.text.trim(),
          'date': _selectedDate,
          'time': _selectedTime != null
              ? '${_selectedTime!.hour}:${_selectedTime!.minute}'
              : null,
          'type': _meetingType,
          'place': _meetingType == 'onsite'
              ? _placeController.text.trim()
              : null,
          'link': _meetingType == 'online' ? _linkController.text.trim() : null,
          'members': _members,
          if (widget.documentId == null)
            'createdAt': FieldValue.serverTimestamp(),
          if (widget.documentId == null) 'createdBy': user.email,
        };

        if (widget.documentId != null) {
          // Update existing meeting
          await FirebaseFirestore.instance
              .collection('meetings')
              .doc(widget.documentId)
              .update(meetingData);
          if (context.mounted) {
            Navigator.pop(context);
            final snack = SnackBar(
              content: const Text('Meeting updated successfully'),
              action: _members.isNotEmpty
                  ? SnackBarAction(
                      label: 'Send Invites',
                      onPressed: () async {
                        final subject =
                            'You were invited: ${_titleController.text.trim()}';
                        final dateText = _selectedDate != null
                            ? _selectedDate.toString().split(' ')[0]
                            : 'No date';
                        final body =
                            'You\'ve been invited to "${_titleController.text.trim()}".\n\nDate: $dateText\nTime: ${_selectedTime?.format(context) ?? 'Not specified'}\n${_meetingType == 'online' ? 'Link: ${_linkController.text.trim()}\n' : 'Place: ${_placeController.text.trim()}\n'}';
                        try {
                          // Send invitation email via SMTP
                          await SmtpMailService.sendMeetingInvitation(
                            recipients: _members,
                            subject: subject,
                            body: body,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invites sent successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to send invites via SMTP: $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    )
                  : null,
            );
            ScaffoldMessenger.of(context).showSnackBar(snack);
          }
        } else {
          // Create new meeting
          await FirebaseFirestore.instance
              .collection('meetings')
              .add(meetingData);
          if (context.mounted) {
            Navigator.pop(context);
            final snack = SnackBar(
              content: const Text('Meeting created successfully'),
              action: _members.isNotEmpty
                  ? SnackBarAction(
                      label: 'Send Invites',
                      onPressed: () async {
                        final subject =
                            'You were invited: ${_titleController.text.trim()}';
                        final dateText = _selectedDate != null
                            ? _selectedDate.toString().split(' ')[0]
                            : 'No date';
                        final body =
                            'You\'ve been invited to "${_titleController.text.trim()}".\n\nDate: $dateText\nTime: ${_selectedTime?.format(context) ?? 'Not specified'}\n${_meetingType == 'online' ? 'Link: ${_linkController.text.trim()}\n' : 'Place: ${_placeController.text.trim()}\n'}';
                        try {
                          await SmtpMailService.sendMeetingInvitation(
                            recipients: _members,
                            subject: subject,
                            body: body,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invites sent successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to send invites via SMTP: $e',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    )
                  : null,
            );
            ScaffoldMessenger.of(context).showSnackBar(snack);
          }
        }
      } catch (e) {
        debugPrint('Error submitting meeting: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.documentId != null;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 24),
      backgroundColor: const Color(0xFFF5F3F8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isUpdate ? 'Update Meeting' : 'New Meeting',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Meeting Title',
                  hintStyle: const TextStyle(color: Color(0xFF808080)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF2D2D2D),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(
                  Navigator.of(context, rootNavigator: true).context,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Date & Time'
                            : '${_selectedDate.toString().split(' ')[0]} ${_selectedTime?.format(context) ?? 'Select Time'}',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? const Color(0xFF808080)
                              : const Color(0xFF2D2D2D),
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _members
                        .map(
                          (email) => Chip(
                            label: Text(email),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () =>
                                setState(() => _members.remove(email)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _memberEmailController,
                    decoration: InputDecoration(
                      hintText: 'Add member email',
                      hintStyle: const TextStyle(color: Color(0xFF808080)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF2D2D2D),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final email = _memberEmailController.text.trim();
                          if (email.isNotEmpty && email.contains('@')) {
                            setState(() {
                              if (!_members.contains(email)) {
                                _members.add(email);
                                _memberEmailController.clear();
                              }
                            });
                          }
                        },
                      ),
                    ),
                    onFieldSubmitted: (email) {
                      email = email.trim();
                      if (email.isNotEmpty && email.contains('@')) {
                        setState(() {
                          if (!_members.contains(email)) {
                            _members.add(email);
                            _memberEmailController.clear();
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile(
                        title: const Text('On-site'),
                        value: 'onsite',
                        groupValue: _meetingType,
                        onChanged: (value) =>
                            setState(() => _meetingType = value.toString()),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile(
                        title: const Text('Online'),
                        value: 'online',
                        groupValue: _meetingType,
                        onChanged: (value) =>
                            setState(() => _meetingType = value.toString()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_meetingType == 'onsite')
                TextFormField(
                  controller: _placeController,
                  decoration: InputDecoration(
                    hintText: 'Place',
                    hintStyle: const TextStyle(color: Color(0xFF808080)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D2D2D),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  validator: (value) =>
                      _meetingType == 'onsite' && (value?.isEmpty ?? true)
                      ? 'Please enter a place'
                      : null,
                ),
              if (_meetingType == 'online')
                TextFormField(
                  controller: _linkController,
                  decoration: InputDecoration(
                    hintText: 'Meeting Link',
                    hintStyle: const TextStyle(color: Color(0xFF808080)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D2D2D),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                  ),
                  validator: (value) =>
                      _meetingType == 'online' && (value?.isEmpty ?? true)
                      ? 'Please enter a meeting link'
                      : null,
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2D2D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isUpdate ? 'UPDATE' : 'CREATE',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _linkController.dispose();
    _memberEmailController.dispose();
    super.dispose();
  }
}
