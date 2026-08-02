import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:vision_medical_system_app/services/db_helper.dart';
import 'shared_tasks_tab.dart';

class EngineerDashboard extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;
  final Map user;

  const EngineerDashboard({
    super.key,
    required this.language,
    required this.token,
    required this.backendUrl,
    required this.user,
  });

  @override
  State<EngineerDashboard> createState() => _EngineerDashboardState();
}

class _EngineerDashboardState extends State<EngineerDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Data lists matching website state
  List<dynamic> _clients = [];
  List<dynamic> _externalTasks = [];
  List<dynamic> _quotations = [];
  List<dynamic> _invoices = [];
  List<dynamic> _products = [];
  List<dynamic> _areas = [];
  List<dynamic> _reports = [];

  // Search & Filter States
  String _clientSearchQuery = '';
  String _selectedClientType = 'all';
  String _selectedGov = 'all';

  // Add Client Form Controllers
  final _addClientFormKey = GlobalKey<FormState>();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();
  final TextEditingController _clientAddressController = TextEditingController();
  String _newClientType = 'مستشفى';

  // Quotation Request Form Controllers
  final _quoteFormKey = GlobalKey<FormState>();
  dynamic _selectedQuoteClient;
  final List<int> _selectedProducts = [];
  final TextEditingController _customItemController = TextEditingController();
  final TextEditingController _quoteAmountController = TextEditingController();
  final TextEditingController _quoteNotesController = TextEditingController();

  // Maintenance Report Form Controllers
  final _reportFormKey = GlobalKey<FormState>();
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _faultDescController = TextEditingController();
  final TextEditingController _workDoneController = TextEditingController();
  String _deviceStatus = 'operational';

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'title': 'Outdoor Service & Field Engineering',
      'subtitle': 'Field Maintenance Engineer Portal',
      'tab_clients': 'Clients & Hospitals',
      'tab_visits': 'Field Visits & Tasks',
      'tab_quotes': 'Quotations & Requests',
      'tab_invoices': 'Invoices & Collections',
      'tab_reports': 'Maintenance Reports',
      'add_client': 'Add Client / Hospital',
      'search_clients': 'Search by name, phone, hospital...',
      'contacts': 'Contacts',
      'address': 'View Address',
      'edit': 'Edit',
      'delete': 'Delete',
      'call': 'Call',
      'whatsapp': 'WhatsApp',
      'empty': 'No records found.',
      'type_all': 'All Types',
      'type_hospital': 'Hospital',
      'type_clinic': 'Clinic',
      'type_center': 'Medical Center',
      'type_company': 'Company / Lab',
      'create_quote': 'Request New Quotation',
      'select_client': 'Select Client / Hospital*',
      'select_products': 'Select Spare Parts / Medical Devices',
      'custom_item': 'Or type custom item name',
      'amount': 'Estimated Total Amount (EGP)',
      'notes': 'Special Notes & Terms',
      'submit_quote': 'Send Request to Accountant',
      'quote_success': 'Quotation request sent to accountant successfully!',
      'submit_report': 'Save Maintenance Report',
      'report_success': 'Maintenance report saved successfully!',
    },
    'ar': {
      'title': 'الصيانة الميدانية والهندسة الطبية',
      'subtitle': 'واجهة مهندس الصيانة الميدانية (الخارجي)',
      'tab_clients': 'سجل العملاء والمستشفيات',
      'tab_visits': 'الزيارات والمهمات الميدانية',
      'tab_quotes': 'عروض الأسعار والطلب',
      'tab_invoices': 'الفواتير والتحصيل الميداني',
      'tab_reports': 'تقارير الصيانة والمعايرة',
      'add_client': 'إضافة عميل / مستشفى جديدة',
      'search_clients': 'بحث باسم المستشفى، العميل، رقم الهاتف...',
      'contacts': 'مسؤولو التواصل',
      'address': 'العنوان التفصيلي',
      'edit': 'تعديل',
      'delete': 'حذف',
      'call': 'اتصال',
      'whatsapp': 'واتساب',
      'empty': 'لا توجد بيانات مسجلة حالياً.',
      'type_all': 'جميع الأنواع',
      'type_hospital': 'مستشفى',
      'type_clinic': 'عيادة',
      'type_center': 'مركز طبي',
      'type_company': 'شركة / معمل',
      'create_quote': 'طلب إنشاء عرض سعر جديد (للمحاسب)',
      'select_client': 'اختر المستشفى / العميل المستهدف*',
      'select_products': 'اختر قطع الغيار أو الأجهزة الطبية',
      'custom_item': 'أو اكتب اسم الخدمة / القطعة يدوياً',
      'amount': 'القيمة المالية الإجمالية (ج.م)',
      'notes': 'الشروط والملاحظات الفنية الخاصة',
      'submit_quote': 'إرسال الطلب للمحاسب المالي لتسعيره',
      'quote_success': 'تم إرسال طلب عرض السعر للمحاسب المالي بنجاح!',
      'submit_report': 'حفظ وتوثيق تقرير الصيانة الميدانية',
      'report_success': 'تم حفظ وتوثيق تقرير الصيانة الميدانية بنجاح!',
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAllEngineerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clientNameController.dispose();
    _clientPhoneController.dispose();
    _clientAddressController.dispose();
    _customItemController.dispose();
    _quoteAmountController.dispose();
    _quoteNotesController.dispose();
    _deviceNameController.dispose();
    _serialNoController.dispose();
    _faultDescController.dispose();
    _workDoneController.dispose();
    super.dispose();
  }

  Future<void> _loadAllEngineerData() async {
    if (widget.token.isEmpty) {
      _loadMockData();
      return;
    }

    setState(() => _isLoading = true);
    final headers = {
      'Authorization': 'Bearer ${widget.token}',
      'Accept': 'application/json',
    };

    // 1. Load Clients
    try {
      final res = await http.get(Uri.parse('${widget.backendUrl}/clients'), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('engineer_clients', res.body);
        final decoded = jsonDecode(res.body);
        _clients = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      final cached = await ChatDatabaseHelper.instance.getFromCache('engineer_clients');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _clients = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    }

    // 2. Load External Visits & Tasks
    try {
      final res = await http.get(Uri.parse('${widget.backendUrl}/tasks?type=external'), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('engineer_tasks', res.body);
        final decoded = jsonDecode(res.body);
        _externalTasks = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      final cached = await ChatDatabaseHelper.instance.getFromCache('engineer_tasks');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _externalTasks = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    }

    // 3. Load Quotations
    try {
      final res = await http.get(Uri.parse('${widget.backendUrl}/quotations'), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('engineer_quotations', res.body);
        final decoded = jsonDecode(res.body);
        _quotations = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      final cached = await ChatDatabaseHelper.instance.getFromCache('engineer_quotations');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _quotations = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    }

    // 4. Load Invoices
    try {
      final res = await http.get(Uri.parse('${widget.backendUrl}/invoices'), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('engineer_invoices', res.body);
        final decoded = jsonDecode(res.body);
        _invoices = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {
      final cached = await ChatDatabaseHelper.instance.getFromCache('engineer_invoices');
      if (cached != null) {
        final decoded = jsonDecode(cached);
        _invoices = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    }

    // 5. Load Products & Spare Parts
    try {
      final res = await http.get(Uri.parse('${widget.backendUrl}/products'), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        _products = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {}

    // 6. Load Areas / Governorates
    try {
      final res = await http.get(Uri.parse('${widget.backendUrl}/areas'), headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        _areas = decoded is List ? decoded : (decoded['data'] as List? ?? []);
      }
    } catch (_) {}

    if (_clients.isEmpty) _loadMockData();

    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMockData() {
    _clients = [
      {
        'id': 1,
        'name': 'مستشفى الجيزة الدولي',
        'type': 'مستشفى',
        'governorate': 'الجيزة',
        'city': 'الدقي',
        'phone': '01001234567',
        'detailed_address': 'شارع التحرير، برج الصفا، الدور 4',
        'contacts': [
          {'id': 101, 'name': 'د. سمير محمود', 'job_title': 'مدير المستشفى', 'phone': '01001234567'},
          {'id': 102, 'name': 'م. أحمد خالد', 'job_title': 'رئيس قسم الصيانة الطبية', 'phone': '01099887766'}
        ]
      },
      {
        'id': 2,
        'name': 'مركز النيل للأشعة والسونار',
        'type': 'مركز طبي',
        'governorate': 'القاهرة',
        'city': 'مدينة نصر',
        'phone': '01119876543',
        'detailed_address': 'شارع مكرم عبيد، تقاطع حسن مأمون',
        'contacts': [
          {'id': 103, 'name': 'د. منى وجدي', 'job_title': 'استشاري الأشعة', 'phone': '01119876543'}
        ]
      },
      {
        'id': 3,
        'name': 'مستشفى السلام التخصصي',
        'type': 'مستشفى',
        'governorate': 'القاهرة',
        'city': 'المعادي',
        'phone': '01223344556',
        'detailed_address': 'طريق كورنيش النيل، بجوار فندق المعادي',
        'contacts': []
      },
    ];

    _externalTasks = [
      {
        'id': 201,
        'title': 'صيانة عاجلة لجهاز رنين Optima MR450',
        'description': 'بلاغ عطل في تبريد الهيليوم ومعايرة الملفات الخاصة بالرأس.',
        'client_hospital': 'مستشفى الجيزة الدولي',
        'status': 'قيد التنفيذ',
        'priority': 'High',
        'phone': '01001234567',
        'address': 'شارع التحرير، الدقي - الجيزة',
      },
      {
        'id': 202,
        'title': 'تركيب ومعايرة جهاز سونار Vivid E90',
        'description': 'تركيب البروب السطحي والقلبي واختبار جودة الصورة.',
        'client_hospital': 'مركز النيل للأشعة',
        'status': 'مجدولة اليوم',
        'priority': 'Medium',
        'phone': '01119876543',
        'address': 'مكرم عبيد، مدينة نصر - القاهرة',
      },
    ];

    _quotations = [
      {
        'id': 301,
        'quotation_number': 'QT-2026-0041',
        'client': {'name': 'مستشفى الجيزة الدولي'},
        'total_amount': 85000.0,
        'status': 'approved',
        'created_at': '2026-07-20',
        'items': [{'name': 'ملف رنين مغناطيسي MRI Coil', 'quantity': 1}]
      },
      {
        'id': 302,
        'quotation_number': 'QT-2026-0042',
        'client': {'name': 'مركز النيل للأشعة'},
        'total_amount': 12000.0,
        'status': 'pending',
        'created_at': '2026-07-28',
        'items': [{'name': 'حساس أوكسجين تنفس صناعي O2 Sensor', 'quantity': 1}]
      },
    ];

    _invoices = [
      {
        'id': 401,
        'invoice_number': 'INV-2026-101',
        'client': {'name': 'مستشفى الجيزة الدولي'},
        'amount': 85000.0,
        'status': 'paid',
        'due_date': '2026-08-10',
      },
      {
        'id': 402,
        'invoice_number': 'INV-2026-102',
        'client': {'name': 'مركز النيل للأشعة'},
        'amount': 12000.0,
        'status': 'unpaid',
        'due_date': '2026-08-15',
      },
    ];

    _products = [
      {'id': 1, 'name': {'ar': 'ملف رنين مغناطيسي MRI Coil', 'en': 'MRI RF Coil'}, 'price': 85000.0},
      {'id': 2, 'name': {'ar': 'حساس أوكسجين تنفس صناعي O2 Sensor', 'en': 'O2 Cell Sensor'}, 'price': 12000.0},
      {'id': 3, 'name': {'ar': 'بروب سونار سطحي Linear Probe', 'en': 'Ultrasound Linear Probe'}, 'price': 45000.0},
      {'id': 4, 'name': {'ar': 'بطارية رسم قلب ECG Battery', 'en': 'ECG Defib Battery'}, 'price': 6500.0},
    ];
  }

  List<dynamic> get _filteredClients {
    return _clients.where((c) {
      final nameMatches = _clientSearchQuery.isEmpty ||
          (c['name']?.toString().toLowerCase().contains(_clientSearchQuery.toLowerCase()) ?? false) ||
          (c['phone']?.toString().contains(_clientSearchQuery) ?? false);
      final typeMatches = _selectedClientType == 'all' || (c['type']?.toString() == _selectedClientType);
      final govMatches = _selectedGov == 'all' || (c['governorate']?.toString() == _selectedGov);
      return nameMatches && typeMatches && govMatches;
    }).toList();
  }

  Future<void> _handleCreateClient() async {
    if (!_addClientFormKey.currentState!.validate()) return;

    final newClientData = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'name': _clientNameController.text,
      'type': _newClientType,
      'phone': _clientPhoneController.text,
      'detailed_address': _clientAddressController.text,
      'contacts': [],
    };

    if (widget.token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('${widget.backendUrl}/clients'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'name': _clientNameController.text,
            'type': _newClientType,
            'phone': _clientPhoneController.text,
            'detailed_address': _clientAddressController.text,
          }),
        );
      } catch (_) {}
    }

    setState(() {
      _clients.insert(0, newClientData);
      _clientNameController.clear();
      _clientPhoneController.clear();
      _clientAddressController.clear();
    });

    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إضافـة العميل / المستشفى بنجاح!'), backgroundColor: Color(0xFF0D9488)),
    );
  }

  Future<void> _submitQuotationRequest() async {
    if (!_quoteFormKey.currentState!.validate() || _selectedQuoteClient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل وتعبئة البيانات المطلوبة'), backgroundColor: Colors.red),
      );
      return;
    }

    final List<Map<String, dynamic>> itemsList = [];
    for (var pid in _selectedProducts) {
      final prod = _products.firstWhere((p) => p['id'] == pid, orElse: () => null);
      if (prod != null) {
        itemsList.add({
          'name': _getLocalizedName(prod['name']),
          'quantity': 1,
          'unit_price': (prod['price'] as num).toDouble(),
        });
      }
    }

    final customName = _customItemController.text.trim();
    final amount = double.tryParse(_quoteAmountController.text) ?? 0.0;

    if (itemsList.isEmpty) {
      itemsList.add({
        'name': customName.isNotEmpty ? customName : 'طلب قطع غيار وخدمات صيانة ميدانية',
        'quantity': 1,
        'unit_price': amount,
      });
    }

    if (widget.token.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('${widget.backendUrl}/quotations'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'client_id': _selectedQuoteClient,
            'total_amount': amount,
            'items': itemsList,
            'notes': '[طلب مهندس صيانة ميدانية] ${_quoteNotesController.text}',
          }),
        );
      } catch (_) {}
    }

    final selectedClientObj = _clients.firstWhere((c) => c['id'] == _selectedQuoteClient, orElse: () => null);
    final clientName = selectedClientObj != null ? selectedClientObj['name'] : 'مستشفى طبي';

    setState(() {
      _quotations.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch,
        'quotation_number': 'QT-2026-${_quotations.length + 100}',
        'client': {'name': clientName},
        'total_amount': amount,
        'status': 'pending',
        'created_at': DateTime.now().toString().split(' ')[0],
        'items': itemsList,
      });
      _selectedProducts.clear();
      _customItemController.clear();
      _quoteAmountController.clear();
      _quoteNotesController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('quote_success')), backgroundColor: const Color(0xFF0D9488)),
    );
    _tabController.animateTo(2);
  }

  void _submitMaintenanceReport() {
    if (!_reportFormKey.currentState!.validate()) return;

    final newReport = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'device_name': _deviceNameController.text,
      'serial_no': _serialNoController.text,
      'fault': _faultDescController.text,
      'work_done': _workDoneController.text,
      'status': _deviceStatus,
      'date': DateTime.now().toString().split(' ')[0],
    };

    setState(() {
      _reports.insert(0, newReport);
      _deviceNameController.clear();
      _serialNoController.clear();
      _faultDescController.clear();
      _workDoneController.clear();
      _deviceStatus = 'operational';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('report_success')), backgroundColor: const Color(0xFF0D9488)),
    );
  }

  void _launchCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showContactsModal(Map client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final contacts = (client['contacts'] as List? ?? []);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'مسؤولو التواصل - ${client['name']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              if (contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('لا يوجد مسؤولو تواصل مسجلين لهذا العميل', style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: contacts.length,
                  itemBuilder: (context, idx) {
                    final c = contacts[idx];
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFCCFBF1), child: Icon(Icons.person, color: Color(0xFF0D9488))),
                      title: Text(c['name'] ?? 'مسؤول', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(c['job_title'] ?? 'مسؤول مستشفى', style: const TextStyle(fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.phone, color: Color(0xFF0D9488)),
                        onPressed: () => _launchCall(c['phone'] ?? ''),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddressModal(Map client) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(client['name'] ?? 'تفاصيل العنوان', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text('المحافظة: ${client['governorate'] ?? 'غير معروف'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('المدينة / المركز: ${client['city'] ?? 'غير معروف'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              const Text('العنوان بالتفصيل:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: Text(client['detailed_address'] ?? 'غير معروف', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                  child: const Text('إغلاق', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showAddClientModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: _addClientFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تسجيل عميل أو مستشفى جديدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _clientNameController,
                  validator: (v) => v == null || v.isEmpty ? 'حقل مطلوب' : null,
                  decoration: InputDecoration(labelText: 'اسم المستشفى / العميل*', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _newClientType,
                  items: const [
                    DropdownMenuItem(value: 'مستشفى', child: Text('مستشفى')),
                    DropdownMenuItem(value: 'عيادة', child: Text('عيادة')),
                    DropdownMenuItem(value: 'مركز طبي', child: Text('مركز طبي')),
                    DropdownMenuItem(value: 'شركة / معمل', child: Text('شركة / معمل')),
                  ],
                  onChanged: (val) => setState(() => _newClientType = val!),
                  decoration: InputDecoration(labelText: 'النوع', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _clientPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _clientAddressController,
                  decoration: InputDecoration(labelText: 'العنوان التفصيلي', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _handleCreateClient,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                    child: const Text('حفظ وتسجيل العميل', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = widget.language == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // Top Header Bar matching Website Design System
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('title'),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: Colors.tealAccent, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t('subtitle'),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 5 Tabs Matching Website Sub-tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.amberAccent,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    tabs: [
                      Tab(text: t('tab_clients'), icon: const Icon(Icons.people_alt_rounded, size: 18)),
                      Tab(text: t('tab_visits'), icon: const Icon(Icons.assignment_late_rounded, size: 18)),
                      Tab(text: t('tab_quotes'), icon: const Icon(Icons.request_quote_rounded, size: 18)),
                      Tab(text: t('tab_invoices'), icon: const Icon(Icons.receipt_long_rounded, size: 18)),
                      Tab(text: t('tab_reports'), icon: const Icon(Icons.description_rounded, size: 18)),
                      Tab(text: widget.language == 'ar' ? 'مهامي' : 'My Tasks', icon: const Icon(Icons.assignment_outlined, size: 18)),
                    ],
                  ),
                ],
              ),
            ),

            // Main Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D9488)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildClientsTab(),
                        _buildVisitsTab(),
                        _buildQuotesTab(),
                        _buildInvoicesTab(),
                        _buildReportsTab(),
                        SharedTasksTab(
                          language: widget.language,
                          token: widget.token,
                          backendUrl: widget.backendUrl,
                          userRole: 'engineer',
                          accentColor: const Color(0xFF0F766E),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. TAB: Clients & Hospitals Directory
  Widget _buildClientsTab() {
    return Column(
      children: [
        // Action & Filter Header Bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Column(
            children: [
              // Row 1: Search Input
              TextField(
                onChanged: (val) => setState(() => _clientSearchQuery = val),
                decoration: InputDecoration(
                  hintText: t('search_clients'),
                  prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),

              // Row 2: Type Filter & Governorate Filter
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedClientType,
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(t('type_all'), style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'مستشفى', child: Text(t('type_hospital'), style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'عيادة', child: Text(t('type_clinic'), style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'مركز طبي', child: Text(t('type_center'), style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'شركة / معمل', child: Text(t('type_company'), style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) => setState(() => _selectedClientType = val!),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedGov,
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('جميع المحافظات', style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)),
                        ..._areas.map((a) {
                          final govName = a['name']?.toString() ?? 'محافظة';
                          return DropdownMenuItem(value: govName, child: Text(govName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis));
                        }),
                      ],
                      onChanged: (val) => setState(() => _selectedGov = val!),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 3: Add Client Button & Count Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _showAddClientModal,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: Text(t('add_client'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_filteredClients.length} / ${_clients.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F766E)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Clients List View
        Expanded(
          child: _filteredClients.isEmpty
              ? Center(child: Text(t('empty'), style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredClients.length,
                  itemBuilder: (context, index) {
                    final c = _filteredClients[index];
                    final phone = c['phone'] ?? 'غير معروف';

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    c['name'] ?? 'مستشفى طبي',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0F2FE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    c['type'] ?? 'مستشفى',
                                    style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${c['governorate'] ?? 'غير معروف'} / ${c['city'] ?? 'غير معروف'}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  phone,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 8,
                              spacing: 6,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showContactsModal(c),
                                  icon: const Icon(Icons.contacts, size: 14, color: Color(0xFF0D9488)),
                                  label: Text(t('contacts'), style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488))),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    side: const BorderSide(color: Color(0xFF0D9488)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _showAddressModal(c),
                                  icon: const Icon(Icons.map, size: 14, color: Colors.redAccent),
                                  label: Text(t('address'), style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    side: const BorderSide(color: Colors.redAccent),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      icon: const Icon(Icons.phone, color: Color(0xFF0D9488), size: 20),
                                      onPressed: () => _launchCall(phone),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(6),
                                      icon: const Icon(Icons.chat, color: Colors.green, size: 20),
                                      onPressed: () => _launchWhatsApp(phone),
                                    ),
                                  ],
                                ),
                              ],
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

  // 2. TAB: Field Visits & External Tasks
  Widget _buildVisitsTab() {
    if (_externalTasks.isEmpty) {
      return Center(child: Text(t('empty'), style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _externalTasks.length,
      itemBuilder: (context, index) {
        final task = _externalTasks[index];
        final isHigh = task['priority'] == 'High' || task['priority'] == 'عالي';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task['title'] ?? 'زيارة صيانة أجهزة طبية',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isHigh ? Colors.red[50] : Colors.teal[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isHigh ? Colors.red[200]! : Colors.teal[200]!),
                      ),
                      child: Text(
                        task['status'] ?? 'قيد المتابعة',
                        style: TextStyle(
                          color: isHigh ? Colors.red[700] : Colors.teal[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 16, color: Color(0xFF0D9488)),
                    const SizedBox(width: 6),
                    Text(
                      task['client_hospital'] ?? task['client']?['name'] ?? 'مستشفى العميل',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF334155)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task['description'] ?? '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 14),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (task['phone'] != null) ...[
                      OutlinedButton.icon(
                        onPressed: () => _launchCall(task['phone']),
                        icon: const Icon(Icons.phone, size: 14, color: Color(0xFF0D9488)),
                        label: Text(t('call'), style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488))),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _launchWhatsApp(task['phone']),
                        icon: const Icon(Icons.chat, size: 14, color: Colors.green),
                        label: Text(t('whatsapp'), style: const TextStyle(fontSize: 11, color: Colors.green)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => task['status'] = 'مكتملة');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تأكيد إنهاء الزيارة الميدانية'), backgroundColor: Colors.teal),
                        );
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 14, color: Colors.white),
                      label: const Text('تأكيد الإنجاز', style: TextStyle(fontSize: 11, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
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

  // 3. TAB: Quotations & Requests for Accountant
  Widget _buildQuotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Quotation Request Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Form(
              key: _quoteFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('create_quote'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),

                  DropdownButtonFormField(
                    value: _selectedQuoteClient,
                    hint: Text(t('select_client')),
                    items: _clients.map<DropdownMenuItem>((c) {
                      return DropdownMenuItem(value: c['id'], child: Text(c['name'].toString()));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedQuoteClient = val),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),

                  Text(t('select_products'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: _products.map((p) {
                        final pid = p['id'] as int;
                        final isChecked = _selectedProducts.contains(pid);
                        return CheckboxListTile(
                          value: isChecked,
                          title: Text(_getLocalizedName(p['name']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text('${p['price']} EGP', style: const TextStyle(fontSize: 11, color: Colors.teal)),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) _selectedProducts.add(pid);
                              else _selectedProducts.remove(pid);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _customItemController,
                    decoration: InputDecoration(labelText: t('custom_item'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _quoteAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: t('amount'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _quoteNotesController,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: t('notes'), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _submitQuotationRequest,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: Text(t('submit_quote'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Quotations Directory List
          const Text('سجل عروض الأسعار الصادرة والطلبات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          _quotations.isEmpty
              ? Center(child: Text(t('empty'), style: const TextStyle(color: Colors.grey)))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quotations.length,
                  itemBuilder: (context, index) {
                    final q = _quotations[index];
                    final status = q['status']?.toString() ?? 'pending';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFFCCFBF1), child: Icon(Icons.description, color: Color(0xFF0D9488))),
                        title: Text('${q['quotation_number'] ?? 'QT-2026'} - ${q['client']?['name'] ?? 'عميل'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${q['total_amount']} EGP - ${q['created_at']}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'approved' ? Colors.teal[50] : Colors.amber[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status == 'approved' ? 'موافق عليه' : 'قيد المراجعة',
                            style: TextStyle(color: status == 'approved' ? Colors.teal[800] : Colors.amber[800], fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  // 4. TAB: Invoices & Collections
  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) {
      return Center(child: Text(t('empty'), style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _invoices.length,
      itemBuilder: (context, index) {
        final inv = _invoices[index];
        final isPaid = inv['status'] == 'paid' || inv['status'] == 'مدفوعة';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isPaid ? Colors.teal[50] : Colors.red[50],
              child: Icon(Icons.receipt_long, color: isPaid ? Colors.teal : Colors.redAccent),
            ),
            title: Text('${inv['invoice_number']} - ${inv['client']?['name'] ?? inv['client_name'] ?? 'عميل'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text('المبلغ: ${inv['amount']} EGP | تاريخ الاستحقاق: ${inv['due_date'] ?? 'N/A'}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPaid ? Colors.teal[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isPaid ? 'مدفوعة' : 'غير مدفوعة',
                style: TextStyle(color: isPaid ? Colors.teal[800] : Colors.red[800], fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  // 5. TAB: Maintenance Reports
  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _reportFormKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('توثيق تقرير معايرة وإصلاح ميداني', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _deviceNameController,
                    validator: (v) => v == null || v.isEmpty ? 'حقل مطلوب' : null,
                    decoration: InputDecoration(labelText: 'اسم الجهاز الطبي المعاين*', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _serialNoController,
                    decoration: InputDecoration(labelText: 'الرقم التسلسلي (Serial No)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _faultDescController,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: 'وصف العطل أو الشكوى الميدانية', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _workDoneController,
                    maxLines: 2,
                    decoration: InputDecoration(labelText: 'الإجراءات الفنية والإصلاح المنفذ', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: _deviceStatus,
                    items: const [
                      DropdownMenuItem(value: 'operational', child: Text('يعمل بكفاءة وجاهز للخدمة')),
                      DropdownMenuItem(value: 'needs_parts', child: Text('يحتاج إلى قطع غيار إضافية')),
                      DropdownMenuItem(value: 'decommissioned', child: Text('خارج الخدمة نهائياً')),
                    ],
                    onChanged: (val) => setState(() => _deviceStatus = val!),
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _submitMaintenanceReport,
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(t('submit_report'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Reports History
          if (_reports.isNotEmpty) ...[
            const Text('سجل التقارير الفنية المحفوظة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reports.length,
              itemBuilder: (context, index) {
                final r = _reports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.assignment_turned_in, color: Color(0xFF0D9488)),
                    title: Text(r['device_name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('الرقم التسلسلي: ${r['serial_no']} - ${r['date']}'),
                    trailing: Text(r['status'].toString(), style: const TextStyle(fontSize: 10, color: Color(0xFF0D9488))),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
