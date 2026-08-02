import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:vision_medical_system_app/services/db_helper.dart';
import 'shared_tasks_tab.dart';

class SellerDashboard extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;
  final Map user;

  const SellerDashboard({
    super.key,
    required this.language,
    required this.token,
    required this.backendUrl,
    required this.user,
  });

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  List<dynamic> _clients = [];
  List<dynamic> _dailyTasks = [];
  List<dynamic> _externalTasks = [];
  List<dynamic> _areas = [];
  int? _selectedAreaId;

  // Add Client form state
  final _clientFormKey = GlobalKey<FormState>();
  final TextEditingController _clientName = TextEditingController();
  final TextEditingController _clientCompany = TextEditingController();
  final TextEditingController _clientPhone = TextEditingController();

  // WhatsApp generator state
  final TextEditingController _waPhone = TextEditingController();
  final TextEditingController _waMessage = TextEditingController();

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'clients': 'Clients List',
      'add_client': 'Add Client',
      'whatsapp': 'WhatsApp Link',
      'daily': 'Daily Tasks',
      'external': 'External Tasks',
      'name': 'Client Name',
      'company': 'Hospital / Institution',
      'phone': 'Phone Number',
      'email': 'Email Address',
      'submit': 'Register Client',
      'cancel': 'Cancel',
      'wa_btn': 'Launch WhatsApp chat',
      'wa_msg': 'Message content',
      'success_client': 'Client added successfully!',
      'empty': 'No items registered.',
      'task_title': 'Task',
      'task_desc': 'Description',
      'task_status': 'Status',
    },
    'ar': {
      'clients': 'قائمة العملاء',
      'add_client': 'إضافة عميل جديد',
      'whatsapp': 'مولد رسائل واتساب',
      'daily': 'مهامي اليومية',
      'external': 'زياراتي الميدانية',
      'name': 'اسم العميل الكامل',
      'company': 'المستشفى / الجهة التابع لها',
      'phone': 'رقم الهاتف المباشر',
      'email': 'البريد الإلكتروني',
      'submit': 'تسجيل العميل',
      'cancel': 'إلغاء',
      'wa_btn': 'فتح محادثة واتساب الآن',
      'wa_msg': 'نص الرسالة المجهزة',
      'success_client': 'تم تسجيل العميل بنجاح في قاعدة البيانات!',
      'empty': 'لا توجد عناصر مسجلة حالياً.',
      'task_title': 'المهمة',
      'task_desc': 'تفاصيل الزيارة',
      'task_status': 'الحالة التشغيلية',
    }
  };

  String t(String key) {
    return _localized[widget.language]?[key] ?? key;
  }

  String _getLocalizedName(dynamic nameObj) {
    if (nameObj is Map) {
      return nameObj[widget.language] ?? nameObj['en'] ?? nameObj['ar'] ?? '';
    }
    return nameObj?.toString() ?? '';
  }

  final TextEditingController _searchQueryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadSellerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clientName.dispose();
    _clientCompany.dispose();
    _clientPhone.dispose();
    _waPhone.dispose();
    _waMessage.dispose();
    _searchQueryController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerData() async {
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

    // 1. Get clients
    try {
      final cRes = await http.get(Uri.parse('${widget.backendUrl}/clients'), headers: headers).timeout(const Duration(seconds: 4));
      if (cRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('seller_clients', cRes.body);
        final decoded = jsonDecode(cRes.body);
        _clients = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('seller_clients');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _clients = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _clients = [
          {'id': 1, 'name': 'Dr. Samir Mahmoud', 'company': 'Giza International Hospital', 'phone': '+201001234567', 'email': 'samir@giza.com'},
          {'id': 2, 'name': 'Dr. Mona Wagdy', 'company': 'Nasr City Specialized Clinic', 'phone': '+201119876543', 'email': 'mona@nasrcity.com'}
        ];
      }
    }

    // 2. Get daily tasks
    try {
      final dtRes = await http.get(Uri.parse('${widget.backendUrl}/tasks?type=internal'), headers: headers).timeout(const Duration(seconds: 4));
      if (dtRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('seller_daily_tasks', dtRes.body);
        final decoded = jsonDecode(dtRes.body);
        _dailyTasks = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('seller_daily_tasks');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _dailyTasks = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _dailyTasks = [
          {'id': 1, 'title': 'Follow up with Dr. Samir', 'description': 'Call Dr. Samir to discuss the Optima MRI quotation.', 'status': 'Pending'},
          {'id': 2, 'title': 'Email brochure to Dr. Mona', 'description': 'Send Vivid E90 ultrasound brochure and details.', 'status': 'Completed'}
        ];
      }
    }

    // 3. Get external tasks
    try {
      final etRes = await http.get(Uri.parse('${widget.backendUrl}/tasks?type=external'), headers: headers).timeout(const Duration(seconds: 4));
      if (etRes.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('seller_external_tasks', etRes.body);
        final decoded = jsonDecode(etRes.body);
        _externalTasks = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('seller_external_tasks');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _externalTasks = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      } else {
        _externalTasks = [
          {'id': 101, 'title': 'Visit Cleopatra Medical Group', 'description': 'In-person meeting with CEO to negotiate ICU ventilators purchase contract.', 'status': 'Scheduled'}
        ];
      }
    }
    // 4. Get areas
    try {
      final aRes = await http.get(Uri.parse('${widget.backendUrl}/areas'), headers: headers).timeout(const Duration(seconds: 4));
      if (aRes.statusCode == 200) {
        final decoded = jsonDecode(aRes.body);
        _areas = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      _areas = [
        {'id': 1, 'name': {'ar': 'مدينة نصر', 'en': 'Nasr City'}},
        {'id': 2, 'name': {'ar': 'الدقي', 'en': 'Dokki'}},
      ];
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMockData() {
    _clients = [
      {'id': 1, 'name': 'Dr. Samir Mahmoud', 'company': 'Giza International Hospital', 'phone': '+201001234567', 'email': 'samir@giza.com'},
      {'id': 2, 'name': 'Dr. Mona Wagdy', 'company': 'Nasr City Specialized Clinic', 'phone': '+201119876543', 'email': 'mona@nasrcity.com'}
    ];

    _areas = [
      {'id': 1, 'name': {'ar': 'مدينة نصر', 'en': 'Nasr City'}},
      {'id': 2, 'name': {'ar': 'الدقي', 'en': 'Dokki'}},
    ];

    _dailyTasks = [
      {'id': 1, 'title': 'Follow up with Dr. Samir', 'description': 'Call Dr. Samir to discuss the Optima MRI quotation.', 'status': 'Pending'},
      {'id': 2, 'title': 'Email brochure to Dr. Mona', 'description': 'Send Vivid E90 ultrasound brochure and details.', 'status': 'Completed'}
    ];

    _externalTasks = [
      {'id': 101, 'title': 'Visit Cleopatra Medical Group', 'description': 'In-person meeting with CEO to negotiate ICU ventilators purchase contract.', 'status': 'Scheduled'}
    ];
  }

  Future<void> _submitClient() async {
    if (_clientFormKey.currentState!.validate()) {
      final areaId = _selectedAreaId ?? (_areas.isNotEmpty ? (_areas.first['id'] as int?) : 1) ?? 1;
      
      if (widget.token.isEmpty) {
        setState(() {
          _clients.insert(0, {
            'id': _clients.length + 1,
            'name': _clientName.text.trim(),
            'company': _clientCompany.text.trim(),
            'phone': _clientPhone.text.trim(),
            'email': '',
          });
          _clientName.clear();
          _clientCompany.clear();
          _clientPhone.clear();
          _selectedAreaId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('success_client')), backgroundColor: Colors.cyan[850])
        );
        _tabController.animateTo(0);
        return;
      }

      final payload = {
        'name': {
          'ar': _clientName.text.trim(),
          'en': _clientName.text.trim(),
        },
        'area_id': areaId,
        'address': {
          'ar': _clientCompany.text.trim(),
          'en': _clientCompany.text.trim(),
        },
        'phone': _clientPhone.text.trim(),
        'email': null,
      };

      try {
        final res = await http.post(
          Uri.parse('${widget.backendUrl}/clients'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload)
        ).timeout(const Duration(seconds: 5));

        if (res.statusCode == 200 || res.statusCode == 201) {
          _clientName.clear();
          _clientCompany.clear();
          _clientPhone.clear();
          setState(() {
            _selectedAreaId = null;
          });
          _loadSellerData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('success_client')), backgroundColor: Colors.cyan[850])
            );
            _tabController.animateTo(0);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _launchWhatsApp() async {
    String phone = _waPhone.text.trim();
    if (phone.startsWith('+')) {
      phone = phone.substring(1);
    }
    final message = Uri.encodeComponent(_waMessage.text);
    final url = 'https://wa.me/$phone?text=$message';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp app.'))
          );
        }
      }
    } catch (_) {}
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
                colors: [Color(0xFF0E7490), Color(0xFF0891B2)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          title: Text(
            isRTL ? 'بوابة المبيعات والتسويق' : 'Sales Representative Portal',
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
              onPressed: _loadSellerData,
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
                  Tab(text: widget.language == 'ar' ? 'طلبات الفواتير' : 'Invoice Requests', icon: const Icon(Icons.receipt_long_rounded, size: 18)),
                  Tab(text: t('clients'), icon: const Icon(Icons.people_alt_rounded, size: 18)),
                  Tab(text: t('add_client'), icon: const Icon(Icons.person_add_alt_1_rounded, size: 18)),
                  Tab(text: t('whatsapp'), icon: const Icon(Icons.chat_bubble_rounded, size: 18)),
                  Tab(text: t('daily'), icon: const Icon(Icons.today_rounded, size: 18)),
                  Tab(text: t('external'), icon: const Icon(Icons.directions_car_rounded, size: 18)),
                  Tab(text: widget.language == 'ar' ? 'المهام الإدارية' : 'Admin Tasks', icon: const Icon(Icons.assignment_outlined, size: 18)),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0891B2)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildInvoiceRequestsTab(),
                  _buildClientsTab(),
                  _buildAddClientTab(),
                  _buildWhatsAppTab(),
                  _buildDailyTasksTab(),
                  _buildExternalTasksTab(),
                  SharedTasksTab(
                    language: widget.language,
                    token: widget.token,
                    backendUrl: widget.backendUrl,
                    userRole: 'seller',
                    accentColor: const Color(0xFF0891B2),
                  ),
                ],
              ),
      ),
    );
  }

  // 1. Clients List
  Widget _buildClientsTab() {
    final query = _searchQueryController.text.toLowerCase().trim();
    final filteredClients = _clients.where((c) {
      final name = c['name'] != null ? _getLocalizedName(c['name']).toLowerCase() : '';
      final company = c['company'] != null
          ? c['company'].toString().toLowerCase()
          : (c['address'] != null ? _getLocalizedName(c['address']).toLowerCase() : '');
      final phone = c['phone']?.toString().toLowerCase() ?? '';
      return name.contains(query) || company.contains(query) || phone.contains(query);
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.white,
          child: TextField(
            controller: _searchQueryController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.language == 'ar' ? 'البحث عن عميل أو مستشفى...' : 'Search client or hospital...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0891B2)),
              suffixIcon: _searchQueryController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchQueryController.clear();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
        Expanded(
          child: filteredClients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        widget.language == 'ar'
                            ? 'لم يتم العثور على عملاء مطابقين'
                            : 'No matching clients found',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final c = filteredClients[index];
                    final name = c['name'] != null ? _getLocalizedName(c['name']) : 'Client';
                    final company = c['company'] != null
                        ? c['company'].toString()
                        : (c['address'] != null ? _getLocalizedName(c['address']) : 'Medical Institution');
                    final phone = c['phone']?.toString() ?? 'N/A';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF0891B2).withValues(alpha: 0.15),
                                    const Color(0xFF0891B2).withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF0891B2), size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    company,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF0891B2)),
                                      const SizedBox(width: 4),
                                      Text(
                                        phone,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF0E7490), fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.chat_rounded, color: Color(0xFF15803D), size: 18),
                              ),
                              onPressed: () {
                                final nameText = c['name'] != null ? _getLocalizedName(c['name']) : '';
                                setState(() {
                                  _waPhone.text = c['phone'] ?? '';
                                  _waMessage.text = widget.language == 'ar'
                                      ? 'مرحباً $nameText، بخصوص العرض المقدم من شركة فيجن ميديكال...'
                                      : 'Hello $nameText, regarding the quotation from Vision Medical...';
                                });
                                _tabController.animateTo(2);
                              },
                              tooltip: 'WhatsApp',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 2. Add Client
  Widget _buildAddClientTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _clientFormKey,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t('add_client'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clientName,
                  decoration: InputDecoration(
                    labelText: t('name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clientCompany,
                  decoration: InputDecoration(
                    labelText: t('company'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _clientPhone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: t('phone'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<dynamic>(
                  initialValue: _selectedAreaId,
                  decoration: InputDecoration(
                    labelText: widget.language == 'ar' ? 'المنطقة (المحافظة)' : 'Area / Governorate',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _areas.map((a) {
                    final name = _getLocalizedName(a['name']);
                    return DropdownMenuItem<dynamic>(
                      value: a['id'],
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedAreaId = val as int?);
                  },
                  validator: (val) => val == null ? 'Required' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitClient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan[800],
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
    );
  }

  // 3. WhatsApp link generator
  Widget _buildWhatsAppTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('whatsapp'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              TextField(
                controller: _waPhone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t('phone'),
                  hintText: 'e.g. 201001234567',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _waMessage,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: t('wa_msg'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _launchWhatsApp,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(t('wa_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _mapStatusLabel(String status) {
    final lower = status.toLowerCase();
    if (lower == 'pending') {
      return widget.language == 'ar' ? 'قيد الانتظار' : 'Pending';
    } else if (lower == 'in_progress') {
      return widget.language == 'ar' ? 'جاري العمل' : 'In Progress';
    } else if (lower == 'completed') {
      return widget.language == 'ar' ? 'مكتملة' : 'Completed';
    } else if (lower == 'cancelled') {
      return widget.language == 'ar' ? 'ملغاة' : 'Cancelled';
    }
    return status;
  }

  // 4. Daily Tasks
  Widget _buildDailyTasksTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _dailyTasks.length,
      itemBuilder: (context, index) {
        final task = _dailyTasks[index];
        final status = task['status']?.toString().toLowerCase() ?? 'pending';
        final isCompleted = status == 'completed';
        final title = task['title'] is Map
            ? (widget.language == 'ar'
                ? (task['title']['ar'] ?? task['title']['en'] ?? '')
                : (task['title']['en'] ?? task['title']['ar'] ?? ''))
            : (task['title'] ?? '').toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: isCompleted ? Colors.green : Colors.grey,
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(task['description'] ?? ''),
          ),
        );
      },
    );
  }

  // 5. External Tasks
  Widget _buildExternalTasksTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _externalTasks.length,
      itemBuilder: (context, index) {
        final task = _externalTasks[index];
        final title = task['title'] is Map
            ? (widget.language == 'ar'
                ? (task['title']['ar'] ?? task['title']['en'] ?? '')
                : (task['title']['en'] ?? task['title']['ar'] ?? ''))
            : (task['title'] ?? '').toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.calendar_month, color: Colors.cyan[800]),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(task['description'] ?? ''),
            trailing: Text(
              _mapStatusLabel(task['status']?.toString() ?? ''),
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan[900], fontSize: 12),
            ),
          ),
        );
      },
    );
  }
  List<dynamic> _invoiceRequests = [
    {
      'id': 101,
      'request_type': 'maintenance_service',
      'type': 'single',
      'client': {'name': 'مستشفى الشفاء التخصصي'},
      'total_amount': 18500.0,
      'status': 'issued',
      'notes': 'صيانة جهاز الرنين وتغيير فلاتر الأكسجين',
      'items': [
        {'item_name': 'زيارة صيانة فنية مع كشف عام', 'quantity': 1, 'unit_price': 3500.0, 'invoice_number': 'INV-2026-00101'},
        {'item_name': 'طقم قطع غيار فلاتر هواء وطاقة', 'quantity': 3, 'unit_price': 5000.0, 'invoice_number': 'INV-2026-00101'}
      ]
    },
    {
      'id': 102,
      'request_type': 'sales_product',
      'type': 'single',
      'client': {'name': 'مركز العاصمة للأشعة'},
      'total_amount': 750000.0,
      'status': 'pending_accountant',
      'notes': 'توريد جهاز سونار ثلاثي الأبعاد مع الضمان',
      'items': [
        {'item_name': 'جهاز سونار Vivid E90 Ultrasound', 'quantity': 1, 'unit_price': 750000.0}
      ]
    }
  ];

  Widget _buildInvoiceRequestsTab() {
    final isAr = widget.language == 'ar';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0891B2),
        foregroundColor: Colors.white,
        onPressed: _showCreateInvoiceRequestDialog,
        icon: const Icon(Icons.add_task_rounded),
        label: Text(isAr ? 'طلب فاتورة جديد' : 'New Request', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _invoiceRequests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text(
                    isAr ? 'لا توجد طلبات فواتير حالية' : 'No invoice requests found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _invoiceRequests.length,
              itemBuilder: (context, index) {
                final req = _invoiceRequests[index];
                final clientName = req['client']?['name'] != null
                    ? _getLocalizedName(req['client']['name'])
                    : (isAr ? 'عميل ميداني' : 'Field Client');

                final String status = req['status'] ?? 'pending_accountant';
                final String requestType = req['request_type'] ?? 'maintenance_service';

                Color statusColor = Colors.amber[800]!;
                String statusText = isAr ? 'قيد مراجعة المحاسب' : 'Pending Accountant';

                if (status == 'issued') {
                  statusColor = Colors.blue[800]!;
                  statusText = isAr ? 'تم إصدار الفاتورة 📄' : 'Issued 📄';
                } else if (status == 'ready_for_collection' || status == 'client_approved') {
                  statusColor = Colors.green[800]!;
                  statusText = isAr ? 'مقبولة (جاهزة للتحصيل) 💰' : 'Approved (Ready for Collection)';
                } else if (status == 'client_rejected') {
                  statusColor = Colors.red[800]!;
                  statusText = isAr ? 'مرفوضة من العميل' : 'Client Rejected';
                } else if (status == 'collected') {
                  statusColor = Colors.teal[800]!;
                  statusText = isAr ? 'تم التحصيل بالكامل ✅' : 'Collected ✅';
                }

                final isMaintenance = requestType == 'maintenance_service';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMaintenance
                                    ? Colors.orange.withValues(alpha: 0.12)
                                    : Colors.cyan.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isMaintenance ? Icons.handyman_rounded : Icons.shopping_bag_rounded,
                                color: isMaintenance ? Colors.orange[900] : const Color(0xFF0E7490),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    clientName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isMaintenance
                                        ? (isAr ? 'خدمة صيانة خارجية ميدانية' : 'Outdoor Maintenance Service')
                                        : (isAr ? 'توريد وتبيع أجهزة طبية' : 'Medical Equipment Sales'),
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        if (req['notes'] != null && req['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            '${isAr ? 'ملاحظات:' : 'Notes:'} ${req['notes']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${isAr ? 'الإجمالي:' : 'Total:'} ${req['total_amount']} EGP',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0E7490)),
                            ),
                            Text(
                              '#Req-${req['id']}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(height: 1),
                        ),
                        // Action Buttons section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _showPaperInvoiceDialog(req),
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.indigo),
                              label: Text(
                                isAr ? 'معاينة / طباعة ورقية' : 'Paper Print',
                                style: const TextStyle(color: Colors.indigo, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Spacer(),
                            if (status == 'issued') ...[
                              OutlinedButton.icon(
                                onPressed: () => _respondByClient(req['id'], 'rejected'),
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                                label: Text(isAr ? 'رفض العميل' : 'Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _respondByClient(req['id'], 'approved'),
                                icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                                label: Text(isAr ? 'موافقة العميل 🟢' : 'Approve 🟢'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF15803D),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCreateInvoiceRequestDialog() {
    final isAr = widget.language == 'ar';
    String requestType = 'maintenance_service';
    String requestMode = 'single';
    int? selectedClientId = _clients.isNotEmpty ? (_clients.first['id'] as int?) : null;
    final itemNameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.note_add_rounded, color: Color(0xFF0E7490)),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'إنشاء طلب فاتورة ميداني' : 'Create Field Invoice Request',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isAr ? 'نوع الطلب الميداني:' : 'Request Category:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text(isAr ? 'صيانة خارجية' : 'Maintenance'),
                            selected: requestType == 'maintenance_service',
                            onSelected: (val) {
                              if (val) setDialogState(() => requestType = 'maintenance_service');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Text(isAr ? 'مبيعات أجهزة' : 'Sales Product'),
                            selected: requestType == 'sales_product',
                            onSelected: (val) {
                              if (val) setDialogState(() => requestType = 'sales_product');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: selectedClientId,
                      decoration: InputDecoration(
                        labelText: isAr ? 'العميل / المستشفى' : 'Select Client',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _clients.map((c) {
                        return DropdownMenuItem<int>(
                          value: c['id'] as int?,
                          child: Text(_getLocalizedName(c['name'])),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedClientId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: itemNameController,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم الخدمة / الجهاز / قطعة الغيار' : 'Item / Service Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'الكمية' : 'Qty',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr ? 'سعر الوحدة (ج.م)' : 'Unit Price',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: isAr ? 'ملاحظات وتفاصيل الخدمة' : 'Notes / Warranty Details',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(quantityController.text) ?? 1;
                    final price = double.tryParse(priceController.text) ?? 0.0;
                    final total = qty * price;

                    final clientObj = _clients.firstWhere(
                      (c) => c['id'] == selectedClientId,
                      orElse: () => {'name': isAr ? 'عميل ميداني' : 'Field Client'},
                    );

                    setState(() {
                      _invoiceRequests.insert(0, {
                        'id': _invoiceRequests.length + 105,
                        'request_type': requestType,
                        'type': requestMode,
                        'client': {'name': clientObj['name']},
                        'total_amount': total,
                        'status': 'pending_accountant',
                        'notes': notesController.text,
                        'items': [
                          {
                            'item_name': itemNameController.text.isNotEmpty ? itemNameController.text : 'خدمة صيانة ومراجعة',
                            'quantity': qty,
                            'unit_price': price,
                          }
                        ]
                      });
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تم إرسال طلب الفاتورة للمحاسب بنجاح!' : 'Invoice request sent to accountant!'),
                        backgroundColor: const Color(0xFF0891B2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(isAr ? 'إرسال للمحاسب' : 'Submit Request', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPaperInvoiceDialog(Map req) {
    final isAr = widget.language == 'ar';
    final clientName = req['client']?['name'] != null ? _getLocalizedName(req['client']['name']) : 'Client';
    final items = (req['items'] as List? ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAr ? 'معاينة الفاتورة الورقية' : 'Paper Invoice Layout',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0E7490)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VISION MEDICAL SYSTEM',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber[900]),
                      ),
                      const SizedBox(height: 4),
                      Text('${isAr ? 'اسم العميل / المستشفى:' : 'Client:'} $clientName', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${isAr ? 'رقم طلب الفاتورة:' : 'Req ID:'} #REQ-${req['id']}'),
                      Text('${isAr ? 'التاريخ:' : 'Date:'} ${DateTime.now().toString().split(' ')[0]}'),
                      const Divider(),
                      Text(isAr ? 'بيانات البنود والخدمات:' : 'Invoice Items:'),
                      const SizedBox(height: 6),
                      ...items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('• ${it['item_name']} (x${it['quantity']})', style: const TextStyle(fontSize: 12)),
                                Text('${it['unit_price'] * (it['quantity'] ?? 1)} EGP', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isAr ? 'الإجمالي المستحق:' : 'Total Amount:', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${req['total_amount']} EGP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber[900])),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تم إرسال امر الطباعة الفوري للجهاز' : 'Sent paper invoice to printer'),
                        backgroundColor: Colors.indigo,
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, color: Colors.white),
                  label: Text(isAr ? 'طباعة الفاتورة الورقية الآن 🖨️' : 'Print Paper Invoice Now 🖨️', style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _respondByClient(int requestId, String responseType) {
    final isAr = widget.language == 'ar';
    if (responseType == 'rejected') {
      final reasonController = TextEditingController();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(isAr ? 'تسجيل سبب رفض العميل' : 'Record Rejection Reason'),
            content: TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: isAr ? 'سبب الرفض' : 'Reason for Rejection',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    final idx = _invoiceRequests.indexWhere((r) => r['id'] == requestId);
                    if (idx != -1) {
                      _invoiceRequests[idx]['status'] = 'client_rejected';
                      _invoiceRequests[idx]['rejection_reason'] = reasonController.text;
                    }
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(isAr ? 'حفظ الرفض' : 'Save Rejection', style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        final idx = _invoiceRequests.indexWhere((r) => r['id'] == requestId);
        if (idx != -1) {
          _invoiceRequests[idx]['status'] = 'ready_for_collection';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم تسجيل موافقة العميل! وتم إرسال إشعار فوري للمحصل 💰' : 'Client approved! Instant notification sent to Collector 💰'),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
    }
  }
}
