import '../widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tracked_action.model.dart';
import '../services/database_service.dart';
import '../widgets/loading_overlay.dart'; // Ensure this matches your widget file path location

class AddRecordScreen extends StatefulWidget {
  final TrackedAction? recordToEdit;

  const AddRecordScreen({super.key, this.recordToEdit});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();

  // 🔒 SECURITY DOUBLE-CLICK BLOCKER LOCKS
  bool _isSaving = false;

  // Form Field Controllers & States
  String _selectedProject = 'Job';
  final _roleController = TextEditingController();
  final _actionTakenController = TextEditingController();
  final _responseStatusController = TextEditingController();
  final _followUpController = TextEditingController();
  
  DateTime _actionDate = DateTime.now();
  DateTime? _followUpDate;

  // Dropdown options
  final List<String> _statusOptions = ['Awaiting Response', 'Successful', 'Rejected', 'Custom...'];
  String _selectedStatus = 'Awaiting Response';
  bool _showCustomStatusInput = false;

  bool get _isEditing => widget.recordToEdit != null;

  @override
  void initState() {
    super.initState();
    
    if (_isEditing) {
      final record = widget.recordToEdit!;
      _selectedProject = record.project;
      _roleController.text = record.roleOpportunity;
      _actionTakenController.text = record.actionTaken;
      _responseStatusController.text = record.responseStatus;
      _followUpController.text = record.followUp;
      _actionDate = record.actionDate;
      _followUpDate = record.followUpDate;

      // Handle custom vs standard status mapping on edit mode load
      if (_statusOptions.contains(record.responseStatus)) {
        _selectedStatus = record.responseStatus;
        _showCustomStatusInput = false;
      } else {
        _selectedStatus = 'Custom...';
        _showCustomStatusInput = true;
      }
    } else {
      _followUpDate = _actionDate.add(const Duration(days: 7));
      _responseStatusController.text = _selectedStatus; // defaults to 'Awaiting Response'
    }
  }

  @override
  void dispose() {
    _roleController.dispose();
    _actionTakenController.dispose();
    _responseStatusController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isActionDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isActionDate ? _actionDate : (_followUpDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isActionDate) {
          _actionDate = picked;
          _followUpDate = _actionDate.add(const Duration(days: 7));
        } else {
          _followUpDate = picked;
        }
      });
    }
  }

  void _submitForm() async {
    // 1. Guard check: Drop press immediately if a network save execution is already processing
    if (_isSaving) return;

    if (_formKey.currentState!.validate()) {
      // 2. Lock down UI access interactions and activate glass overlay animation frames
      setState(() {
        _isSaving = true;
      });

      try {
        // 🎯 COMPILER DOMINO FIX: Grab current active authenticator node tracking user ID
        final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
        if (currentUserId.isEmpty) {
          throw Exception("Missing user identifier session configuration flag");
        }

        // Determine the final status text value to save to Firebase
        String finalStatus = _showCustomStatusInput 
            ? _responseStatusController.text.trim() 
            : _selectedStatus;

        if (finalStatus.isEmpty) finalStatus = "Awaiting Response";

        final updatedRecord = TrackedAction(
          id: widget.recordToEdit?.id,
          userId: currentUserId, // 🎯 INJECTED REQUIRED PARAMETER KEY
          project: _selectedProject,
          roleOpportunity: _roleController.text.trim(),
          actionDate: _actionDate, 
          actionTaken: _actionTakenController.text.trim().isEmpty ? "No Action Provided" : _actionTakenController.text.trim(),
          responseStatus: finalStatus,
          followUp: _followUpController.text.trim().isEmpty ? "No Follow Up Info" : _followUpController.text.trim(),
          followUpDate: _followUpDate,
        );

        if (_isEditing) {
          await _dbService.updateActionRecord(widget.recordToEdit!.id!, updatedRecord);
        } else {
          await _dbService.addActionRecord(updatedRecord);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing ? 'Changes saved successfully!' : 'Record added successfully!'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green.shade800,
            ),
          );
          Navigator.pop(context); 
        }
      } catch (e) {
        // Release locks if transaction failures or structural timeouts strike
        setState(() {
          _isSaving = false;
        });
        debugPrint("实用 🔴 Error handling form submit: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submission failed: ${e.toString()}'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _isEditing ? Colors.amber.shade800 : Colors.blue.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Track Entry' : 'New Track Entry'),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      // 🛠️ Wrap structural layout tree inside a Stack to overlay the frosted loader
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // 1. Projects Dropdown Selector
                  DropdownButtonFormField<String>(
                    value: _selectedProject, 
                    decoration: const InputDecoration(labelText: 'Projects', border: OutlineInputBorder()),
                    items: ['Job', 'Sales'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: _isSaving ? null : (newValue) => setState(() => _selectedProject = newValue!),
                  ),
                  const SizedBox(height: 16),

                  // 2. Role / Opportunity Input
                  TextFormField(
                    controller: _roleController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(labelText: 'Role/Opportunity', border: OutlineInputBorder()),
                    validator: (val) => val!.trim().isEmpty ? 'Please enter a role or opportunity' : null,
                  ),
                  const SizedBox(height: 16),

                  // 3. Action Date Picker Field
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    child: ListTile(
                      title: Text("Action Date: ${_actionDate.toLocal()}".split(' ')[0]),
                      subtitle: const Text("Automatically updates follow-up timeline (+7 days)"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: _isSaving ? null : () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Action Taken Input
                  TextFormField(
                    controller: _actionTakenController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(labelText: 'Action Taken', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  // 5. Response Status Dropdown Selector & Custom Input
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Response Status', border: OutlineInputBorder()),
                    items: _statusOptions.map((String status) {
                      return DropdownMenuItem<String>(value: status, child: Text(status));
                    }).toList(),
                    onChanged: _isSaving ? null : (newValue) {
                      setState(() {
                        _selectedStatus = newValue!;
                        _showCustomStatusInput = _selectedStatus == 'Custom...';
                        if (!_showCustomStatusInput) {
                          _responseStatusController.text = _selectedStatus;
                        }
                      });
                    },
                  ),
                  
                  // Dynamic Text Field that displays ONLY if user taps "Custom..."
                  if (_showCustomStatusInput) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _responseStatusController,
                      enabled: !_isSaving,
                      decoration: const InputDecoration(
                        labelText: 'Enter Custom Response Status',
                        hintText: 'e.g., Scheduled Interview, Under Review',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => _showCustomStatusInput && val!.trim().isEmpty ? 'Please enter your custom status' : null,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 6. Follow Up Note Input
                  TextFormField(
                    controller: _followUpController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(labelText: 'Follow up', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),

                  // 7. Follow Up Date Picker Field
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    child: ListTile(
                      title: Text(_followUpDate == null ? "Follow Up Date (Optional)" : "Follow Up Date: ${_followUpDate!.toLocal()}".split(' ')[0]),
                      subtitle: const Text("Tap to manually adjust outpopulated schedule"),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: _isSaving ? null : () => _selectDate(context, false),
                    ),
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isSaving ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isSaving 
                          ? 'Saving Tracks...' 
                          : (_isEditing ? 'Save Edits' : 'Save Entry to OpTrack'), 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🌟 MODERN FROSTED LOADING GLASS OVERLAY
          EyeCatchingLoadingOverlay(
            isLoading: _isSaving,
            message: _isEditing ? "Updating Database..." : "Publishing to Challenge Workspace...",
          ),
        ],
      ),
    );
  }
}