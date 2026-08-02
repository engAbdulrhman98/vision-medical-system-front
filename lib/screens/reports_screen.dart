import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportsScreen extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;

  const ReportsScreen({
    super.key,
    required this.language,
    this.token = '',
    this.backendUrl = '',
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late String _lang;
  String _searchQuery = '';

  final List<Map<String, String>> _mockReports = [
    {
      'id': 'REP-001',
      'deviceName': 'Optima MR450 MRI Scanner',
      'summary': 'Routine calibration and field homogeneity check.',
      'findings': 'Homogeneity was slightly off by 1.2 ppm in the Z-axis. RF coils are functioning within nominal parameters.',
      'actionsTaken': 'Performed magnetic field shimming. Calibrated receiver coils and ran phantom scans.',
      'status': 'Approved',
      'date': '2026-07-05',
    },
    {
      'id': 'REP-002',
      'deviceName': 'Engström Carestation Ventilator',
      'summary': 'Oxygen sensor failure and replacement.',
      'findings': 'O2 sensor reading 15% lower than baseline calibration. Flow control valve is intact.',
      'actionsTaken': 'Replaced old O2 sensor cell with new stock item. Recalibrated O2 concentration curves.',
      'status': 'Approved',
      'date': '2026-07-08',
    },
    {
      'id': 'REP-003',
      'deviceName': 'Brivo XR X-Ray Machine',
      'summary': 'Collimator rotation mechanism inspection.',
      'findings': 'Dust accumulation in the rotor bearings causing friction and noise during adjustment.',
      'actionsTaken': 'Cleaned collimator assembly, lubricated mechanical gears, and verified alignment under low dose.',
      'status': 'Pending',
      'date': '2026-07-09',
    },
  ];

  List<Map<String, String>> _reports = [];

  final List<String> _devicesList = [
    'Optima MR450 MRI Scanner',
    'Vivid E90 Ultrasound',
    'Engström Carestation Ventilator',
    'Defibtech Lifeline ECG',
    'Brivo XR X-Ray Machine',
  ];

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'title': 'Maintenance Reports',
      'search': 'Search reports by device...',
      'new_report': 'Create Report',
      'status_approved': 'Approved',
      'status_pending': 'Pending Review',
      'device': 'Device / Equipment',
      'summary': 'Summary',
      'findings': 'Technical Findings',
      'actions': 'Actions Taken',
      'date': 'Date Created',
      'status': 'Status',
      'submit': 'Submit Report',
      'cancel': 'Cancel',
      'empty': 'No reports found.',
      'field_empty': 'This field cannot be empty',
      'success_msg': 'Report submitted successfully!',
      'stats_total': 'Total Reports',
      'stats_approved': 'Approved',
      'stats_pending': 'Pending',
    },
    'ar': {
      'title': 'تقارير الصيانة',
      'search': 'البحث عن تقرير بالجهاز...',
      'new_report': 'إنشاء تقرير جديد',
      'status_approved': 'معتمد',
      'status_pending': 'قيد المراجعة',
      'device': 'الأجهزة الطبية',
      'summary': 'ملخص التقرير',
      'findings': 'النتائج الفنية والأعطال',
      'actions': 'الإجراءات المتخذة',
      'date': 'تاريخ التقرير',
      'status': 'حالة التقرير',
      'submit': 'إرسال التقرير',
      'cancel': 'إلغاء',
      'empty': 'لا توجد تقارير صيانة حالياً.',
      'field_empty': 'هذا الحقل مطلوب ولا يمكن تركه فارغاً',
      'success_msg': 'تم تسجيل تقرير الصيانة بنجاح!',
      'stats_total': 'إجمالي التقارير',
      'stats_approved': 'معتمدة',
      'stats_pending': 'قيد الانتظار',
    }
  };

  bool _isLoading = false;
  List<dynamic> _dbTasks = [];

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
    _loadReports();
    _loadTasks();
  }

  String t(String key) {
    return _localized[_lang]?[key] ?? key;
  }

  Future<void> _loadReports() async {
    if (widget.token.isEmpty) {
      setState(() {
        _reports = List.from(_mockReports);
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${widget.backendUrl}/maintenance-reports'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded is List ? decoded : [];
        
        setState(() {
          _reports = list.map<Map<String, String>>((item) {
            final summaryMap = item['summary'] is Map ? item['summary'] : {};
            final summaryStr = _lang == 'ar' 
                ? (summaryMap['ar'] ?? summaryMap['en'] ?? '') 
                : (summaryMap['en'] ?? summaryMap['ar'] ?? '');

            final devNameMap = item['deviceName'] is Map ? item['deviceName'] : {};
            final devNameStr = _lang == 'ar'
                ? (devNameMap['ar'] ?? devNameMap['en'] ?? '')
                : (devNameMap['en'] ?? devNameMap['ar'] ?? '');

            final statusVal = item['status']?.toString().toLowerCase() ?? 'submitted';
            final uiStatus = (statusVal == 'approved') ? 'Approved' : 'Pending';

            final dateStr = item['created_at']?.toString().split(' ')[0] ?? '';

            return {
              'id': item['id']?.toString() ?? '',
              'deviceName': devNameStr.isNotEmpty ? devNameStr : (item['deviceName']?.toString() ?? 'N/A'),
              'summary': summaryStr.isNotEmpty ? summaryStr : (item['summary']?.toString() ?? ''),
              'findings': item['findings']?.toString() ?? '',
              'actionsTaken': item['actions_taken']?.toString() ?? '',
              'status': uiStatus,
              'date': dateStr,
            };
          }).toList();
        });
      }
    } catch (_) {
      setState(() {
        _reports = List.from(_mockReports);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTasks() async {
    if (widget.token.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('${widget.backendUrl}/tasks'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            _dbTasks = decoded;
          });
        }
      }
    } catch (_) {}
  }

  void _showCreateReportDialog() {
    final formKey = GlobalKey<FormState>();
    String selectedDevice = _devicesList.first;
    final summaryController = TextEditingController();
    final findingsController = TextEditingController();
    final actionsController = TextEditingController();
    dynamic selectedTask;
    if (_dbTasks.isNotEmpty) {
      selectedTask = _dbTasks.first;
    }
    bool dialogLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Text(
                  t('new_report'),
                  style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Device/Task Dropdown
                        Text(t('device'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        if (widget.token.isNotEmpty && _dbTasks.isNotEmpty) ...[
                          DropdownButtonFormField<dynamic>(
                            initialValue: selectedTask,
                            items: _dbTasks.map((t) {
                              final titleMap = t['title'] is Map ? t['title'] : {};
                              final titleStr = _lang == 'ar'
                                  ? (titleMap['ar'] ?? titleMap['en'] ?? '')
                                  : (titleMap['en'] ?? titleMap['ar'] ?? '');
                              
                              final devNameMap = t['device_product_name'] is Map ? t['device_product_name'] : {};
                              final devNameStr = _lang == 'ar'
                                  ? (devNameMap['ar'] ?? devNameMap['en'] ?? '')
                                  : (devNameMap['en'] ?? devNameMap['ar'] ?? '');

                              final displayName = devNameStr.isNotEmpty 
                                  ? '$titleStr ($devNameStr)' 
                                  : titleStr;

                              return DropdownMenuItem(
                                value: t,
                                child: Text(
                                  displayName,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedTask = val;
                              });
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ] else ...[
                          DropdownButtonFormField<String>(
                            initialValue: selectedDevice,
                            items: _devicesList.map((d) {
                              return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                selectedDevice = val;
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Summary Input
                        Text(t('summary'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: summaryController,
                          validator: (value) => value == null || value.trim().isEmpty ? t('field_empty') : null,
                          decoration: InputDecoration(
                            hintText: 'Calibration, filter swap, etc.',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Findings Input
                        Text(t('findings'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: findingsController,
                          maxLines: 3,
                          validator: (value) => value == null || value.trim().isEmpty ? t('field_empty') : null,
                          decoration: InputDecoration(
                            hintText: 'What issues were detected?',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Actions Taken Input
                        Text(t('actions'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: actionsController,
                          maxLines: 3,
                          validator: (value) => value == null || value.trim().isEmpty ? t('field_empty') : null,
                          decoration: InputDecoration(
                            hintText: 'What action was taken to resolve this?',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t('cancel'), style: TextStyle(color: Colors.grey[600])),
                  ),
                  ElevatedButton(
                    onPressed: dialogLoading ? null : () async {
                      if (formKey.currentState!.validate()) {
                        if (widget.token.isNotEmpty && _dbTasks.isNotEmpty && selectedTask != null) {
                          setDialogState(() => dialogLoading = true);
                          try {
                            final payload = {
                              'task_id': selectedTask['id'].toString(),
                              'summary_ar': _lang == 'ar' ? summaryController.text.trim() : '',
                              'summary_en': _lang != 'ar' ? summaryController.text.trim() : '',
                              'findings': findingsController.text.trim(),
                              'actions_taken': actionsController.text.trim(),
                            };
                            if (payload['summary_ar']!.isEmpty) payload['summary_ar'] = payload['summary_en']!;
                            if (payload['summary_en']!.isEmpty) payload['summary_en'] = payload['summary_ar']!;

                            final res = await http.post(
                              Uri.parse('${widget.backendUrl}/maintenance-reports'),
                              headers: {
                                'Authorization': 'Bearer ${widget.token}',
                                'Content-Type': 'application/json',
                                'Accept': 'application/json',
                              },
                              body: jsonEncode(payload),
                            ).timeout(const Duration(seconds: 5));

                            if (res.statusCode == 201) {
                              _loadReports();
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(t('success_msg')),
                                    backgroundColor: Colors.teal[800],
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _lang == 'ar' 
                                          ? 'خطأ من الخادم عند حفظ التقرير' 
                                          : 'Server error saving report',
                                    ),
                                    backgroundColor: Colors.red[800],
                                  ),
                                );
                              }
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _lang == 'ar' 
                                        ? 'فشل الاتصال بالخادم' 
                                        : 'Failed to connect to server',
                                  ),
                                  backgroundColor: Colors.red[800],
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() => dialogLoading = false);
                          }
                        } else {
                          setState(() {
                            final newId = 'REP-${_reports.length + 101}';
                            _reports.insert(0, {
                              'id': newId,
                              'deviceName': selectedDevice,
                              'summary': summaryController.text.trim(),
                              'findings': findingsController.text.trim(),
                              'actionsTaken': actionsController.text.trim(),
                              'status': 'Pending',
                              'date': DateTime.now().toString().split(' ')[0],
                            });
                          });
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('success_msg')),
                              backgroundColor: Colors.teal[800],
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: dialogLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(t('submit'), style: const TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _lang == 'ar';
    final filtered = _reports.where((r) => r['deviceName']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final approvedCount = _reports.where((r) => r['status'] == 'Approved').length;
    final pendingCount = _reports.where((r) => r['status'] == 'Pending').length;

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Colors.teal[800],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            t('title'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Column(
          children: [
            if (widget.token.isEmpty)
              Container(
                width: double.infinity,
                color: Colors.amber[900],
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lang == 'ar'
                            ? 'وضع عدم الاتصال بالخادم: يتم استخدام البيانات المحلية المؤقتة.'
                            : 'Offline Mode: Using cached local mock data.',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            // Statistics Summary Header Card
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  _buildStatCard(t('stats_total'), _reports.length.toString(), Colors.teal[800]!),
                  const SizedBox(width: 8),
                  _buildStatCard(t('stats_approved'), approvedCount.toString(), Colors.green[700]!),
                  const SizedBox(width: 8),
                  _buildStatCard(t('stats_pending'), pendingCount.toString(), Colors.orange[700]!),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: t('search'),
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.teal[800]),
                    ),
                  ),
                ),
              ),
            ),

            // Reports List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assessment_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            t('empty'),
                            style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12.0),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final report = filtered[index];
                        final isApproved = report['status'] == 'Approved';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: isApproved ? Colors.green[50] : Colors.orange[50],
                              child: Icon(
                                isApproved ? Icons.verified : Icons.hourglass_empty,
                                color: isApproved ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              report['deviceName']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                            ),
                            subtitle: Text(
                              '${report['summary']} • ${report['date']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isApproved ? Colors.green[100] : Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isApproved ? t('status_approved') : t('status_pending'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isApproved ? Colors.green[800] : Colors.orange[800],
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 4),
                                    Text(
                                      t('findings'),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal[900]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report['findings']!,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      t('actions'),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal[900]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      report['actionsTaken']!,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        'ID: ${report['id']}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateReportDialog,
          backgroundColor: Colors.teal[800],
          child: const Icon(Icons.add_chart, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
