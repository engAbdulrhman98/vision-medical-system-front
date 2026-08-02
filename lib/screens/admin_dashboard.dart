import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vision_medical_system_app/services/db_helper.dart';
import 'shared_tasks_tab.dart';

class AdminDashboard extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;
  final Map user;

  const AdminDashboard({
    super.key,
    required this.language,
    required this.token,
    required this.backendUrl,
    required this.user,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  Map<String, dynamic> _stats = {
    'total_visits': 1245,
    'today_visits': 84,
    'products': 18,
    'categories': 6,
    'brands': 4,
    'pending_reviews': 3,
    'unread_messages': 2
  };
  List<dynamic> _reviews = [];
  List<dynamic> _messages = [];
  List<dynamic> _users = [];
  final List<String> _roles = ['Admin', 'Manager', 'Accountant', 'Seller'];
  
  // Settings form state
  final _settingsFormKey = GlobalKey<FormState>();
  final TextEditingController _storeNameAr = TextEditingController(text: 'نظام فيجن ميدكال');
  final TextEditingController _storeNameEn = TextEditingController(text: 'Vision Medical');
  final TextEditingController _storeEmail = TextEditingController(text: 'info@vision-medical.com');
  final TextEditingController _storePhone = TextEditingController(text: '+20 100 123 4567');
  final TextEditingController _storeWhatsapp = TextEditingController(text: '201001234567');
  final TextEditingController _maintenancePhone = TextEditingController(text: '+20 111 765 4321');
  final TextEditingController _maintenanceWhatsapp = TextEditingController(text: '201117654321');
  final TextEditingController _aboutUsTitleAr = TextEditingController(text: 'من نحن');
  final TextEditingController _aboutUsTitleEn = TextEditingController(text: 'About Us');
  final TextEditingController _aboutUsContentAr = TextEditingController(text: 'نحن شركة رائدة في الأجهزة الطبية...');
  final TextEditingController _aboutUsContentEn = TextEditingController(text: 'We are a leading medical devices company...');
  final TextEditingController _footerTextAr = TextEditingController(text: 'حقوق النشر محفوظة © نظام فيجن ميدكال');
  final TextEditingController _footerTextEn = TextEditingController(text: 'All rights reserved © Vision Medical');
  final TextEditingController _companyMapLink = TextEditingController(text: 'https://maps.google.com/?q=30.0444,31.2357');

  final Map<String, dynamic> _workingHours = {
    'saturday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'sunday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'monday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'tuesday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'wednesday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'thursday': {'open': true, 'from': '08:00', 'to': '17:00'},
    'friday': {'open': false, 'from': '08:00', 'to': '17:00'},
  };
  
  // Role assignment state
  final _roleFormKey = GlobalKey<FormState>();
  final TextEditingController _assignEmail = TextEditingController();
  String _selectedAssignRole = 'Admin';

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'overview': 'Overview',
      'reviews': 'Reviews',
      'messages': 'Messages',
      'permissions': 'Permissions',
      'settings': 'Settings',
      'stats_visits': 'Total Visits',
      'stats_today': 'Today Visits',
      'stats_products': 'Products',
      'stats_categories': 'Categories',
      'stats_pending_reviews': 'Pending Reviews',
      'stats_unread_messages': 'Unread Messages',
      'assign_role': 'Assign Role to User',
      'email_label': 'Employee Email Address',
      'select_role': 'Select Job Role',
      'submit': 'Save & Apply',
      'refresh': 'Refresh Data',
      'status_approved': 'Approved',
      'status_pending': 'Pending',
      'approve': 'Approve',
      'delete': 'Delete',
      'success_assign': 'Role assigned successfully!',
      'success_settings': 'Settings updated successfully!',
      'sender': 'Sender',
      'subject': 'Subject',
      'content': 'Content',
      'working_hours': 'Working Hours',
    },
    'ar': {
      'overview': 'الإحصائيات',
      'reviews': 'المراجعات',
      'messages': 'الرسائل',
      'permissions': 'الصلاحيات',
      'settings': 'الإعدادات',
      'stats_visits': 'إجمالي الزيارات',
      'stats_today': 'زيارات اليوم',
      'stats_products': 'المنتجات الطبية',
      'stats_categories': 'الأقسام الرئيسية',
      'stats_pending_reviews': 'مراجعات معلقة',
      'stats_unread_messages': 'رسائل غير مقروءة',
      'assign_role': 'تعيين دور لموظف',
      'email_label': 'البريد الإلكتروني للموظف',
      'select_role': 'اختر المسمى الوظيفي',
      'submit': 'حفظ وتطبيق',
      'refresh': 'تحديث البيانات',
      'status_approved': 'مقبول',
      'status_pending': 'قيد الانتظار',
      'approve': 'موافقة',
      'delete': 'حذف',
      'success_assign': 'تم تعيين الدور للموظف بنجاح!',
      'success_settings': 'تم تحديث الإعدادات بنجاح!',
      'sender': 'المرسل',
      'subject': 'الموضوع',
      'content': 'محتوى الرسالة',
      'working_hours': 'أوقات العمل المعتمدة',
    }
  };

  String t(String key) {
    return _localized[widget.language]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storeNameAr.dispose();
    _storeNameEn.dispose();
    _storeEmail.dispose();
    _storePhone.dispose();
    _storeWhatsapp.dispose();
    _maintenancePhone.dispose();
    _maintenanceWhatsapp.dispose();
    _aboutUsTitleAr.dispose();
    _aboutUsTitleEn.dispose();
    _aboutUsContentAr.dispose();
    _aboutUsContentEn.dispose();
    _footerTextAr.dispose();
    _footerTextEn.dispose();
    _companyMapLink.dispose();
    _assignEmail.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (widget.token.isEmpty) {
      _loadMockData();
      return;
    }
    setState(() => _isLoading = true);
    bool showedOfflineToast = false;

    void showOfflineToast() {
      if (!showedOfflineToast && mounted) {
        showedOfflineToast = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.language == 'ar'
                  ? 'وضع عدم الاتصال: يتم عرض البيانات المخزنة مؤقتاً'
                  : 'Offline mode: displaying cached data',
            ),
            backgroundColor: Colors.amber[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Accept': 'application/json',
    };
    
    // 1. Get stats
    try {
      final statsRes = await http.get(Uri.parse('${widget.backendUrl}/dashboard/stats'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (statsRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('admin_stats', statsRes.body);
        _stats = jsonDecode(statsRes.body);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('admin_stats');
      if (cached != null) {
        _stats = jsonDecode(cached);
      }
    }

    // 2. Get reviews
    try {
      final reviewsRes = await http.get(Uri.parse('${widget.backendUrl}/reviews'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (reviewsRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('admin_reviews', reviewsRes.body);
        final data = jsonDecode(reviewsRes.body);
        _reviews = data is List ? data : (data['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('admin_reviews');
      if (cached != null) {
        final data = jsonDecode(cached);
        _reviews = data is List ? data : (data['data'] as List? ?? []);
      } else {
        _reviews = [
          {'id': 1, 'reviewer_name': 'Dr. Ahmad Ali', 'rating': 5, 'comment': 'Excellent quality MRI machine, very reliable.', 'is_approved': false, 'product_name': {'ar': 'جهاز رنين مغناطيسي Optima', 'en': 'Optima MRI Scanner'}},
          {'id': 2, 'reviewer_name': 'Eng. Omar Fayed', 'rating': 4, 'comment': 'Good ultrasound scanner. High frame rates.', 'is_approved': false, 'product_name': {'ar': 'جهاز سونار ثلاثي الأبعاد', 'en': 'Vivid E90 Ultrasound'}},
          {'id': 3, 'reviewer_name': 'Prof. Laila Kamel', 'rating': 2, 'comment': 'O2 sensor needs calibration frequently.', 'is_approved': false, 'product_name': {'ar': 'جهاز تنفس صناعي ICU', 'en': 'Engström Ventilator'}}
        ];
      }
    }

    // 3. Get messages
    try {
      final msgRes = await http.get(Uri.parse('${widget.backendUrl}/messages'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (msgRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('admin_messages', msgRes.body);
        final data = jsonDecode(msgRes.body);
        _messages = data is List ? data : (data['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('admin_messages');
      if (cached != null) {
        final data = jsonDecode(cached);
        _messages = data is List ? data : (data['data'] as List? ?? []);
      } else {
        _messages = [
          {'id': 1, 'name': 'Al-Shifa Hospital', 'email': 'purchasing@shifa.com', 'subject': 'Quotation Request', 'message': 'We need a formal quotation for 3 MRI machines and 5 Ultrasounds including installation.', 'created_at': '2026-07-14T10:30:00Z', 'is_read': false},
          {'id': 2, 'name': 'Dr. Hany Gamil', 'email': 'hany@gmail.com', 'subject': 'ECG Maintenance', 'message': 'Our ECG machine is showing error code 203. Need urgent engineer visit.', 'created_at': '2026-07-13T16:15:00Z', 'is_read': true}
        ];
      }
    }

    // 4. Get users
    try {
      final usersRes = await http.get(Uri.parse('${widget.backendUrl}/users'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (usersRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('admin_users', usersRes.body);
        final data = jsonDecode(usersRes.body);
        _users = data is List ? data : (data['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('admin_users');
      if (cached != null) {
        final data = jsonDecode(cached);
        _users = data is List ? data : (data['data'] as List? ?? []);
      } else {
        _users = [
          {'id': 1, 'name': 'Super Admin', 'email': 'admin@vision.com', 'role': 'Admin'},
        ];
      }
    }

    // 5. Get settings
    try {
      final settingsRes = await http.get(Uri.parse('${widget.backendUrl}/settings'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (settingsRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('admin_settings', settingsRes.body);
        _applySettings(jsonDecode(settingsRes.body));
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('admin_settings');
      if (cached != null) {
        _applySettings(jsonDecode(cached));
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _applySettings(dynamic res) {
    if (!mounted) return;
    if (res == null) return;
    _storeNameAr.text = res['store_name']?['ar'] ?? _storeNameAr.text;
    _storeNameEn.text = res['store_name']?['en'] ?? _storeNameEn.text;
    _storeEmail.text = res['store_email'] ?? _storeEmail.text;
    _storePhone.text = res['store_phone'] ?? _storePhone.text;
    _storeWhatsapp.text = res['whatsapp'] ?? _storeWhatsapp.text;
    _maintenancePhone.text = res['maintenance_phone'] ?? _maintenancePhone.text;
    _maintenanceWhatsapp.text = res['maintenance_whatsapp'] ?? _maintenanceWhatsapp.text;
    _aboutUsTitleAr.text = res['about_us_title']?['ar'] ?? _aboutUsTitleAr.text;
    _aboutUsTitleEn.text = res['about_us_title']?['en'] ?? _aboutUsTitleEn.text;
    _aboutUsContentAr.text = res['about_us_content']?['ar'] ?? _aboutUsContentAr.text;
    _aboutUsContentEn.text = res['about_us_content']?['en'] ?? _aboutUsContentEn.text;
    _footerTextAr.text = res['footer_text']?['ar'] ?? _footerTextAr.text;
    _footerTextEn.text = res['footer_text']?['en'] ?? _footerTextEn.text;
    _companyMapLink.text = res['company_map_link'] ?? _companyMapLink.text;

    if (res['working_hours_days'] is Map) {
      final days = res['working_hours_days'] as Map;
      days.forEach((key, val) {
        if (_workingHours.containsKey(key) && val is Map) {
          _workingHours[key] = {
            'open': val['open'] == '1' || val['open'] == true || val['open'] == 1,
            'from': val['from'] ?? '08:00',
            'to': val['to'] ?? '17:00',
          };
        }
      });
    }
  }

  void _loadMockData() {
    _reviews = [
      {'id': 1, 'reviewer_name': 'Dr. Ahmad Ali', 'rating': 5, 'comment': 'Excellent quality MRI machine, very reliable.', 'is_approved': false, 'product_name': {'ar': 'جهاز رنين مغناطيسي Optima', 'en': 'Optima MRI Scanner'}},
      {'id': 2, 'reviewer_name': 'Eng. Omar Fayed', 'rating': 4, 'comment': 'Good ultrasound scanner. High frame rates.', 'is_approved': false, 'product_name': {'ar': 'جهاز سونار ثلاثي الأبعاد', 'en': 'Vivid E90 Ultrasound'}},
      {'id': 3, 'reviewer_name': 'Prof. Laila Kamel', 'rating': 2, 'comment': 'O2 sensor needs calibration frequently.', 'is_approved': false, 'product_name': {'ar': 'جهاز تنفس صناعي ICU', 'en': 'Engström Ventilator'}}
    ];

    _messages = [
      {'id': 1, 'name': 'Al-Shifa Hospital', 'email': 'purchasing@shifa.com', 'subject': 'Quotation Request', 'message': 'We need a formal quotation for 3 MRI machines and 5 Ultrasounds including installation.', 'created_at': '2026-07-14T10:30:00Z', 'is_read': false},
      {'id': 2, 'name': 'Dr. Hany Gamil', 'email': 'hany@gmail.com', 'subject': 'ECG Maintenance', 'message': 'Our ECG machine is showing error code 203. Need urgent engineer visit.', 'created_at': '2026-07-13T16:15:00Z', 'is_read': true}
    ];

    _users = [
      {'id': 1, 'name': 'Super Admin', 'email': 'admin@vision.com', 'role': 'Admin'},
      {'id': 2, 'name': 'Ahmed Manager', 'email': 'manager@vision.com', 'role': 'Manager'},
      {'id': 3, 'name': 'Sara Accountant', 'email': 'accountant@vision.com', 'role': 'Accountant'},
      {'id': 4, 'name': 'Hassan Seller', 'email': 'sales@vision.com', 'role': 'Seller'}
    ];
  }

  Future<void> _approveReview(int reviewId) async {
    if (widget.token.isEmpty) {
      setState(() {
        _reviews.removeWhere((r) => r['id'] == reviewId);
        _stats['pending_reviews'] = (_stats['pending_reviews'] as int) - 1;
      });
      return;
    }
    try {
      final res = await http.post(
        Uri.parse('${widget.backendUrl}/reviews/$reviewId/approve'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        }
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        _loadDashboardData();
      }
    } catch (_) {}
  }

  Future<void> _deleteReview(int reviewId) async {
    if (widget.token.isEmpty) {
      setState(() {
        _reviews.removeWhere((r) => r['id'] == reviewId);
        _stats['pending_reviews'] = (_stats['pending_reviews'] as int) - 1;
      });
      return;
    }
    try {
      final res = await http.delete(
        Uri.parse('${widget.backendUrl}/reviews/$reviewId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        }
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        _loadDashboardData();
      }
    } catch (_) {}
  }

  Future<void> _deleteMessage(int msgId) async {
    if (widget.token.isEmpty) {
      setState(() {
        _messages.removeWhere((m) => m['id'] == msgId);
        _stats['unread_messages'] = (_stats['unread_messages'] as int) - 1;
      });
      return;
    }
    try {
      final res = await http.delete(
        Uri.parse('${widget.backendUrl}/messages/$msgId'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        }
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        _loadDashboardData();
      }
    } catch (_) {}
  }

  Future<void> _assignUserRole() async {
    if (_roleFormKey.currentState!.validate()) {
      final email = _assignEmail.text.trim();
      if (widget.token.isEmpty) {
        setState(() {
          _users.add({
            'id': _users.length + 1,
            'name': email.split('@')[0],
            'email': email,
            'role': _selectedAssignRole
          });
          _assignEmail.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('success_assign')), backgroundColor: Colors.green[800])
          );
        }
        return;
      }
      try {
        final res = await http.post(
          Uri.parse('${widget.backendUrl}/roles/assign'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'role': _selectedAssignRole,
          })
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          _assignEmail.clear();
          _loadDashboardData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('success_assign')), backgroundColor: Colors.green[800])
            );
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _saveSettings() async {
    if (_settingsFormKey.currentState!.validate()) {
      final payload = {
        'store_name': {
          'ar': _storeNameAr.text,
          'en': _storeNameEn.text,
        },
        'store_email': _storeEmail.text,
        'store_phone': _storePhone.text,
        'whatsapp': _storeWhatsapp.text,
        'maintenance_phone': _maintenancePhone.text,
        'maintenance_whatsapp': _maintenanceWhatsapp.text,
        'about_us_title': {
          'ar': _aboutUsTitleAr.text,
          'en': _aboutUsTitleEn.text,
        },
        'about_us_content': {
          'ar': _aboutUsContentAr.text,
          'en': _aboutUsContentEn.text,
        },
        'footer_text': {
          'ar': _footerTextAr.text,
          'en': _footerTextEn.text,
        },
        'company_map_link': _companyMapLink.text,
        'working_hours_days': _workingHours,
      };

      if (widget.token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('success_settings')), backgroundColor: Colors.green[800])
          );
        }
        return;
      }
      try {
        final res = await http.post(
          Uri.parse('${widget.backendUrl}/settings'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload)
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('success_settings')), backgroundColor: Colors.green[800])
            );
          }
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = widget.language == 'ar';
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F5132), Color(0xFF198754)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          title: Text(
            isRTL ? 'بوابة المدير العام' : 'Super Admin Portal',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded, size: 18),
              ),
              onPressed: _loadDashboardData,
              tooltip: t('refresh'),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white.withValues(alpha: 0.1),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: [
                  Tab(text: t('overview'), icon: const Icon(Icons.dashboard_rounded, size: 18)),
                  Tab(text: t('reviews'), icon: const Icon(Icons.star_rounded, size: 18)),
                  Tab(text: t('messages'), icon: const Icon(Icons.mail_rounded, size: 18)),
                  Tab(text: t('permissions'), icon: const Icon(Icons.admin_panel_settings_rounded, size: 18)),
                  Tab(text: t('settings'), icon: const Icon(Icons.settings_rounded, size: 18)),
                  Tab(text: widget.language == 'ar' ? 'المهام' : 'Tasks', icon: const Icon(Icons.assignment_outlined, size: 18)),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F5132)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildReviewsTab(),
                  _buildMessagesTab(),
                  _buildPermissionsTab(),
                  _buildSettingsTab(),
                  SharedTasksTab(
                    language: widget.language,
                    token: widget.token,
                    backendUrl: widget.backendUrl,
                    userRole: 'admin',
                    accentColor: const Color(0xFF0F5132),
                  ),
                ],
              ),
      ),
    );
  }

  // 1. Overview Tab
  Widget _buildOverviewTab() {
    final isAr = widget.language == 'ar';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Executive Hero Welcome Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F5132), Color(0xFF1E7E34)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F5132).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isAr ? 'لوحة المراقبة العامة' : 'Master Overview',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr ? 'مرحباً بك في مركز التحكم' : 'Welcome to Control Center',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'نظرة شاملة ومباشرة على أداء المنظومة الطبية والزيارات والمراجعات.'
                            : 'Live executive overview of medical system activity and metrics.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stat Cards Grid
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(t('stats_visits'), _stats['total_visits'].toString(), Icons.remove_red_eye_rounded, const Color(0xFF2563EB), '+14%'),
              _buildStatCard(t('stats_today'), _stats['today_visits'].toString(), Icons.trending_up_rounded, const Color(0xFFD97706), isAr ? 'مباشر' : 'Live'),
              _buildStatCard(t('stats_products'), _stats['products'].toString(), Icons.medical_services_rounded, const Color(0xFF4F46E5), isAr ? 'جهاز' : 'Items'),
              _buildStatCard(t('stats_categories'), _stats['categories'].toString(), Icons.category_rounded, const Color(0xFF0D9488), isAr ? 'أقسام' : 'Dept'),
              _buildStatCard(t('stats_pending_reviews'), _stats['pending_reviews'].toString(), Icons.star_rate_rounded, const Color(0xFFEAB308), isAr ? 'قيد التدقيق' : 'Pending'),
              _buildStatCard(t('stats_unread_messages'), _stats['unread_messages'].toString(), Icons.mark_as_unread_rounded, const Color(0xFFDC2626), isAr ? 'جديد' : 'New'),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity Log Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF0F5132), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isAr ? 'النشاطات الأخيرة في النظام' : 'Recent System Logs',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAr ? 'آخر التحديثات' : 'Live Stream',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLogItem(
                  isAr ? 'تم تعيين دور "مدير المستودع" للموظف manager@vision.com' : 'Admin assigned role "Manager" to manager@vision.com',
                  '5 mins ago',
                ),
                const Divider(height: 16),
                _buildLogItem(
                  isAr ? 'تم تحديث سعر الجهاز الطبي "Optima MRI" بواسطة المدير' : 'Product "Optima MRI" price was updated by admin',
                  '2 hours ago',
                ),
                const Divider(height: 16),
                _buildLogItem(
                  isAr ? 'رسالة استفسار جديدة من مستشفى الشفاء' : 'New contact message from Al-Shifa Hospital',
                  '1 day ago',
                ),
                const Divider(height: 16),
                _buildLogItem(
                  isAr ? 'تحديث إعدادات أوقات العمل الرسمية' : 'Settings updated: working hours changed',
                  '2 days ago',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String badge) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String action, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.history, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(action, style: const TextStyle(fontSize: 13)),
          ),
          Text(time, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  bool get _isAdminUser {
    final r = (widget.user['role'] ?? '').toString().toLowerCase();
    return r == 'admin';
  }

  // 2. Reviews Tab (Structured Scrollable Moderation View)
  Widget _buildReviewsTab() {
    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                widget.language == 'ar' ? 'لا توجد مراجعات معلقة' : 'No pending reviews.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      itemBuilder: (context, index) {
        final review = _reviews[index];
        final pNameMap = review['product_name'] ?? {};
        final pName = widget.language == 'ar' 
            ? (pNameMap['ar'] ?? pNameMap['en'] ?? '') 
            : (pNameMap['en'] ?? pNameMap['ar'] ?? '');
        final reviewerName = review['reviewer_name'] ?? 'Reviewer';
        final initial = reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : 'U';
        final rating = review['rating'] ?? 5;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.amber.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.amber.shade100,
                      child: Text(
                        initial,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reviewerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.teal.shade200),
                            ),
                            child: Text(
                              '${t('stats_products')}: $pName',
                              style: TextStyle(fontSize: 11, color: Colors.teal.shade900, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        Icons.star,
                        size: 14,
                        color: i < rating ? Colors.amber : Colors.grey[300],
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    review['comment'] ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _deleteReview(review['id']),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(t('delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveReview(review['id']),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(t('approve')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. Messages Tab (Structured Scrollable Unread Messages Table View)
  Widget _buildMessagesTab() {
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_read_outlined, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                widget.language == 'ar' ? 'لا توجد رسائل واردة غير مقروءة' : 'No incoming unread messages.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final senderName = msg['name'] ?? 'User';
        final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U';
        final bool isRead = msg['is_read'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isRead ? Colors.grey.shade200 : Colors.lightBlue.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isRead ? Colors.grey.shade100 : Colors.lightBlue.shade100,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isRead ? Colors.grey.shade800 : Colors.lightBlue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                senderName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (!isRead) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            msg['email'] ?? '',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        msg['subject'] ?? 'Contact',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    msg['message'] ?? '',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _deleteMessage(msg['id']),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(t('delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 4. Permissions Tab (Restricted to Admin Only)
  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isAdminUser)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.amber.shade900),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.language == 'ar'
                          ? 'تنبيه أمان: مدير النظام (Admin) هو الوحيد المخول بإنشاء وتعيين صلاحيات الموظفين.'
                          : 'Security Notice: Only Admin is authorized to assign and create employee accounts.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          if (_isAdminUser)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _roleFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(t('assign_role'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _assignEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: t('email_label'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (!val.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAssignRole,
                        decoration: InputDecoration(
                          labelText: t('select_role'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedAssignRole = val);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _assignUserRole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          t('submit'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Users list
          Text(
            widget.language == 'ar' ? 'سجل صلاحيات موظفي النظام' : 'User Roles Registry',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[900],
                    foregroundColor: Colors.white,
                    child: Text(user['name']?.substring(0, 1).toUpperCase() ?? 'U'),
                  ),
                  title: Text(user['name'] ?? ''),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Text(
                      user['role'] ?? '',
                      style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  // 5. Settings Tab
  Widget _buildSettingsTab() {
    final isAr = widget.language == 'ar';
    final dayLabels = {
      'saturday': {'ar': 'السبت', 'en': 'Saturday'},
      'sunday': {'ar': 'الأحد', 'en': 'Sunday'},
      'monday': {'ar': 'الاثنين', 'en': 'Monday'},
      'tuesday': {'ar': 'الثلاثاء', 'en': 'Tuesday'},
      'wednesday': {'ar': 'الأربعاء', 'en': 'Wednesday'},
      'thursday': {'ar': 'الخميس', 'en': 'Thursday'},
      'friday': {'ar': 'الجمعة', 'en': 'Friday'},
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _settingsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Core Settings
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'الإعدادات الأساسية للهوية' : 'Identity Core Settings',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _storeNameAr,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم الموقع بالعربية' : 'Store Name (AR)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeNameEn,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم الموقع بالإنجليزية' : 'Store Name (EN)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: isAr ? 'البريد الإلكتروني العام للموقع' : 'System Email Address',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ),

            // Section 2: Contacts & Support
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.contact_phone, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'بيانات الاتصال والدعم الفني' : 'Contacts & Support',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _storePhone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isAr ? 'رقم الهاتف الرئيسي للشركة' : 'General Phone Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeWhatsapp,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isAr ? 'رقم واتساب المبيعات' : 'Sales WhatsApp Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maintenancePhone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isAr ? 'رقم هاتف الصيانة الطارئة' : 'Emergency Maintenance Phone',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _maintenanceWhatsapp,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: isAr ? 'رقم واتساب الصيانة' : 'Service WhatsApp Number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section 3: About Us & Branding
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'عن الشركة وتذييل الصفحة' : 'About Us & Branding',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    TextFormField(
                      controller: _aboutUsTitleAr,
                      decoration: InputDecoration(
                        labelText: isAr ? 'عنوان قسم من نحن (بالعربية)' : 'About Us Title (AR)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aboutUsTitleEn,
                      decoration: InputDecoration(
                        labelText: isAr ? 'عنوان قسم من نحن (بالإنجليزية)' : 'About Us Title (EN)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aboutUsContentAr,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isAr ? 'محتوى قسم من نحن (بالعربية)' : 'About Us Content (AR)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _aboutUsContentEn,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: isAr ? 'محتوى قسم من نحن (بالإنجليزية)' : 'About Us Content (EN)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _footerTextAr,
                      decoration: InputDecoration(
                        labelText: isAr ? 'نص تذييل الصفحة (بالعربية)' : 'Footer Text (AR)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _footerTextEn,
                      decoration: InputDecoration(
                        labelText: isAr ? 'نص تذييل الصفحة (بالإنجليزية)' : 'Footer Text (EN)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyMapLink,
                      decoration: InputDecoration(
                        labelText: isAr ? 'رابط جوجل ماب لمقر الشركة' : 'Google Maps Location Link',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Section 4: Working Hours
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'أوقات العمل الأسبوعية' : 'Weekly Working Hours',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ..._workingHours.keys.map((dayKey) {
                      final dayData = _workingHours[dayKey] as Map;
                      final label = dayLabels[dayKey]?[isAr ? 'ar' : 'en'] ?? dayKey;
                      final isOpen = dayData['open'] == true;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Switch(
                                  value: isOpen,
                                  activeThumbColor: Colors.green[800],
                                  onChanged: (val) {
                                    setState(() {
                                      _workingHours[dayKey]['open'] = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (isOpen)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: dayData['from'] ?? '08:00',
                                        decoration: InputDecoration(
                                          labelText: isAr ? 'من الساعة' : 'From',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onChanged: (val) {
                                          _workingHours[dayKey]['from'] = val;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: dayData['to'] ?? '17:00',
                                        decoration: InputDecoration(
                                          labelText: isAr ? 'إلى الساعة' : 'To',
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onChanged: (val) {
                                          _workingHours[dayKey]['to'] = val;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(height: 1),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Submit Button
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              child: Text(
                t('submit'),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
