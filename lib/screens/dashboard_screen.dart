import 'add_record_screen.dart';
import 'login_screen.dart';
import 'dart:async'; 
import 'dart:ui'; 
import 'package:csv/csv.dart'; 
import 'package:universal_html/html.dart' as html; 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:confetti/confetti.dart'; 
import '../services/database_service.dart';
import '../models/tracked_action.model.dart';
import '../widgets/ad_banner_widget.dart'; // 🎯 MOUNT THE REUSABLE GOOGLE AD COMPONENT

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dbService = DatabaseService();
  final DateTime _yearStartDate = DateTime(2026, 5, 20);
  bool _isAdmin = false; 
  bool _viewingOthersProjects = false;

  String _searchQuery = "";
  String _selectedCategoryFilter = "All"; 
  final _searchController = TextEditingController();
  Timer? _debounce;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _checkAdminPrivileges();
  }

  void _checkAdminPrivileges() async {
    bool status = await _dbService.isSuperAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = status;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _confettiController.dispose(); 
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.trim()) {
      case 'Successful': return Colors.green.shade700;
      case 'Rejected': return Colors.red.shade700;
      case 'Awaiting Response':
      case 'Awaiting Responce': return Colors.amber.shade800;
      default: return Colors.blueGrey.shade600;
    }
  }

  Widget _getStatusIcon(String status) {
    switch (status.trim()) {
      case 'Successful': return const Icon(Icons.check_circle, color: Colors.green, size: 18);
      case 'Rejected': return const Icon(Icons.cancel, color: Colors.red, size: 18);
      case 'Awaiting Response':
      case 'Awaiting Responce': return const Icon(Icons.lens, color: Colors.amber, size: 14);
      default: return const Icon(Icons.help_outline, color: Colors.blueGrey, size: 18);
    }
  }

  void _exportToCSV(List<TrackedAction> records) {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Cannot export an empty dataset. Sign in to sync your active logs."))
      );
      return;
    }
    List<List<dynamic>> rows = [];
    rows.add(["Project", "Opportunity / Role", "Action Taken", "Status", "Action Date", "Follow Up Notes", "Follow Up Date"]);

    for (var record in records) {
      rows.add([
        record.project,
        record.roleOpportunity,
        record.actionTaken,
        record.responseStatus,
        record.actionDate.toString().split(' ')[0],
        record.followUp,
        record.followUpDate != null ? record.followUpDate.toString().split(' ')[0] : 'N/A'
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    
    if (kIsWeb) {
      final blob = html.Blob([csvData], 'text/csv', 'native');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "1000_challenge_export.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📱 Mobile export engine initialized safely without browser hooks."))
      );
    }
  }

  void _showAnalyticsPanel(BuildContext context, List<TrackedAction> records) {
    int jobCount = records.where((r) => r.project == 'Job').length;
    int salesCount = records.where((r) => r.project == 'Sales').length;
    int successfulCount = records.where((r) => r.responseStatus == 'Successful').length;
    int rejectedCount = records.where((r) => r.responseStatus == 'Rejected').length;
    int awaitingCount = records.where((r) => r.responseStatus.contains('Awaiting')).length;

    double completionPercentage = records.isNotEmpty ? (records.length / 1000) * 100 : 0.0;
    int closedOutcomes = successfulCount + rejectedCount;
    double successRate = closedOutcomes > 0 ? (successfulCount / closedOutcomes) * 100 : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade50,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              children: [
                Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text("📊 Challenge Analytics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900), overflow: TextOverflow.ellipsis)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(height: 24),
                
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("🏔️ Mountain Progress", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text("${records.length} / 1000", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: completionPercentage / 100,
                            backgroundColor: Colors.blue.shade50,
                            color: Colors.blue.shade700,
                            minHeight: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("${completionPercentage.toStringAsFixed(1)}% of your yearly 1,000 objective secured", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 380) {
                      return Column(
                        children: [
                          _buildGridStatCard("💼 Jobs Count", "$jobCount", Colors.teal.shade700),
                          const SizedBox(height: 12),
                          _buildGridStatCard("💰 Sales Count", "$salesCount", Colors.orange.shade800),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(child: _buildGridStatCard("💼 Jobs Count", "$jobCount", Colors.teal.shade700)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildGridStatCard("💰 Sales Count", "$salesCount", Colors.orange.shade800)),
                        ],
                      );
                    }
                  }
                ),
                const SizedBox(height: 16),

                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.trending_up, color: Colors.green.shade700),
                    ),
                    title: const Text("🏆 Closed Win Rate", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text("Percentage of closed interactions that hit Success status", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    trailing: Text("${successRate.toStringAsFixed(1)}%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  ),
                ),
                const SizedBox(height: 20),

                Text("🎯 Pipeline Funnel Status", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 15)),
                const SizedBox(height: 10),
                
                _buildModernStatusRow("Awaiting Action Response", awaitingCount, Colors.amber.shade800, Icons.hourglass_top),
                _buildModernStatusRow("Successful Transitions", successfulCount, Colors.green.shade700, Icons.check_circle_outline),
                _buildModernStatusRow("Rejected / Closed Logs", rejectedCount, Colors.red.shade700, Icons.block_outlined),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGridStatCard(String title, String count, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildModernStatusRow(String title, int count, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text("$count", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          )
        ],
      ),
    );
  }

  void _confirmDeletion(BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you completely sure you want to permanently delete the tracking entry for '$title'? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dbService.deleteActionRecord(docId);
            },
            child: const Text("Delete permanently", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime yearEndDate = _yearStartDate.add(const Duration(days: 365)).subtract(const Duration(seconds: 1));
    final now = DateTime.now();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    
    int remainingWorkDays = 0;
    for (int i = 0; i <= yearEndDate.difference(now).inDays; i++) {
      final testDay = now.add(Duration(days: i));
      if (testDay.weekday >= DateTime.monday && testDay.weekday <= DateTime.friday) {
        remainingWorkDays++;
      }
    }
    if (remainingWorkDays == 0) remainingWorkDays = 1; 

    return StreamBuilder<List<TrackedAction>>(
      stream: _dbService.getTrackedActionsStream(_isAdmin), 
      builder: (context, snapshot) {
        List<TrackedAction> rawRecords = [];
        bool showGuestLockBanner = false;

        if (snapshot.hasError) {
          if (snapshot.error.toString().contains('permission-denied') || FirebaseAuth.instance.currentUser == null) {
            showGuestLockBanner = true;
            rawRecords = []; 
          }
        } else if (snapshot.hasData) {
          rawRecords = snapshot.data!;
        }

        List<TrackedAction> displayedRecords = [];
        if (!showGuestLockBanner) {
          if (_isAdmin && _viewingOthersProjects) {
            displayedRecords = rawRecords.where((rec) => rec.userId != currentUserId).toList();
          } else {
            displayedRecords = rawRecords.where((rec) => rec.userId == currentUserId).toList();
          }
        }

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text(
                  _isAdmin 
                    ? (_viewingOthersProjects ? '👥 Team Work Tracks' : '👑 Admin Workspace')
                    : '1000 Challenge Feeds',
                  style: const TextStyle(fontSize: 18),
                ),
                centerTitle: true,
                backgroundColor: _isAdmin 
                    ? (_viewingOthersProjects ? Colors.amber.shade900 : Colors.purple.shade900)
                    : Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              drawer: Drawer(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: _isAdmin ? Colors.purple.shade900 : Colors.blue.shade700, 
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isAdmin ? Icons.gavel : Icons.account_circle, 
                            color: Colors.white, 
                            size: 44
                          ),
                          const SizedBox(height: 8),
                          Text(
                            FirebaseAuth.instance.currentUser != null
                                ? '${_isAdmin ? "👑 SUPER ADMIN" : "Active Profile"}:\n${FirebaseAuth.instance.currentUser!.email}'
                                : 'Challenge Security: Locked',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
                    ListTileTheme(
                      data: const ListTileThemeData(dense: true),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.dashboard, color: (!_viewingOthersProjects) ? Colors.deepPurple : Colors.grey),
                            title: Text(
                              'My Private Dashboard', 
                              style: TextStyle(fontWeight: !_viewingOthersProjects ? FontWeight.bold : FontWeight.normal)
                            ),
                            selected: !_viewingOthersProjects,
                            onTap: () {
                              setState(() => _viewingOthersProjects = false);
                              Navigator.pop(context);
                            },
                          ),
                          if (_isAdmin)
                            ListTile(
                              leading: Icon(Icons.people_alt, color: _viewingOthersProjects ? Colors.amber.shade900 : Colors.grey),
                              title: Text(
                                'View Others\' Work', 
                                style: TextStyle(fontWeight: _viewingOthersProjects ? FontWeight.bold : FontWeight.normal, color: _viewingOthersProjects ? Colors.amber.shade900 : Colors.black87)
                              ),
                              selected: _viewingOthersProjects,
                              onTap: () {
                                setState(() => _viewingOthersProjects = true);
                                Navigator.pop(context);
                              },
                            ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.analytics, color: Colors.blue),
                            title: const Text('Milestones & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () {
                              Navigator.pop(context); 
                              _showAnalyticsPanel(context, displayedRecords); 
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.file_download, color: Colors.green),
                            title: const Text('Export Feed to CSV', style: TextStyle(fontWeight: FontWeight.bold)),
                            onTap: () {
                              Navigator.pop(context); 
                              _exportToCSV(displayedRecords); 
                            },
                          ),
                          const Divider(),
                          if (FirebaseAuth.instance.currentUser == null) ...[
                            ListTile(
                              leading: const Icon(Icons.login, color: Colors.blue),
                              title: const Text('Sign In Gateway', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                              },
                            ),
                          ] else ...[
                            ListTile(
                              leading: const Icon(Icons.logout, color: Colors.red),
                              title: const Text('Secure Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  (() {
                    final upcomingFollowups = displayedRecords.where((item) {
                      if (item.followUpDate == null) return false;
                      final dateDifference = item.followUpDate!.difference(now).inDays;
                      return dateDifference >= 1 && dateDifference <= 2;
                    }).toList();

                    if (upcomingFollowups.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200, width: 1.5)
                      ),
                      child: ExpansionTile(
                        leading: Icon(Icons.notification_important, color: Colors.red.shade800, size: 26),
                        title: Text(
                          "Alert: ${upcomingFollowups.length} Follow-ups Due within 48 Hours!",
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: const Text("Cloud reminders scheduled via automation engine.", style: TextStyle(fontSize: 11, color: Colors.black54)),
                        children: upcomingFollowups.map((record) {
                          return ListTile(
                            dense: true,
                            title: Text("🎯 ${record.roleOpportunity} (${record.project})", style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Action Notes: ${record.followUp}\nDue Date: ${record.followUpDate.toString().split(' ')[0]}"),
                            trailing: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.red.shade700),
                          );
                        }).toList(),
                      ),
                    );
                  }()),

                  if (showGuestLockBanner)
                    Container(
                      width: double.infinity,
                      color: Colors.amber.shade50,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.lock_person, color: Colors.amber.shade900, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "🔒 App Workspace Locked: Please open the menu drawer slider and click 'Sign In Gateway' to authenticate and view your personalized entries.",
                              style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildCoachCard(displayedRecords, remainingWorkDays, yearEndDate, now),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: TextField(
                      key: const ValueKey('optrack_search_bar_input'),
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search role, opportunity, or status...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: Row(
                      children: ["All", "Job", "Sales"].map<Widget>((category) {
                        final isSelected = _selectedCategoryFilter == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedCategoryFilter = category);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  Expanded(
                    child: _buildFilteredList(displayedRecords, now, showGuestLockBanner),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  if (FirebaseAuth.instance.currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("🔒 Unauthorized: Please sign in first to add records."))
                    );
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRecordScreen()));
                },
                backgroundColor: _isAdmin 
                    ? (_viewingOthersProjects ? Colors.amber.shade900 : Colors.purple.shade900)
                    : Colors.blue.shade700,
                foregroundColor: Colors.white,
                child: const Icon(Icons.add),
              ),
              
              // 🎯 SURGICAL AD INTEGRATION BLOCK
              // Houses your dynamic 320x50 AdMob processing layout directly beneath your scroll feed
              bottomNavigationBar: const SafeArea(
                child: AdBannerWidget(),
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilteredList(List<TrackedAction> filteredList, DateTime now, bool isGuestMode) {
    if (isGuestMode) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_shared_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('No records to display. Log in to synchronize dashboard data.', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final filtered = filteredList.where((item) {
      final matchesCategory = _selectedCategoryFilter == "All" || item.project == _selectedCategoryFilter;
      final matchesSearch = item.roleOpportunity.toLowerCase().contains(_searchQuery) ||
                            item.actionTaken.toLowerCase().contains(_searchQuery) ||
                            item.responseStatus.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text('No entries match your search filters.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        final item = filtered[index];
        final actionDateStr = "${item.actionDate.toLocal()}".split(' ')[0];
        final followUpDateStr = item.followUpDate != null ? "${item.followUpDate!.toLocal()}".split(' ')[0] : 'N/A';
        final statusColor = _getStatusColor(item.responseStatus);

        final bool requiresFollowUpToday = item.followUpDate != null &&
            item.followUpDate!.year == now.year &&
            item.followUpDate!.month == now.month &&
            item.followUpDate!.day == now.day;

        return Card(
          elevation: 2,
          shape: requiresFollowUpToday 
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.redAccent, width: 2))
              : null,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ExpansionTile(
            leading: Chip(
              key: ValueKey('project_chip_${item.id ?? index}'),
              label: Text(item.project, style: const TextStyle(fontSize: 12)),
              backgroundColor: item.project == 'Job' ? Colors.teal.shade50 : Colors.orange.shade50,
              padding: EdgeInsets.zero,
            ),
            title: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(item.roleOpportunity, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                _getStatusIcon(item.responseStatus),
                if (requiresFollowUpToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(4)),
                    child: const Text("⚠️ FOLLOW UP TODAY", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text("Action Taken: ${item.actionTaken}\nDate: $actionDateStr", style: const TextStyle(fontSize: 13)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text("📊 Status: ", style: TextStyle(fontSize: 13)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            item.responseStatus,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                        if (_isAdmin && _viewingOthersProjects)
                          Text(
                            "👤 ID: ${(item.userId ?? '').toString().length > 6 ? (item.userId ?? '').toString().substring(0, 6) : (item.userId ?? '')}...",
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("Note: ${item.followUp}", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    Text("📆 Follow up schedule: $followUpDateStr", style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          label: const Text("Delete", style: TextStyle(color: Colors.red, fontSize: 12)),
                          onPressed: () => _confirmDeletion(context, item.id!, item.roleOpportunity),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text("Edit", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AddRecordScreen(recordToEdit: item)));
                          },
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoachCard(List<TrackedAction> records, int remainingWorkDays, DateTime yearEndDate, DateTime now) {
    final todayRecords = records.where((rec) => rec.actionDate.year == now.year && rec.actionDate.month == now.month && rec.actionDate.day == now.day).length;
    const int dailyTarget = 4;
    final bool isDailyTargetMet = todayRecords >= dailyTarget;

    final mondayOffset = now.weekday - 1;
    final currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: mondayOffset));
    final currentFridayEnd = currentMonday.add(const Duration(days: 4, hours: 23, minutes: 59, seconds: 59));

    final thisWeekRecords = records.where((rec) => rec.actionDate.isAfter(currentMonday.subtract(const Duration(seconds: 1))) && rec.actionDate.isBefore(currentFridayEnd)).length;
    const int totalWeekBaselineGoal = 20;

    int weekDeficit = totalWeekBaselineGoal - thisWeekRecords;
    if (weekDeficit < 0) weekDeficit = 0;

    int projectsRemainingForYear = 1000 - records.length;
    if (projectsRemainingForYear < 0) projectsRemainingForYear = 0;
    double recoveryRatePerDay = projectsRemainingForYear / remainingWorkDays;

    return Card(
      margin: const EdgeInsets.all(12),
      color: _isAdmin 
          ? (_viewingOthersProjects ? Colors.amber.shade50 : Colors.purple.shade50) 
          : Colors.blue.shade50,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _viewingOthersProjects ? "👥 Global Active Baseline:" : "📆 Calendar Cycle:", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isAdmin ? (_viewingOthersProjects ? Colors.amber.shade900 : Colors.purple.shade900) : Colors.blue.shade900)
                ),
                Text("2026 ➡️ ${yearEndDate.year}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isAdmin ? (_viewingOthersProjects ? Colors.amber.shade900 : Colors.purple.shade900) : Colors.blue.shade900)),
              ],
            ),
            const Divider(height: 16),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text("🎯 Submissions today: $todayRecords / $dailyTarget", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                if (isDailyTargetMet && records.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                    child: const Text("🔥 Quota Met!", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text("${dailyTarget - todayRecords} left today", style: TextStyle(color: Colors.orange.shade900, fontSize: 10, fontWeight: FontWeight.bold))
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text("📊 Weekly Performance: $thisWeekRecords / $totalWeekBaselineGoal", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            if (weekDeficit > 0)
              Text("⚠️ Need $weekDeficit more entries by Friday night to hit target.", style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))
            else
              const Text("🎉 Week Status: Weekly target achieved!", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.speed, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _viewingOthersProjects 
                        ? "Monitoring Team Velocity: Tracking ${records.length} global actions submitted across workspace streams."
                        : "Blueprint Pace: You have ${records.length} records. Submit ${recoveryRatePerDay.toStringAsFixed(2)} actions per weekday to clear the 1,000 tracker!",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}