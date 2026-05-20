import 'package:cloud_firestore/cloud_firestore.dart';

class TrackedAction {
  final String? id;
  final String project;
  final String roleOpportunity;
  final String actionTaken;
  final String responseStatus;
  final DateTime actionDate;
  final String followUp;
  final DateTime? followUpDate;
  final String userId; // 💡 Non-nullable string ensures absolute alignment with query filtering locks

  TrackedAction({
    this.id,
    required this.project,
    required this.roleOpportunity,
    required this.actionTaken,
    required this.responseStatus,
    required this.actionDate,
    required this.followUp,
    this.followUpDate,
    required this.userId, // Required parameter ensures a user ID is always attached
  });

  // Convert model data out into standard json structure for Firestore collection writes
  Map<String, dynamic> toFirestore() {
    return {
      'project': project,
      'roleOpportunity': roleOpportunity,
      'actionTaken': actionTaken,
      'responseStatus': responseStatus,
      'actionDate': Timestamp.fromDate(actionDate),
      'followUp': followUp,
      'followUpDate': followUpDate != null ? Timestamp.fromDate(followUpDate!) : null,
      'userId': userId,
    };
  }

  // Bind incoming document snapshots back into clean instance definitions
  factory TrackedAction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Process actionDate parsing safely
    DateTime parsedActionDate = DateTime.now();
    if (data['actionDate'] != null) {
      parsedActionDate = (data['actionDate'] as Timestamp).toDate();
    }

    return TrackedAction(
      id: doc.id,
      project: data['project'] ?? '',
      roleOpportunity: data['roleOpportunity'] ?? '',
      actionTaken: data['actionTaken'] ?? '',
      responseStatus: data['responseStatus'] ?? '',
      actionDate: parsedActionDate,
      followUp: data['followUp'] ?? '',
      userId: data['userId'] ?? '',
      // 🛡️ TYPE-SAFE PARSING: Gracefully unpacks date string configurations or timestamps
      followUpDate: data['followUpDate'] == null
          ? null
          : (data['followUpDate'] is String 
              ? DateTime.parse(data['followUpDate']) 
              : (data['followUpDate'] as Timestamp).toDate()),
    );
  }
}