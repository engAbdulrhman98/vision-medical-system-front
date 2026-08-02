import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vision_medical_system_app/services/db_helper.dart';

/// A reusable Tasks Tab embedded in any role dashboard.
///
/// [canCreate]  – true for admin/manager: shows FAB to create tasks
/// [canUpdate]  – true for engineer: shows Start/Complete buttons
/// [accentColor] – theme color matching the parent dashboard
class SharedTasksTab extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;
  final String userRole; // 'admin','manager','engineer','accountant','seller','collector'
  final Color accentColor;

  const SharedTasksTab({
    super.key,
    required this.language,
    required this.token,
    required this.backendUrl,
    required this.userRole,
    this.accentColor = const Color(0xFF0D9488),
  });

  @override
  State<SharedTasksTab> createState() => _SharedTasksTabState();
}

class _SharedTasksTabState extends State<SharedTasksTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _tasks = [];
  String _searchQuery = '';
  String _filterStatus = 'all';
  final _searchCtrl = TextEditingController();

  bool get _canCreate =>
      widget.userRole == 'admin' || widget.userRole == 'manager';
  bool get _canUpdate =>
      widget.userRole == 'engineer' ||
      widget.userRole == 'admin' ||
      widget.userRole == 'manager';

  final Map<String, Map<String, String>> _loc = {
    'en': {
      'title': 'Tasks',
      'search': 'Search tasks...',
      'all': 'All',
      'pending': 'Pending',
      'inprogress': 'In Progress',
      'completed': 'Completed',
      'empty': 'No tasks found',
      'new_task': 'New Task',
      'task_title': 'Task Title',
      'description': 'Description',
      'priority': 'Priority',
      'device': 'Device',
      'client': 'Client',
      'date': 'Scheduled Date',
      'submit': 'Create Task',
      'cancel': 'Cancel',
      'field_empty': 'Required field',
      'success_create': 'Task created successfully!',
      'success_update': 'Task status updated!',
      'start_task': 'Start',
      'complete_task': 'Complete',
      'create_report': 'Report',
      'total': 'Total',
      'assigned_to': 'Assigned',
      'loading': 'Loading tasks...',
      'refresh': 'Refresh',
    },
    'ar': {
      'title': 'المهام',
      'search': 'ابحث عن مهمة...',
      'all': 'الكل',
      'pending': 'معلقة',
      'inprogress': 'جاري',
      'completed': 'مكتملة',
      'empty': 'لا توجد مهام',
      'new_task': 'مهمة جديدة',
      'task_title': 'عنوان المهمة',
      'description': 'الوصف والتفاصيل',
      'priority': 'الأولوية',
      'device': 'الجهاز الطبي',
      'client': 'العميل / المستشفى',
      'date': 'التاريخ المجدول',
      'submit': 'إنشاء المهمة',
      'cancel': 'إلغاء',
      'field_empty': 'حقل مطلوب',
      'success_create': 'تم إنشاء المهمة بنجاح!',
      'success_update': 'تم تحديث حالة المهمة!',
      'start_task': 'بدء',
      'complete_task': 'إكمال',
      'create_report': 'تقرير',
      'total': 'الإجمالي',
      'assigned_to': 'المكلّف',
      'loading': 'جاري التحميل...',
      'refresh': 'تحديث',
    },
  };

  String t(String key) => _loc[widget.language]?[key] ?? key;
  bool get isAr => widget.language == 'ar';

  final List<String> _devicesList = [
    'Optima MR450 MRI Scanner',
    'Vivid E90 Ultrasound',
    'Engström Carestation Ventilator',
    'Defibtech Lifeline ECG',
    'Brivo XR X-Ray Machine',
    'Siemens SOMATOM CT Scanner',
  ];

  final List<String> _clientsList = [
    'Giza International Hospital',
    'Nasr City Specialized Clinic',
    'Cleopatra Medical Group',
    'Ibn Sina Medical Center',
    'Al-Salam International Hospital',
  ];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (widget.token.isEmpty) {
      _setMock();
      return;
    }
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('${widget.backendUrl}/tasks'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('shared_tasks_${widget.userRole}', res.body);
        final decoded = jsonDecode(res.body);
        final list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
        if (mounted) {
          setState(() => _tasks = list.map<Map<String, dynamic>>((item) => _parseTask(item)).toList());
        }
      }
    } catch (_) {
      final cached = await ChatDatabaseHelper.instance.getFromCache('shared_tasks_${widget.userRole}');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        final list = decoded is List ? decoded : (decoded['data'] as List? ?? []);
        if (mounted) {
          setState(() => _tasks = list.map<Map<String, dynamic>>((item) => _parseTask(item)).toList());
        }
      } else {
        _setMock();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _parseTask(dynamic item) {
    final lang = widget.language;
    String _loc(dynamic obj) {
      if (obj is Map) return obj[lang] ?? obj['ar'] ?? obj['en'] ?? '';
      return obj?.toString() ?? '';
    }

    final status = item['status']?.toString() ?? 'pending';
    String uiStatus;
    switch (status.toLowerCase()) {
      case 'in_progress': uiStatus = 'In Progress'; break;
      case 'completed': uiStatus = 'Completed'; break;
      case 'cancelled': uiStatus = 'Cancelled'; break;
      default: uiStatus = 'Pending';
    }

    final priority = item['priority']?.toString() ?? 'medium';
    String uiPriority;
    switch (priority.toLowerCase()) {
      case 'high': uiPriority = 'High'; break;
      case 'low': uiPriority = 'Low'; break;
      case 'emergency': uiPriority = 'Emergency'; break;
      default: uiPriority = 'Medium';
    }

    return {
      'id': item['id']?.toString() ?? '',
      'title': _loc(item['title']).isNotEmpty ? _loc(item['title']) : (item['title']?.toString() ?? ''),
      'description': item['description']?.toString() ?? '',
      'status': uiStatus,
      'priority': uiPriority,
      'device': _loc(item['device_product_name']).isNotEmpty ? _loc(item['device_product_name']) : (item['device_product_name']?.toString() ?? ''),
      'client': _loc(item['client_name']).isNotEmpty ? _loc(item['client_name']) : (item['client_name']?.toString() ?? ''),
      'scheduledAt': item['scheduled_at']?.toString().split(' ')[0] ?? '',
      'assignedTo': item['assigned_to']?.toString() ?? '',
    };
  }

  void _setMock() {
    setState(() {
      _tasks = [
        {
          'id': '101',
          'title': isAr ? 'معايرة ملفات الرنين المغناطيسي' : 'Calibrate MRI RF Coils',
          'description': isAr ? 'إجراء معايرة روتينية لملفات RF والتحقق من التجانس على ماسح Optima MR450 MRI.' : 'Perform routine RF coil calibration on Optima MR450 MRI Scanner.',
          'priority': 'High',
          'status': 'Completed',
          'device': 'Optima MR450 MRI Scanner',
          'client': isAr ? 'مستشفى الجيزة الدولي' : 'Giza International Hospital',
          'scheduledAt': '2026-07-05',
          'assignedTo': isAr ? 'م. أسامة مصطفى' : 'Osama Mostafa',
        },
        {
          'id': '102',
          'title': isAr ? 'استبدال خلية أوكسجين جهاز التنفس' : 'Replace Ventilator O2 Cell',
          'description': isAr ? 'استبدال مستشعر O2 المعطوب ومعايرة القراءات.' : 'Replace faulty O2 sensor on Engström Carestation Ventilator.',
          'priority': 'High',
          'status': 'In Progress',
          'device': 'Engström Carestation Ventilator',
          'client': isAr ? 'عيادة نصر سيتي المتخصصة' : 'Nasr City Specialized Clinic',
          'scheduledAt': '2026-07-08',
          'assignedTo': isAr ? 'م. أسامة مصطفى' : 'Osama Mostafa',
        },
        {
          'id': '103',
          'title': isAr ? 'إصلاح روتور مضيق الأشعة السينية' : 'Repair X-Ray Collimator Rotor',
          'description': isAr ? 'فحص تجميعة المضيق وتنظيف محامل الروتور.' : 'Inspect collimator assembly on Brivo XR X-Ray Machine.',
          'priority': 'Medium',
          'status': 'Pending',
          'device': 'Brivo XR X-Ray Machine',
          'client': isAr ? 'مستشفى الجيزة الدولي' : 'Giza International Hospital',
          'scheduledAt': '2026-07-09',
          'assignedTo': isAr ? 'م. خالد عمر' : 'Khaled Omar',
        },
        {
          'id': '104',
          'title': isAr ? 'تحديث برنامج جهاز القلب ECG' : 'ECG Firmware Update',
          'description': isAr ? 'تحديث البرنامج الثابت إلى v2.4 وإجراء اختبار تشخيص ذاتي.' : 'Update firmware to v2.4 on Defibtech Lifeline ECG.',
          'priority': 'Low',
          'status': 'Pending',
          'device': 'Defibtech Lifeline ECG',
          'client': isAr ? 'مجموعة كليوباترا الطبية' : 'Cleopatra Medical Group',
          'scheduledAt': '2026-07-12',
          'assignedTo': isAr ? 'م. رامي حسن' : 'Ramy Hassan',
        },
      ];
    });
  }

  Future<void> _updateTaskStatus(int index, String newStatus) async {
    final task = _tasks[index];
    final taskId = task['id']?.toString() ?? '';

    setState(() => _tasks[index] = {..._tasks[index], 'status': newStatus});

    if (widget.token.isEmpty || int.tryParse(taskId) == null) return;

    String backendStatus;
    switch (newStatus) {
      case 'In Progress': backendStatus = 'in_progress'; break;
      case 'Completed': backendStatus = 'completed'; break;
      default: backendStatus = 'pending';
    }

    try {
      await http.put(
        Uri.parse('${widget.backendUrl}/tasks/$taskId/status'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'status': backendStatus}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('success_update')),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ─── Create Task Dialog ───────────────────────────────────────────────────
  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selDevice = _devicesList.first;
    String selClient = _clientsList.first;
    String selPriority = 'Medium';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return Directionality(
            textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.playlist_add, color: widget.accentColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(t('new_task'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: widget.accentColor)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel(t('task_title')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: titleCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? t('field_empty') : null,
                        decoration: _inputDec(isAr ? 'مثال: معايرة جهاز الرنين...' : 'e.g., Calibrate MRI coils...'),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel(t('description')),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? t('field_empty') : null,
                        decoration: _inputDec(isAr ? 'الخطوات والمعايير المطلوبة...' : 'Steps and parameters...'),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel(t('device')),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selDevice,
                        items: _devicesList.map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) { if (v != null) setS(() => selDevice = v); },
                        decoration: _inputDec(''),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel(t('client')),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selClient,
                        items: _clientsList.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) { if (v != null) setS(() => selClient = v); },
                        decoration: _inputDec(''),
                      ),
                      const SizedBox(height: 14),
                      _fieldLabel(t('priority')),
                      const SizedBox(height: 6),
                      Row(
                        children: ['Low', 'Medium', 'High'].map((p) {
                          final selected = selPriority == p;
                          Color pColor = p == 'High' ? Colors.red : (p == 'Medium' ? Colors.orange : Colors.green);
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setS(() => selPriority = p),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? pColor.withValues(alpha: 0.15) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: selected ? pColor : Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: Text(
                                    isAr ? (p == 'High' ? 'عالية' : p == 'Medium' ? 'متوسطة' : 'منخفضة') : p,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected ? pColor : Colors.grey[600],
                                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t('cancel'), style: TextStyle(color: Colors.grey[600])),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      await _submitCreateTask(titleCtrl.text.trim(), descCtrl.text.trim(), selDevice, selClient, selPriority);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(t('submit'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _submitCreateTask(String title, String desc, String device, String client, String priority) async {
    // Optimistic insert
    final newId = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _tasks.insert(0, {
        'id': newId,
        'title': title,
        'description': desc,
        'status': 'Pending',
        'priority': priority,
        'device': device,
        'client': client,
        'scheduledAt': DateTime.now().toString().split(' ')[0],
        'assignedTo': '',
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t('success_create')),
        backgroundColor: widget.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
    }

    if (widget.token.isEmpty) return;

    try {
      await http.post(
        Uri.parse('${widget.backendUrl}/tasks'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'title': {'ar': title, 'en': title},
          'description': desc,
          'priority': priority.toLowerCase(),
          'device_product_name': device,
          'client_name': client,
          'scheduled_at': DateTime.now().toString().split(' ')[0],
          'status': 'pending',
        }),
      ).timeout(const Duration(seconds: 5));
      // Reload to sync real IDs
      await _loadTasks();
    } catch (_) {}
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: widget.accentColor, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _fieldLabel(String label) => Text(label,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.blueGrey[700]));

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return const Color(0xFF16A34A);
      case 'in progress': return const Color(0xFFF59E0B);
      case 'cancelled': return Colors.grey;
      default: return const Color(0xFFDC2626);
    }
  }

  IconData _statusIcon(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return Icons.check_circle_outline;
      case 'in progress': return Icons.play_circle_outline;
      default: return Icons.radio_button_unchecked;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return t('completed');
      case 'in progress': return t('inprogress');
      default: return t('pending');
    }
  }

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high': case 'emergency': return const Color(0xFFDC2626);
      case 'medium': return const Color(0xFFF59E0B);
      default: return const Color(0xFF16A34A);
    }
  }

  String _priorityLabel(String p) {
    if (!isAr) return p;
    switch (p.toLowerCase()) {
      case 'high': return 'عالية';
      case 'medium': return 'متوسطة';
      case 'low': return 'منخفضة';
      case 'emergency': return 'طارئة';
      default: return p;
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _tasks.where((task) {
      final title = (task['title'] ?? '').toString().toLowerCase();
      final client = (task['client'] ?? '').toString().toLowerCase();
      final matchSearch = _searchQuery.isEmpty || title.contains(_searchQuery) || client.contains(_searchQuery);
      final status = (task['status'] ?? '').toString().toLowerCase();
      final matchFilter = _filterStatus == 'all' ||
          (_filterStatus == 'pending' && status == 'pending') ||
          (_filterStatus == 'inprogress' && status == 'in progress') ||
          (_filterStatus == 'completed' && status == 'completed');
      return matchSearch && matchFilter;
    }).toList();
  }

  int _count(String s) => _tasks.where((t) => (t['status'] ?? '').toString().toLowerCase() == s.toLowerCase()).length;

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Stats row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                _statPill(t('total'), _tasks.length, widget.accentColor),
                const SizedBox(width: 8),
                _statPill(t('pending'), _count('pending'), const Color(0xFFDC2626)),
                const SizedBox(width: 8),
                _statPill(t('inprogress'), _count('in progress'), const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _statPill(t('completed'), _count('completed'), const Color(0xFF16A34A)),
              ],
            ),
          ),
          // Search & filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: t('search'),
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 20, color: widget.accentColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('all', t('all')),
                      const SizedBox(width: 8),
                      _filterChip('pending', t('pending')),
                      const SizedBox(width: 8),
                      _filterChip('inprogress', t('inprogress')),
                      const SizedBox(width: 8),
                      _filterChip('completed', t('completed')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // Tasks list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: widget.accentColor))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(t('empty'), style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: widget.accentColor,
                        onRefresh: _loadTasks,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final task = _filtered[i];
                            final actualIdx = _tasks.indexWhere((t) => t['id'] == task['id']);
                            return _buildTaskCard(task, actualIdx);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: _showCreateDialog,
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.playlist_add),
              label: Text(t('new_task'), style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _statPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? widget.accentColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? widget.accentColor : Colors.grey[300]!),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int actualIdx) {
    final status = task['status']?.toString() ?? 'Pending';
    final priority = task['priority']?.toString() ?? 'Medium';
    final sColor = _statusColor(status);
    final pColor = _priorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(status), color: sColor, size: 22),
          ),
          title: Text(
            task['title']?.toString() ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_priorityLabel(priority),
                      style: TextStyle(fontSize: 10, color: pColor, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${task['device'] ?? ''} • ${task['scheduledAt'] ?? ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: sColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _statusLabel(status),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sColor),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if ((task['description'] ?? '').toString().isNotEmpty) ...[
                    Text(isAr ? 'التفاصيل:' : 'Details:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: widget.accentColor)),
                    const SizedBox(height: 4),
                    Text(task['description'].toString(),
                        style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 10),
                  ],
                  _detailRow(Icons.business_outlined, t('client'), task['client']?.toString() ?? ''),
                  _detailRow(Icons.calendar_today_outlined, isAr ? 'التاريخ' : 'Date', task['scheduledAt']?.toString() ?? ''),
                  if ((task['assignedTo'] ?? '').toString().isNotEmpty)
                    _detailRow(Icons.person_outline, t('assigned_to'), task['assignedTo'].toString()),
                  // Action buttons — role-based
                  if (_canUpdate && status != 'Cancelled') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status == 'Pending')
                          _actionBtn(
                            label: t('start_task'),
                            icon: Icons.play_arrow,
                            color: const Color(0xFFF59E0B),
                            onTap: () => _updateTaskStatus(actualIdx, 'In Progress'),
                          ),
                        if (status == 'In Progress')
                          _actionBtn(
                            label: t('complete_task'),
                            icon: Icons.check,
                            color: const Color(0xFF16A34A),
                            onTap: () => _updateTaskStatus(actualIdx, 'Completed'),
                          ),
                        if (status == 'Completed') ...[
                          _actionBtn(
                            label: t('create_report'),
                            icon: Icons.note_add_outlined,
                            color: widget.accentColor,
                            onTap: () {
                              Navigator.pushNamed(context, '/reports', arguments: {
                                'token': widget.token,
                                'backendUrl': widget.backendUrl,
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
