import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TasksScreen extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;

  const TasksScreen({
    super.key,
    required this.language,
    this.token = '',
    this.backendUrl = '',
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late String _lang;
  String _searchQuery = '';

  final List<Map<String, String>> _mockTasks = [
    {
      'id': 'TSK-101',
      'title': 'Calibrate MRI RF Coils',
      'description': 'Perform routine RF coil calibration and verify homogeneity on the Optima MR450 MRI Scanner.',
      'priority': 'High',
      'status': 'Completed',
      'device': 'Optima MR450 MRI Scanner',
      'client': 'Giza International Hospital',
      'scheduledAt': '2026-07-05',
    },
    {
      'id': 'TSK-102',
      'title': 'Replace Ventilator Oxygen Cell',
      'description': 'Replace faulty O2 sensor on Engström Carestation Ventilator and calibrate readings.',
      'priority': 'High',
      'status': 'Completed',
      'device': 'Engström Carestation Ventilator',
      'client': 'Nasr City Specialized Clinic',
      'scheduledAt': '2026-07-08',
    },
    {
      'id': 'TSK-103',
      'title': 'Repair X-Ray Collimator Rotor',
      'description': 'Inspect collimator assembly on Brivo XR X-Ray Machine and clean rotor bearings to fix rotation lag.',
      'priority': 'Medium',
      'status': 'In Progress',
      'device': 'Brivo XR X-Ray Machine',
      'client': 'Giza International Hospital',
      'scheduledAt': '2026-07-09',
    },
    {
      'id': 'TSK-104',
      'title': 'ECG Firmware Update',
      'description': 'Update firmware to v2.4 on Defibtech Lifeline ECG and run baseline self-diagnostic test.',
      'priority': 'Low',
      'status': 'Pending',
      'device': 'Defibtech Lifeline ECG',
      'client': 'Nasr City Specialized Clinic',
      'scheduledAt': '2026-07-12',
    },
  ];

  List<Map<String, String>> _tasks = [];

  final List<String> _devicesList = [
    'Optima MR450 MRI Scanner',
    'Vivid E90 Ultrasound',
    'Engström Carestation Ventilator',
    'Defibtech Lifeline ECG',
    'Brivo XR X-Ray Machine',
  ];

  final List<String> _clientsList = [
    'Nasr City Specialized Clinic',
    'Giza International Hospital',
  ];

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'title': 'My Tasks',
      'search': 'Search tasks by title...',
      'new_task': 'Create Task',
      'status_pending': 'Pending',
      'status_inprogress': 'In Progress',
      'status_completed': 'Completed',
      'priority': 'Priority',
      'device': 'Device',
      'client': 'Client',
      'date': 'Scheduled Date',
      'description': 'Description',
      'submit': 'Create Task',
      'cancel': 'Cancel',
      'empty': 'No tasks found.',
      'field_empty': 'This field is required',
      'success_msg': 'Task created successfully!',
      'stats_total': 'Total Tasks',
      'stats_pending': 'Pending',
      'stats_inprogress': 'In Progress',
      'stats_completed': 'Completed',
      'start_task': 'Start Task',
      'complete_task': 'Complete Task',
      'create_report': 'Create Report',
    },
    'ar': {
      'title': 'مهام الصيانة',
      'search': 'البحث عن مهمة بالعنوان...',
      'new_task': 'إنشاء مهمة جديدة',
      'status_pending': 'قيد الانتظار',
      'status_inprogress': 'جاري العمل',
      'status_completed': 'مكتملة',
      'priority': 'الأهمية',
      'device': 'الجهاز الطبي',
      'client': 'العميل / المستشفى',
      'date': 'التاريخ المجدول',
      'description': 'التفاصيل والوصف',
      'submit': 'إنشاء المهمة',
      'cancel': 'إلغاء',
      'empty': 'لا توجد مهام صيانة حالياً.',
      'field_empty': 'هذا الحقل مطلوب',
      'success_msg': 'تم إنشاء المهمة بنجاح!',
      'stats_total': 'إجمالي المهام',
      'stats_pending': 'قيد الانتظار',
      'stats_inprogress': 'جاري العمل',
      'stats_completed': 'مكتملة',
      'start_task': 'بدء العمل',
      'complete_task': 'إكمال المهمة',
      'create_report': 'إنشاء تقرير فني',
    }
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
    _loadTasks();
  }

  String t(String key) {
    return _localized[_lang]?[key] ?? key;
  }

  Future<void> _loadTasks() async {
    if (widget.token.isEmpty) {
      setState(() {
        _tasks = List.from(_mockTasks);
      });
      return;
    }

    setState(() => _isLoading = true);

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
        final list = decoded is List ? decoded : [];

        setState(() {
          _tasks = list.map<Map<String, String>>((item) {
            final titleMap = item['title'] is Map ? item['title'] : {};
            final titleStr = _lang == 'ar' 
                ? (titleMap['ar'] ?? titleMap['en'] ?? '') 
                : (titleMap['en'] ?? titleMap['ar'] ?? '');

            final devProductMap = item['device_product_name'] is Map ? item['device_product_name'] : {};
            final deviceStr = _lang == 'ar'
                ? (devProductMap['ar'] ?? devProductMap['en'] ?? '')
                : (devProductMap['en'] ?? devProductMap['ar'] ?? '');

            final clientMap = item['client_name'] is Map ? item['client_name'] : {};
            final clientStr = _lang == 'ar'
                ? (clientMap['ar'] ?? clientMap['en'] ?? '')
                : (clientMap['en'] ?? clientMap['ar'] ?? '');

            final statusVal = item['status']?.toString() ?? 'pending';
            final uiStatus = _mapStatusToUI(statusVal);

            final priorityVal = item['priority']?.toString() ?? 'medium';
            final uiPriority = _mapPriorityToUI(priorityVal);

            final dateStr = item['scheduled_at']?.toString().split(' ')[0] ?? '';

            return {
              'id': item['id']?.toString() ?? '',
              'title': titleStr,
              'description': item['description']?.toString() ?? '',
              'priority': uiPriority,
              'status': uiStatus,
              'device': deviceStr.isNotEmpty ? deviceStr : (item['device_product_name']?.toString() ?? 'N/A'),
              'client': clientStr.isNotEmpty ? clientStr : (item['client_name']?.toString() ?? 'N/A'),
              'scheduledAt': dateStr,
            };
          }).toList();
        });
      }
    } catch (_) {
      setState(() {
        _tasks = List.from(_mockTasks);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapStatusToUI(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String _mapStatusToBackend(String uiStatus) {
    switch (uiStatus) {
      case 'Pending':
        return 'pending';
      case 'In Progress':
        return 'in_progress';
      case 'Completed':
        return 'completed';
      case 'Cancelled':
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  String _mapPriorityToUI(String priority) {
    final p = priority.toLowerCase();
    if (p == 'low') return 'Low';
    if (p == 'medium') return 'Medium';
    if (p == 'high') return 'High';
    if (p == 'emergency') return 'Emergency';
    return 'Medium';
  }

  void _showCreateTaskDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedDevice = _devicesList.first;
    String selectedClient = _clientsList.first;
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              t('new_task'),
              style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Title
                    Text(t('search').replaceAll('البحث عن مهمة بالعنوان...', 'العنوان').replaceAll('Search tasks by title...', 'Title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: titleController,
                      validator: (value) => value == null || value.trim().isEmpty ? t('field_empty') : null,
                      decoration: InputDecoration(
                        hintText: 'Inspect MRI Coils, calibrate flow, etc.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    Text(t('description'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      validator: (value) => value == null || value.trim().isEmpty ? t('field_empty') : null,
                      decoration: InputDecoration(
                        hintText: 'Task steps and specific parameters to check...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Device Dropdown
                    Text(t('device'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 16),

                    // Client Dropdown
                    Text(t('client'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClient,
                      items: _clientsList.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          selectedClient = val;
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Priority
                    Text(t('priority'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      items: ['High', 'Medium', 'Low'].map((p) {
                        return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          selectedPriority = val;
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      final newId = 'TSK-${_tasks.length + 101}';
                      _tasks.insert(0, {
                        'id': newId,
                        'title': titleController.text.trim(),
                        'description': descController.text.trim(),
                        'device': selectedDevice,
                        'client': selectedClient,
                        'priority': selectedPriority,
                        'status': 'Pending',
                        'scheduledAt': DateTime.now().toString().split(' ')[0],
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(t('submit'), style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateTaskStatus(int index, String newStatus) async {
    final task = _tasks[index];
    final taskId = task['id'];

    if (widget.token.isEmpty || taskId == null || taskId.isEmpty || int.tryParse(taskId) == null) {
      setState(() {
        _tasks[index]['status'] = newStatus;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final backendStatus = _mapStatusToBackend(newStatus);
      final response = await http.put(
        Uri.parse('${widget.backendUrl}/tasks/$taskId/status'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': backendStatus}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        await _loadTasks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _lang == 'ar'
                    ? 'تم تحديث حالة المهمة بنجاح!'
                    : 'Task status updated successfully!',
              ),
              backgroundColor: Colors.teal[800],
            ),
          );
        }
      } else {
        final decoded = jsonDecode(response.body);
        if (decoded['require_otp'] == true) {
          _showOtpDialog(taskId, index);
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(decoded['message'] ?? (_lang == 'ar' ? 'فشل تحديث حالة المهمة' : 'Failed to update task status')),
              backgroundColor: Colors.red[800],
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lang == 'ar' ? 'خطأ في الاتصال بالخادم' : 'Server connection error'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOtpDialog(String taskId, int index) async {
    final otpController = TextEditingController();
    Map<String, dynamic>? otpData;
    bool isGenerating = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (isGenerating && otpData == null) {
              http.post(
                Uri.parse('${widget.backendUrl}/tasks/$taskId/generate-otp'),
                headers: {
                  'Authorization': 'Bearer ${widget.token}',
                  'Accept': 'application/json',
                },
              ).then((res) {
                if (res.statusCode == 200) {
                  setDialogState(() {
                    otpData = jsonDecode(res.body);
                    isGenerating = false;
                  });
                } else {
                  setDialogState(() => isGenerating = false);
                }
              }).catchError((_) {
                setDialogState(() => isGenerating = false);
              });
            }

            final contactPerson = otpData?['contact_person'] ?? {};
            final contactName = contactPerson['name'] ?? (_lang == 'ar' ? 'مسؤول المستشفى' : 'Hospital Contact');
            final contactPhone = contactPerson['phone'] ?? '';
            final contactJob = contactPerson['job_title'] ?? (_lang == 'ar' ? 'مسؤول' : 'Manager');
            final otpCode = otpData?['otp_code'] ?? '';

            return Directionality(
              textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.teal[800]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lang == 'ar' ? 'توثيق إغلاق المهمة (OTP)' : 'Verify Task Completion',
                        style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                content: isGenerating
                    ? const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator(color: Colors.teal)),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _lang == 'ar'
                                  ? 'أدخل رمز التأكيد المكون من 4 أرقام المستلم من مسؤول المستشفى/العيادة لإغلاق المهمة.'
                                  : 'Enter the 4-digit OTP code received from the hospital contact person.',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.teal[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.teal.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _lang == 'ar' ? 'طالب الخدمة بالجهة:' : 'Requested Contact:',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$contactName ($contactJob) $contactPhone',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  if (otpCode.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      _lang == 'ar' ? 'كود الـ OTP الصادر للمسؤول:' : 'Generated OTP Code:',
                                      style: TextStyle(fontSize: 10, color: Colors.teal[800]),
                                    ),
                                    const SizedBox(height: 2),
                                    Center(
                                      child: Text(
                                        otpCode,
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal[900], letterSpacing: 6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
                              decoration: InputDecoration(
                                hintText: '0000',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_lang == 'ar' ? 'إلغاء' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: isGenerating
                        ? null
                        : () async {
                            final code = otpController.text.trim();
                            if (code.length != 4) return;
                            Navigator.pop(context);

                            setState(() => _isLoading = true);
                            try {
                              final res = await http.post(
                                Uri.parse('${widget.backendUrl}/tasks/$taskId/verify-otp'),
                                headers: {
                                  'Authorization': 'Bearer ${widget.token}',
                                  'Content-Type': 'application/json',
                                  'Accept': 'application/json',
                                },
                                body: jsonEncode({'otp_code': code}),
                              );
                              if (res.statusCode == 200) {
                                await _loadTasks();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _lang == 'ar'
                                            ? 'تم توثيق وإغلاق المهمة بنجاح بكود العميل!'
                                            : 'Task verified and completed successfully!',
                                      ),
                                      backgroundColor: Colors.green[800],
                                    ),
                                  );
                                }
                              } else {
                                final errDec = jsonDecode(res.body);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errDec['message'] ?? (_lang == 'ar' ? 'رمز التأكيد غير صحيح' : 'Invalid OTP')),
                                      backgroundColor: Colors.red[800],
                                    ),
                                  );
                                }
                              }
                            } catch (_) {
                              // Catch errors
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[800]),
                    child: Text(_lang == 'ar' ? 'توثيق وإكمال' : 'Verify & Complete', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _lang == 'ar';
    final filtered = _tasks.where((t) => t['title']!.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    final pendingCount = _reportsCount('Pending');
    final progressCount = _reportsCount('In Progress');
    final completedCount = _reportsCount('Completed');

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
            // Statistics Summary Card
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  _buildStatCard(t('stats_total'), _tasks.length.toString(), Colors.teal[800]!),
                  const SizedBox(width: 8),
                  _buildStatCard(t('stats_pending'), pendingCount.toString(), Colors.red[700]!),
                  const SizedBox(width: 8),
                  _buildStatCard(t('stats_inprogress'), progressCount.toString(), Colors.orange[700]!),
                  const SizedBox(width: 8),
                  _buildStatCard(t('stats_completed'), completedCount.toString(), Colors.green[700]!),
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

            // Tasks List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
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
                        final task = filtered[index];
                        final priority = task['priority']!;
                        final status = task['status']!;

                        Color priorityColor = Colors.blue;
                        if (priority == 'High') priorityColor = Colors.red;
                        if (priority == 'Medium') priorityColor = Colors.orange;

                        Color statusColor = Colors.red;
                        String localizedStatus = t('status_pending');
                        if (status == 'In Progress') {
                          statusColor = Colors.orange;
                          localizedStatus = t('status_inprogress');
                        } else if (status == 'Completed') {
                          statusColor = Colors.green;
                          localizedStatus = t('status_completed');
                        }

                        // find index in actual array to support state updates
                        final actualIndex = _tasks.indexOf(task);

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withValues(alpha: 0.1),
                              child: Icon(
                                status == 'Completed' ? Icons.check_circle : (status == 'In Progress' ? Icons.play_circle : Icons.stop_circle_outlined),
                                color: statusColor,
                              ),
                            ),
                            title: Text(
                              task['title']!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
                            ),
                            subtitle: Text(
                              '${task['device']} • ${task['scheduledAt']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                localizedStatus,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
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
                                      t('description'),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.teal[900]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      task['description']!,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildDetailRow(t('client'), task['client']!),
                                    _buildDetailRow(t('priority'), priority, valueColor: priorityColor),
                                    _buildDetailRow(t('date'), task['scheduledAt']!),
                                    const SizedBox(height: 16),

                                    // Action buttons depending on status
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (status == 'Pending')
                                          ElevatedButton.icon(
                                            onPressed: () => _updateTaskStatus(actualIndex, 'In Progress'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange[800],
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                            label: Text(t('start_task'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                          )
                                        else if (status == 'In Progress')
                                          ElevatedButton.icon(
                                            onPressed: () => _updateTaskStatus(actualIndex, 'Completed'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green[800],
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.check, color: Colors.white, size: 16),
                                            label: Text(t('complete_task'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                          )
                                        else if (status == 'Completed')
                                          ElevatedButton.icon(
                                             onPressed: () {
                                               Navigator.pushNamed(
                                                 context,
                                                 '/reports',
                                                 arguments: {
                                                   'token': widget.token,
                                                   'backendUrl': widget.backendUrl,
                                                 },
                                               );
                                             },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.teal[800],
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            icon: const Icon(Icons.note_add_outlined, color: Colors.white, size: 16),
                                            label: Text(t('create_report'), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                          ),
                                      ],
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
          onPressed: _showCreateTaskDialog,
          backgroundColor: Colors.teal[800],
          child: const Icon(Icons.playlist_add, color: Colors.white),
        ),
      ),
    );
  }

  int _reportsCount(String status) {
    return _tasks.where((t) => t['status'] == status).length;
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: valueColor ?? const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
