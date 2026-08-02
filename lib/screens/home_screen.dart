import 'package:flutter/material.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  final String language;
  final Function(String) onLanguageChanged;
  final String email;
  final String token;
  final String backendUrl;

  const HomeScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.email,
    this.token = '',
    this.backendUrl = '',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class DeviceItem {
  final String id;
  final String name;
  final String category;
  final String location;
  final String status; // 'Operational', 'Maintenance', 'Offline'
  final String serial;

  DeviceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.status,
    required this.serial,
  });
}

class MaintenanceTicket {
  final String ticketId;
  final String deviceName;
  final String issue;
  final String priority; // 'Low', 'Medium', 'High'
  final String status; // 'Pending', 'In Progress', 'Completed'
  final String date;

  MaintenanceTicket({
    required this.ticketId,
    required this.deviceName,
    required this.issue,
    required this.priority,
    required this.status,
    required this.date,
  });
}

class _HomeScreenState extends State<HomeScreen> {
  late String _lang;
  int _currentIndex = 0;
  String _facilityName = '';
  String _employeeName = '';
  String _employeeEmail = '';
  String _employeeRole = '';
  String _employeePhone = '';

  // Local state for interactive ticket submissions
  final List<DeviceItem> _devices = [
    DeviceItem(id: '1', name: 'Optima MR450 MRI Scanner', category: 'Radiology', location: 'Room A-102', status: 'Operational', serial: 'SN-MRI-88402'),
    DeviceItem(id: '2', name: 'Vivid E90 Ultrasound', category: 'Cardiology', location: 'ICU Ward B', status: 'Operational', serial: 'SN-ULS-11938'),
    DeviceItem(id: '3', name: 'Engström Carestation Ventilator', category: 'Critical Care', location: 'ICU Room 4', status: 'Maintenance', serial: 'SN-VEN-44201'),
    DeviceItem(id: '4', name: 'Defibtech Lifeline ECG', category: 'Emergency', location: 'ER Room 2', status: 'Operational', serial: 'SN-DFB-33928'),
    DeviceItem(id: '5', name: 'Brivo XR X-Ray Machine', category: 'Radiology', location: 'Imaging Center 3', status: 'Offline', serial: 'SN-XRY-77501'),
  ];

  final List<MaintenanceTicket> _tickets = [
    MaintenanceTicket(ticketId: 'TKT-991', deviceName: 'Engström Carestation Ventilator', issue: 'Oxygen sensor calibration error', priority: 'High', status: 'In Progress', date: '2026-07-07'),
    MaintenanceTicket(ticketId: 'TKT-992', deviceName: 'Brivo XR X-Ray Machine', issue: 'Collimator rotation failure', priority: 'High', status: 'Pending', date: '2026-07-08'),
  ];

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'title': 'Vision Medical Dashboard',
      'welcome': 'Welcome back,',
      'nav_overview': 'Overview',
      'nav_catalog': 'Equipment',
      'nav_service': 'Maintenance',
      'nav_chat': 'Chats',
      'nav_settings': 'Settings',
      'stat_total': 'Total Assets',
      'stat_operational': 'Operational',
      'stat_maintenance': 'In Service',
      'stat_offline': 'Offline',
      'recent_activities': 'Recent Service Logs',
      'quick_actions': 'Quick Actions',
      'act_request': 'Request Service',
      'act_catalog': 'View Catalog',
      'act_add': 'Add Device',
      'search_placeholder': 'Search medical equipment...',
      'serial': 'Serial Number',
      'location': 'Location',
      'department': 'Department',
      'status': 'Status',
      'request_service_btn': 'Request Maintenance',
      'service_portal': 'Service Requests Portal',
      'new_ticket': 'New Service Ticket',
      'device_label': 'Select Device',
      'issue_label': 'Description of Issue',
      'issue_empty': 'Please describe the issue',
      'priority_label': 'Priority Level',
      'contact_label': 'Biomedical Engineer in Charge',
      'submit_ticket': 'Submit Service Ticket',
      'success_ticket': 'Maintenance ticket submitted successfully!',
      'ticket_list': 'Active Service Tickets',
      'ticket_id': 'Ticket ID',
      'ticket_date': 'Date Created',
      'priority_high': 'High',
      'priority_medium': 'Medium',
      'priority_low': 'Low',
      'status_pending': 'Pending',
      'status_inprogress': 'In Progress',
      'status_completed': 'Completed',
      'settings_title': 'Settings',
      'employee_profile': 'Employee Account Details',
      'employee_name': 'Full Name',
      'employee_role': 'Job Role',
      'employee_email': 'Email Address',
      'employee_phone': 'Phone Number',
      'company_info': 'Vision Medical Co.',
      'company_desc': 'Supplier and Authorized Service Partner for Premium Medical Devices.',
      'tech_support': 'Emergency Technical Support',
      'tech_support_val': '19999 (Hotline)',
      'logout': 'Logout',
    },
    'ar': {
      'title': 'لوحة تحكم الأجهزة الطبية',
      'welcome': 'مرحباً بك مجدداً،',
      'nav_overview': 'الرئيسية',
      'nav_catalog': 'الأجهزة الطبية',
      'nav_service': 'الصيانة',
      'nav_chat': 'المحادثات',
      'nav_settings': 'الإعدادات',
      'stat_total': 'إجمالي الأجهزة',
      'stat_operational': 'جاهز للعمل',
      'stat_maintenance': 'قيد الصيانة',
      'stat_offline': 'خارج الخدمة',
      'recent_activities': 'سجل النشاطات الأخيرة',
      'quick_actions': 'إجراءات سريعة',
      'act_request': 'طلب صيانة',
      'act_catalog': 'عرض الكتالوج',
      'act_add': 'إضافة جهاز جديد',
      'search_placeholder': 'البحث عن أجهزة ومعدات...',
      'serial': 'الرقم التسلسلي',
      'location': 'الموقع / الغرفة',
      'department': 'القسم الطبي',
      'status': 'الحالة التشغيلية',
      'request_service_btn': 'طلب صيانة للجهاز',
      'service_portal': 'بوابة طلبات الصيانة والخدمات',
      'new_ticket': 'إنشاء طلب صيانة جديد',
      'device_label': 'اختر الجهاز الطبي',
      'issue_label': 'وصف العطل بالتفصيل',
      'issue_empty': 'يرجى كتابة وصف للعطل',
      'priority_label': 'مستوى الأهمية / الأولوية',
      'contact_label': 'المهندس المسؤول بالمستشفى',
      'submit_ticket': 'إرسال طلب الصيانة',
      'success_ticket': 'تم تسجيل طلب الصيانة بنجاح في النظام!',
      'ticket_list': 'طلبات الصيانة النشطة الآن',
      'ticket_id': 'رقم الطلب',
      'ticket_date': 'تاريخ الإنشاء',
      'priority_high': 'عالي الخطورة',
      'priority_medium': 'متوسط',
      'priority_low': 'منخفض',
      'status_pending': 'قيد الانتظار',
      'status_inprogress': 'جاري العمل',
      'status_completed': 'تمت الصيانة',
      'settings_title': 'الإعدادات والملف الشخصي',
      'employee_profile': 'بيانات حساب الموظف',
      'employee_name': 'الاسم الكامل',
      'employee_role': 'المسمى الوظيفي',
      'employee_email': 'البريد الإلكتروني',
      'employee_phone': 'رقم الهاتف',
      'company_info': 'شركة نظام فيجن ميدكال للأجهزة الطبية',
      'company_desc': 'المورد والوكيل المعتمد لخدمات الصيانة والتركيب للأجهزة الطبية الممتازة.',
      'tech_support': 'طوارئ الصيانة والدعم الفني للشركة',
      'tech_support_val': '19999 (الخط الساخن)',
      'logout': 'تسجيل الخروج',
    }
  };

  // Form controllers for new ticket submission
  final _formKey = GlobalKey<FormState>();
  String? _selectedDeviceForTicket;
  final TextEditingController _issueController = TextEditingController();
  String _selectedPriority = 'High';
  final TextEditingController _contactController = TextEditingController();

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
    _facilityName = _lang == 'ar' ? 'مستشفى القاهرة العام' : 'Cairo General Hospital';
    
    // Initialize employee details
    _employeeName = widget.email.contains('@') 
        ? widget.email.split('@')[0] 
        : widget.email;
    if (_employeeName.isNotEmpty) {
      _employeeName = _employeeName[0].toUpperCase() + _employeeName.substring(1);
    }
    _employeeEmail = widget.email.contains('@') ? widget.email : 'employee@visionmedical.com';
    _employeeRole = _lang == 'ar' ? 'مهندس أجهزة طبية' : 'Biomedical Engineer';
    _employeePhone = '+20 10 1234 5678';

    if (_devices.isNotEmpty) {
      _selectedDeviceForTicket = _devices.first.name;
    }
  }

  String t(String key) {
    return _localized[_lang]?[key] ?? key;
  }

  void _toggleLanguage() {
    final newLang = _lang == 'en' ? 'ar' : 'en';
    setState(() {
      _lang = newLang;
      if (_facilityName == 'Cairo General Hospital') {
        _facilityName = 'مستشفى القاهرة العام';
      } else if (_facilityName == 'مستشفى القاهرة العام') {
        _facilityName = 'Cairo General Hospital';
      }
    });
    widget.onLanguageChanged(newLang);
  }

  void _submitTicket() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        final ticketId = 'TKT-${_tickets.length + 991}';
        _tickets.add(
          MaintenanceTicket(
            ticketId: ticketId,
            deviceName: _selectedDeviceForTicket ?? 'General Device',
            issue: _issueController.text,
            priority: _selectedPriority,
            status: 'Pending',
            date: DateTime.now().toString().split(' ')[0],
          ),
        );

        // Update the target device status to Maintenance
        final idx = _devices.indexWhere((d) => d.name == _selectedDeviceForTicket);
        if (idx != -1) {
          final oldDev = _devices[idx];
          _devices[idx] = DeviceItem(
            id: oldDev.id,
            name: oldDev.name,
            category: oldDev.category,
            location: oldDev.location,
            status: 'Maintenance',
            serial: oldDev.serial,
          );
        }

        _issueController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('success_ticket')),
          backgroundColor: Colors.teal[800],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _lang == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Colors.teal[800],
          title: Row(
            children: [
              const Icon(Icons.settings_input_component, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                t('title'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/notifications',
                      arguments: {
                        'token': widget.token,
                        'backendUrl': widget.backendUrl,
                      },
                    );
                  },
                  tooltip: _lang == 'ar' ? 'التنبيهات' : 'Notifications',
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _toggleLanguage,
              icon: const Icon(Icons.language, color: Colors.white),
              label: Text(
                _lang == 'en' ? 'العربية' : 'English',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: _buildCurrentTab(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.teal[800],
          unselectedItemColor: Colors.grey[600],
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: t('nav_overview'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.inventory_2_outlined),
              activeIcon: const Icon(Icons.inventory_2),
              label: t('nav_catalog'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.build_circle_outlined),
              activeIcon: const Icon(Icons.build_circle),
              label: t('nav_service'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.chat_outlined),
              activeIcon: const Icon(Icons.chat),
              label: t('nav_chat'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: t('nav_settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_currentIndex) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildCatalogTab();
      case 2:
        return _buildServiceTab();
      case 3:
        return _buildChatTab();
      case 4:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  // 1. OVERVIEW TAB
  Widget _buildOverviewTab() {
    final operationalCount = _devices.where((d) => d.status == 'Operational').length;
    final maintenanceCount = _devices.where((d) => d.status == 'Maintenance').length;
    final offlineCount = _devices.where((d) => d.status == 'Offline').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[800]!, Colors.teal[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('welcome'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _employeeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _facilityName,
                  style: const TextStyle(color: Colors.tealAccent, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Statistics Row
          Text(
            '${t('stat_total')}: ${_devices.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(t('stat_operational'), operationalCount.toString(), Colors.green, Icons.check_circle_outline),
              const SizedBox(width: 8),
              _buildStatCard(t('stat_maintenance'), maintenanceCount.toString(), Colors.orange, Icons.build_outlined),
              const SizedBox(width: 8),
              _buildStatCard(t('stat_offline'), offlineCount.toString(), Colors.red, Icons.error_outline),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions
          Text(
            t('quick_actions'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickActionButton(
                icon: Icons.build,
                label: t('act_request'),
                onTap: () {
                  setState(() {
                    _currentIndex = 2; // Switch to maintenance tab
                  });
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionButton(
                icon: Icons.inventory_2,
                label: t('act_catalog'),
                onTap: () {
                  setState(() {
                    _currentIndex = 1; // Switch to catalog
                  });
                },
              ),
              const SizedBox(width: 12),
              _buildQuickActionButton(
                icon: Icons.assessment_outlined,
                label: _lang == 'ar' ? 'التقارير' : 'Reports',
                onTap: () {
                  Navigator.pushNamed(context, '/reports');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Service Logs
          Text(
            t('recent_activities'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tickets.length,
            itemBuilder: (context, index) {
              final ticket = _tickets[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ticket.status == 'Pending'
                        ? Colors.red[50]
                        : Colors.orange[50],
                    child: Icon(
                      ticket.status == 'Pending' ? Icons.warning_amber : Icons.engineering,
                      color: ticket.status == 'Pending' ? Colors.red : Colors.orange,
                    ),
                  ),
                  title: Text(
                    ticket.deviceName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(ticket.issue, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('${t('ticket_id')}: ${ticket.ticketId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(width: 12),
                          Text(ticket.date, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: ticket.status == 'Pending' ? Colors.red[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ticket.status == 'Pending' ? t('status_pending') : t('status_inprogress'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ticket.status == 'Pending' ? Colors.red[800] : Colors.orange[800],
                      ),
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

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.teal[800], size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.teal[900],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. CATALOG TAB
  Widget _buildCatalogTab() {
    final filtered = _devices.where((d) {
      final nameMatches = d.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final serialMatches = d.serial.toLowerCase().contains(_searchQuery.toLowerCase());
      final catMatches = d.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || serialMatches || catMatches;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search box
          TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: t('search_placeholder'),
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final device = filtered[index];
                Color statusColor;
                String localizedStatus;

                if (device.status == 'Operational') {
                  statusColor = Colors.green;
                  localizedStatus = t('stat_operational');
                } else if (device.status == 'Maintenance') {
                  statusColor = Colors.orange;
                  localizedStatus = t('stat_maintenance');
                } else {
                  statusColor = Colors.red;
                  localizedStatus = t('stat_offline');
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.devices_other, color: statusColor, size: 20),
                    ),
                    title: Text(
                      device.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text('${t('location')}: ${device.location}', style: const TextStyle(fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
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
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            _buildInfoRow(t('serial'), device.serial),
                            _buildInfoRow(t('department'), device.category),
                            _buildInfoRow(t('location'), device.location),
                            _buildInfoRow(t('status'), localizedStatus),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedDeviceForTicket = device.name;
                                    _currentIndex = 2; // Jump to service ticket creation page
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[800],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.build, color: Colors.white, size: 16),
                                label: Text(
                                  t('request_service_btn'),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
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
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  // 3. SERVICE TAB
  Widget _buildServiceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card for active portal
            Card(
              color: Colors.teal[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.build_circle, color: Colors.teal[800], size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('service_portal'),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal[900]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('hospital_name_val'),
                            style: TextStyle(fontSize: 12, color: Colors.teal[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // New Ticket Form Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t('new_ticket'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[900]),
                  ),
                  const SizedBox(height: 16),

                  // Select Device Dropdown
                  Text(t('device_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDeviceForTicket,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      fillColor: Colors.grey[50],
                      filled: true,
                    ),
                    items: _devices.map((device) {
                      return DropdownMenuItem<String>(
                        value: device.name,
                        child: Text(device.name, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedDeviceForTicket = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description of issue
                  Text(t('issue_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _issueController,
                    maxLines: 3,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return t('issue_empty');
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: Colors.grey[50],
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Priority level selectors
                  Text(t('priority_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPriorityButton('High', t('priority_high'), Colors.red),
                      const SizedBox(width: 8),
                      _buildPriorityButton('Medium', t('priority_medium'), Colors.orange),
                      const SizedBox(width: 8),
                      _buildPriorityButton('Low', t('priority_low'), Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact engineer name input
                  Text(t('contact_label'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _contactController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      fillColor: Colors.grey[50],
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  ElevatedButton(
                    onPressed: _submitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      t('submit_ticket'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildPriorityButton(String value, String label, Color color) {
    final isSelected = _selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPriority = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // 4. SETTINGS TAB
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medical Profile Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.teal[50],
                        radius: 28,
                        child: Icon(Icons.person, color: Colors.teal[800], size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('employee_profile'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
                            ),
                            const SizedBox(height: 4),
                            Text(_employeeEmail, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.teal[800]),
                        onPressed: _showEditAccountDialog,
                        tooltip: _lang == 'ar' ? 'تعديل البيانات' : 'Edit Details',
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildProfileField(t('employee_name'), _employeeName),
                  _buildProfileField(t('employee_role'), _employeeRole),
                  _buildProfileField(t('employee_phone'), _employeePhone),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Settings Language Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.language, color: Colors.teal[800]),
                    const SizedBox(width: 12),
                    Text(
                      _lang == 'en' ? 'App Language' : 'لغة التطبيق',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _toggleLanguage,
                  child: Text(
                    _lang == 'en' ? 'العربية' : 'English',
                    style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog() {
    final nameController = TextEditingController(text: _employeeName);
    final emailController = TextEditingController(text: _employeeEmail);
    final roleController = TextEditingController(text: _employeeRole);
    final phoneController = TextEditingController(text: _employeePhone);

    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              _lang == 'ar' ? 'تعديل بيانات الحساب الشخصي' : 'Edit Personal Account Details',
              style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t('employee_name')}:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal[800]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${t('employee_email')}:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal[800]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${t('employee_role')}:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: roleController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal[800]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${t('employee_phone')}:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal[800]!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_lang == 'ar' ? 'إلغاء' : 'Cancel', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _employeeName = nameController.text.trim();
                    _employeeEmail = emailController.text.trim();
                    _employeeRole = roleController.text.trim();
                    _employeePhone = phoneController.text.trim();
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _lang == 'ar'
                            ? 'تم تحديث بيانات الحساب الشخصي بنجاح!'
                            : 'Personal account details updated successfully!',
                      ),
                      backgroundColor: Colors.teal[800],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_lang == 'ar' ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatTab() {
    return ChatScreen(
      language: _lang,
      email: widget.email,
      token: widget.token,
      backendUrl: widget.backendUrl,
      isEmbed: true,
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }
}
