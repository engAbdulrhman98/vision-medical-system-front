import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'admin_dashboard.dart';
import 'manager_dashboard.dart';
import 'accountant_dashboard.dart';
import 'seller_dashboard.dart';
import 'engineer_dashboard.dart';
import 'collector_dashboard.dart';
import 'notifications_screen.dart';
import 'package:vision_medical_system_app/services/notification_service.dart';
import 'package:vision_medical_system_app/services/db_helper.dart';

class DashboardScreen extends StatefulWidget {
  final String language;
  final Function(String) onLanguageChanged;
  final String email;
  final String token;
  final String backendUrl;
  final Map user;

  const DashboardScreen({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    required this.email,
    this.token = '',
    this.backendUrl = '',
    required this.user,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String _lang;
  String _activeRole = 'admin'; // active viewing role
  String _userRole = 'admin'; // actual logged-in user's role

  Timer? _notificationTimer;
  final Set<int> _shownNotificationIds = {};
  bool _isInitialFetch = true;

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'admin_portal': 'Admin Portal',
      'control_panel': 'Control Panel',
      'switch_role': 'Switch Board Role',
      'admin_role': 'Super Admin view',
      'engineer_role': 'Field Engineer view',
      'manager_role': 'Inventory Manager view',
      'accountant_role': 'Financial Accountant view',
      'collector_role': 'Collector view',
      'seller_role': 'Sales Representative view',
      'logout': 'Logout',
      'view_site': 'Website Store',
      'welcome': 'Welcome back,',
      'current_viewing': 'Current Mode:',
    },
    'ar': {
      'admin_portal': 'بوابة الإدارة العامة',
      'control_panel': 'لوحة التحكم والتحليل',
      'switch_role': 'تغيير لوحة العرض',
      'admin_role': 'واجهة المدير العام',
      'engineer_role': 'واجهة المهندس الميداني (الصيانة الخارجي)',
      'manager_role': 'واجهة مدير المستودع',
      'accountant_role': 'واجهة المحاسب المالي',
      'collector_role': 'واجهة المحصل',
      'seller_role': 'واجهة مندوب المبيعات',
      'logout': 'تسجيل الخروج',
      'view_site': 'الموقع الإلكتروني',
      'welcome': 'مرحباً بك مجدداً،',
      'current_viewing': 'الوضع الحالي:',
    }
  };

  String t(String key) {
    return _localized[_lang]?[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
    
    // Parse user role
    String rawRole = 'admin';
    if (widget.user['role'] != null) {
      rawRole = widget.user['role'].toString().toLowerCase();
    } else if (widget.user['roles'] is List && (widget.user['roles'] as List).isNotEmpty) {
      rawRole = (widget.user['roles'] as List)[0]['name'].toString().toLowerCase();
    }

    if (rawRole.contains('admin') || rawRole.contains('ceo')) {
      _userRole = 'admin';
    } else if (rawRole.contains('engineer') || rawRole.contains('outdoor') || rawRole.contains('indoor') || rawRole.contains('tech')) {
      _userRole = 'engineer';
    } else if (rawRole.contains('accountant')) {
      _userRole = 'accountant';
    } else if (rawRole.contains('collector')) {
      _userRole = 'collector';
    } else if (rawRole.contains('seller') || rawRole.contains('sales') || rawRole.contains('sale')) {
      _userRole = 'seller';
    } else if (rawRole.contains('manager') || rawRole.contains('operation')) {
      _userRole = 'manager';
    } else {
      _userRole = 'engineer'; // fallback
    }
    
    _activeRole = _userRole;
    
    _initNotifications();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initNotifications() async {
    if (widget.token.isNotEmpty && widget.backendUrl.isNotEmpty) {
      try {
        // Request notifications permission at startup
        await NotificationService.instance.requestPermissions();
      } catch (e) {
        debugPrint('Error requesting notification permissions: $e');
      }
      
      // Perform initial check to load existing notifications
      await _checkNewNotifications();
      
      // Check every 10 seconds for real-time notifications
      _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        _checkNewNotifications();
      });
    }
  }

  Future<void> _checkNewNotifications() async {
    if (widget.token.isEmpty || widget.backendUrl.isEmpty) return;
    
    try {
      final response = await http.get(
        Uri.parse('${widget.backendUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final rawJson = jsonDecode(response.body);
        final data = rawJson is Map ? (rawJson['data'] as List? ?? []) : (rawJson as List? ?? []);
        
        for (var item in data) {
          final int id = item['id'];
          final titleObj = item['title'];
          final messageObj = item['message'] ?? item['description'];
          
          String title = '';
          if (titleObj is Map) {
            title = titleObj[_lang] ?? titleObj['en'] ?? titleObj['ar'] ?? 'New Alert';
          } else {
            title = titleObj?.toString() ?? 'New Alert';
          }

          String message = '';
          if (messageObj is Map) {
            message = messageObj[_lang] ?? messageObj['en'] ?? messageObj['ar'] ?? '';
          } else {
            message = messageObj?.toString() ?? '';
          }
          
          final bool isUnread = item['read_at'] == null;
          
          if (isUnread) {
            if (!_shownNotificationIds.contains(id)) {
              _shownNotificationIds.add(id);
              
              // Only trigger system notifications after the initial fetch
              if (!_isInitialFetch) {
                await NotificationService.instance.showNotification(
                  id: id,
                  title: title,
                  body: message,
                );
              }
            }
          } else {
            // If it's read now, make sure it's in our shown list so we don't trigger it again
            _shownNotificationIds.add(id);
          }
        }
        
        _isInitialFetch = false;
      }
    } catch (e) {
      debugPrint('Error polling notifications: $e');
    }
  }

  void _toggleLanguage() {
    final nextLang = _lang == 'en' ? 'ar' : 'en';
    setState(() {
      _lang = nextLang;
    });
    widget.onLanguageChanged(nextLang);
  }

  void _logout() {
    _showLogoutConfirmation();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              _lang == 'ar' ? 'تسجيل الخروج' : 'Logout',
              style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold),
            ),
            content: Text(
              _lang == 'ar'
                  ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟'
                  : 'Are you sure you want to log out?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_lang == 'ar' ? 'إلغاء' : 'Cancel', style: TextStyle(color: Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  ChatDatabaseHelper.instance.deleteFromCache('active_session').then((_) {
                    if (mounted) {
                      navigator.pushReplacementNamed('/login');
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  _lang == 'ar' ? 'تسجيل الخروج' : 'Logout',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _lang == 'ar';
    final userDisplayName = widget.user['name'] ?? widget.email.split('@')[0];

    Widget dashboardContent;
    Color primaryColor = const Color(0xFF0D9488);
    Color secondaryColor = const Color(0xFF14B8A6);
    
    switch (_activeRole) {
      case 'admin':
        primaryColor = const Color(0xFF0F5132);
        secondaryColor = const Color(0xFF198754);
        dashboardContent = AdminDashboard(
          language: _lang,
          token: widget.token,
          backendUrl: widget.backendUrl,
          user: widget.user,
        );
        break;
      case 'manager':
        primaryColor = const Color(0xFF1E1B4B);
        secondaryColor = const Color(0xFF4338CA);
        dashboardContent = ManagerDashboard(
          language: _lang,
          token: widget.token,
          backendUrl: widget.backendUrl,
          user: widget.user,
        );
        break;
      case 'accountant':
        primaryColor = const Color(0xFF78350F);
        secondaryColor = const Color(0xFFD97706);
        dashboardContent = AccountantDashboard(
          language: _lang,
          token: widget.token,
          backendUrl: widget.backendUrl,
          user: widget.user,
        );
        break;
      case 'collector':
        primaryColor = const Color(0xFF92400E);
        secondaryColor = const Color(0xFFB45309);
        dashboardContent = CollectorDashboard(
          language: _lang,
          token: widget.token,
          backendUrl: widget.backendUrl,
          user: widget.user,
        );
        break;
      case 'engineer':
        primaryColor = const Color(0xFF0F766E);
        secondaryColor = const Color(0xFF0D9488);
        dashboardContent = EngineerDashboard(
          language: _lang,
          token: widget.token,
          backendUrl: widget.backendUrl,
          user: widget.user,
        );
        break;
      case 'seller':
        primaryColor = const Color(0xFF0E7490);
        secondaryColor = const Color(0xFF0891B2);
        dashboardContent = SellerDashboard(
          language: _lang,
          token: widget.token,
          backendUrl: widget.backendUrl,
          user: widget.user,
        );
        break;
      default:
        primaryColor = const Color(0xFF0D9488);
        secondaryColor = const Color(0xFF14B8A6);
        dashboardContent = ManagerDashboard(
          language: _lang,
          token: widget.token,
          backendUrl: widget.backendUrl,
          user: widget.user,
        );
    }

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          // Mimic native back button to send app to background (like WhatsApp/Facebook)
          SystemNavigator.pop();
        },
        child: Scaffold(
          drawer: Drawer(
            child: Column(
              children: [
                // Top Header User Card (Vision Control Panel Header)
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              child: Text(
                                userDisplayName.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userDisplayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.email,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          '${t('current_viewing')} ${_activeRole.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Website Style Categorized Navigation List (Filtered by User Role)
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // 1. Staff Conversations & Communication (ALL ROLES)
                      _buildSectionHeader(_lang == 'ar' ? 'محادثات الموظفين' : 'STAFF CONVERSATIONS', Colors.teal),
                      _buildDrawerTile(
                        title: _lang == 'ar' ? '💬 محادثات الموظفين' : 'Staff Conversations',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: Colors.teal,
                        badgeText: 'LIVE',
                        badgeColor: Colors.teal,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed(
                            '/chat',
                            arguments: {
                              'email': widget.email,
                              'token': widget.token,
                              'backendUrl': widget.backendUrl,
                            },
                          );
                        },
                      ),
                      _buildDrawerTile(
                        title: _lang == 'ar' ? '🔔 الإشعارات والتنبيهات' : 'Alerts & Notifications',
                        icon: Icons.notifications_active_outlined,
                        color: Colors.orange[800]!,
                        badgeText: _shownNotificationIds.isNotEmpty ? '${_shownNotificationIds.length}' : null,
                        badgeColor: Colors.red,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => NotificationsScreen(
                                language: _lang,
                                token: widget.token,
                                backendUrl: widget.backendUrl,
                              ),
                            ),
                          );
                        },
                      ),

                      // 2. Sales & Field Engineering (Admin, Engineer, Seller)
                      if (_userRole == 'admin' || _userRole == 'engineer' || _userRole == 'seller') ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Divider(height: 1),
                        ),
                        _buildSectionHeader(_lang == 'ar' ? 'المبيعات والصيانة الميدانية' : 'SALES & FIELD ENGINEERING', const Color(0xFF0F766E)),
                        if (_userRole == 'admin' || _userRole == 'engineer')
                          _buildDrawerTile(
                            title: _lang == 'ar' ? '🛠️ الصيانة الخارجية والميدانية' : 'External Maintenance Visits',
                            icon: Icons.handyman_rounded,
                            color: const Color(0xFF0F766E),
                            isSelected: _activeRole == 'engineer',
                            onTap: () {
                              setState(() { _activeRole = 'engineer'; });
                              Navigator.pop(context);
                            },
                          ),
                        if (_userRole == 'admin' || _userRole == 'seller')
                          _buildDrawerTile(
                            title: _lang == 'ar' ? '🏪 المبيعات وسجل العملاء' : 'Sales & Clients',
                            icon: Icons.people_alt_rounded,
                            color: const Color(0xFF0E7490),
                            isSelected: _activeRole == 'seller',
                            onTap: () {
                              setState(() { _activeRole = 'seller'; });
                              Navigator.pop(context);
                            },
                          ),
                        _buildDrawerTile(
                          title: _lang == 'ar' ? '📋 جدول التكليفات والمهام' : 'Tasks & Work Orders',
                          icon: Icons.assignment_outlined,
                          color: Colors.indigo,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).pushNamed(
                              '/tasks',
                              arguments: {
                                'email': widget.email,
                                'token': widget.token,
                                'backendUrl': widget.backendUrl,
                                'user': widget.user,
                              },
                            );
                          },
                        ),
                      ],

                      // 3. Reports & Financials (Admin, Accountant, Collector)
                      if (_userRole == 'admin' || _userRole == 'accountant' || _userRole == 'collector') ...[ 
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Divider(height: 1),
                        ),
                        _buildSectionHeader(_lang == 'ar' ? 'التقارير والماليات' : 'REPORTS & FINANCIALS', const Color(0xFF78350F)),
                        _buildDrawerTile(
                          title: _lang == 'ar' ? '🧾 الفواتير والتحصيل الميداني' : 'Invoices & Billing',
                          icon: Icons.receipt_long_rounded,
                          color: const Color(0xFF78350F),
                          isSelected: _activeRole == 'accountant',
                          onTap: () {
                            setState(() { _activeRole = 'accountant'; });
                            Navigator.pop(context);
                          },
                        ),
                        if (_userRole == 'admin' || _userRole == 'collector')
                          _buildDrawerTile(
                            title: _lang == 'ar' ? '💰 لوحة المحصل' : 'Collector Dashboard',
                            icon: Icons.account_balance_wallet_outlined,
                            color: const Color(0xFF92400E),
                            isSelected: _activeRole == 'collector',
                            onTap: () {
                              setState(() { _activeRole = 'collector'; });
                              Navigator.pop(context);
                            },
                          ),
                        _buildDrawerTile(
                          title: _lang == 'ar' ? '📊 التقارير المالية والتحليلية' : 'Financial & Maintenance Reports',
                          icon: Icons.pie_chart_outline_rounded,
                          color: Colors.purple[700]!,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(context).pushNamed(
                              '/reports',
                              arguments: {
                                'token': widget.token,
                                'backendUrl': widget.backendUrl,
                              },
                            );
                          },
                        ),
                      ],

                      // 4. Inventory Control & Medical Catalog (Admin, Manager)
                      if (_userRole == 'admin' || _userRole == 'manager') ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Divider(height: 1),
                        ),
                        _buildSectionHeader(_lang == 'ar' ? 'إدارة المستودع والمنتجات' : 'INVENTORY CONTROL', const Color(0xFF1E1B4B)),
                        _buildDrawerTile(
                          title: _lang == 'ar' ? '📦 كتالوج المنتجات الطبية والمخزون' : 'Medical Products & Catalog',
                          icon: Icons.inventory_2_rounded,
                          color: const Color(0xFF1E1B4B),
                          isSelected: _activeRole == 'manager',
                          onTap: () {
                            setState(() { _activeRole = 'manager'; });
                            Navigator.pop(context);
                          },
                        ),
                      ],

                      // 5. Administrator Portal (Admin Only)
                      if (_userRole == 'admin') ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Divider(height: 1),
                        ),
                        _buildSectionHeader(_lang == 'ar' ? 'المدير العام' : 'ADMINISTRATOR', const Color(0xFF0F5132)),
                        _buildDrawerTile(
                          title: _lang == 'ar' ? 'لوحة التحكم والإدارة العامة' : 'Super Admin Control Panel',
                          icon: Icons.admin_panel_settings_rounded,
                          color: const Color(0xFF0F5132),
                          isSelected: _activeRole == 'admin',
                          onTap: () {
                            setState(() { _activeRole = 'admin'; });
                            Navigator.pop(context);
                          },
                        ),
                      ],

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Divider(height: 1),
                      ),

                      // 6. Language & Session
                      _buildDrawerTile(
                        title: _lang == 'ar' ? 'English Language' : 'اللغة العربية',
                        icon: Icons.translate_rounded,
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleLanguage();
                        },
                      ),
                      _buildDrawerTile(
                        title: t('logout'),
                        icon: Icons.logout_rounded,
                        color: Colors.red[700]!,
                        onTap: _logout,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          appBar: AppBar(
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('admin_portal'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, letterSpacing: 0.3),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${t('current_viewing')} ${_activeRole.toUpperCase()}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_outlined, size: 18),
                    ),
                    if (_shownNotificationIds.isNotEmpty)
                      Positioned(
                        top: -1,
                        right: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(
                        language: _lang,
                        token: widget.token,
                        backendUrl: widget.backendUrl,
                      ),
                    ),
                  );
                },
                tooltip: _lang == 'ar' ? 'التنبيهات والإشعارات' : 'Notifications',
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/chat',
                    arguments: {
                      'email': widget.email,
                      'token': widget.token,
                      'backendUrl': widget.backendUrl,
                    },
                  );
                },
                tooltip: _lang == 'ar' ? 'المحادثات' : 'Chats',
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.translate_rounded, size: 18),
                ),
                onPressed: _toggleLanguage,
                tooltip: _lang == 'ar' ? 'English' : 'العربية',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (widget.token.isEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[800]!, Colors.orange[900]!],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _lang == 'ar'
                                ? 'وضع عدم الاتصال بالخادم: يتم استخدام البيانات المحفوظة محلياً.'
                                : 'Offline Mode: Using cached local data.',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(child: dashboardContent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Colors.blueGrey[700],
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isSelected = false,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5) : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : color, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? color : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13.5,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (badgeColor ?? color).withValues(alpha: 0.4)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor ?? color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 16)
            else
              const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
