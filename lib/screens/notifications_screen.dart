import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vision_medical_system_app/services/db_helper.dart';

class AppNotification {
  final int id;
  final String title;
  final String description;
  final bool isRead;
  final String time;
  final String type; // 'task', 'chat', 'report', 'system'

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.isRead,
    required this.time,
    required this.type,
  });
}

class NotificationsScreen extends StatefulWidget {
  final String language;
  final String token;
  final String backendUrl;

  const NotificationsScreen({
    super.key,
    required this.language,
    this.token = '',
    this.backendUrl = '',
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late String _lang;
  bool _isLoading = false;
  List<AppNotification> _notifications = [];

  final List<AppNotification> _mockNotifications = [
    AppNotification(
      id: 101,
      title: 'طلب عرض سعر جديد (QT-2026-008)',
      description: 'قام المهندس بإرسال طلب عرض سعر جديد للعميل مستشفى السلام. يرجى المراجعة والتسعير.',
      isRead: false,
      time: 'منذ 5 دقائق',
      type: 'quote',
    ),
    AppNotification(
      id: 102,
      title: 'اعتماد عرض سعر (QT-2026-005)',
      description: 'تم تسعير واعتماد عرض السعر الخاص بالعميل مركز النيل للأشعة بنجاح.',
      isRead: false,
      time: 'منذ ساعتين',
      type: 'quote',
    ),
    AppNotification(
      id: 1,
      title: 'مهمة صيانة جديدة',
      description: 'تم إسناد مهمة جديدة: معايرة أجهزة السونار والرنين المغناطيسي.',
      isRead: false,
      time: 'منذ ساعة',
      type: 'task',
    ),
    AppNotification(
      id: 2,
      title: 'رسالة جديدة من المحاسب',
      description: 'أستاذ محمود (المحاسب المالي): "تم إصدار الفاتورة المطلوبة."',
      isRead: true,
      time: 'أمس',
      type: 'chat',
    ),
  ];

  final Map<String, Map<String, String>> _localized = {
    'en': {
      'title': 'Notifications',
      'empty': 'No notifications yet',
      'empty_sub': 'We will notify you when something happens.',
      'mark_all_read': 'Mark all as read',
      'delete_all': 'Clear all',
      'status_unread': 'Unread',
      'success_read_all': 'All notifications marked as read',
      'success_read_single': 'Notification marked as read',
      'success_delete': 'Notification deleted',
      'offline_msg': 'Working offline. Actions performed locally.',
    },
    'ar': {
      'title': 'التنبيهات والإشعارات',
      'empty': 'لا توجد تنبيهات جديدة حالياً',
      'empty_sub': 'سنقوم بإشعارك فور حدوث أي نشاط جديد.',
      'mark_all_read': 'تحديد الكل كمقروء',
      'delete_all': 'مسح الكل',
      'status_unread': 'غير مقروء',
      'success_read_all': 'تم تحديد جميع التنبيهات كمقروءة',
      'success_read_single': 'تم قراءة التنبيه',
      'success_delete': 'تم حذف التنبيه بنجاح',
      'offline_msg': 'تعمل دون اتصال. تم تنفيذ الإجراء محلياً.',
    }
  };

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
    _fetchNotifications();
  }

  String t(String key) {
    return _localized[_lang]?[key] ?? key;
  }

  Future<void> _fetchNotifications() async {
    if (widget.token.isEmpty) {
      setState(() {
        _notifications = List.from(_mockNotifications);
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool showedOfflineToast = false;
    void showOfflineToast() {
      if (!showedOfflineToast && mounted) {
        showedOfflineToast = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _lang == 'ar'
                  ? 'وضع عدم الاتصال: يتم عرض البيانات المخزنة مؤقتاً'
                  : 'Offline mode: displaying cached data',
            ),
            backgroundColor: Colors.amber[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    dynamic rawJson;
    try {
      final response = await http.get(
        Uri.parse('${widget.backendUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        await ChatDatabaseHelper.instance.saveToCache('user_notifications', response.body);
        rawJson = jsonDecode(response.body);
      } else {
        throw Exception();
      }
    } catch (_) {
      showOfflineToast();
      final cached = await ChatDatabaseHelper.instance.getFromCache('user_notifications');
      if (cached != null) {
        rawJson = jsonDecode(cached);
      }
    }

    if (rawJson != null) {
      final data = rawJson is Map ? (rawJson['data'] as List? ?? []) : (rawJson as List? ?? []);
      final List<AppNotification> loaded = [];

      for (var item in data) {
        final int id = item['id'];
        final titleObj = item['title'];
        final messageObj = item['message'] ?? item['description'];

        String title = '';
        if (titleObj is Map) {
          title = titleObj[_lang] ?? titleObj['en'] ?? titleObj['ar'] ?? (_lang == 'ar' ? 'تنبيه جديد' : 'New Notification');
        } else {
          title = titleObj?.toString() ?? (_lang == 'ar' ? 'تنبيه جديد' : 'New Notification');
        }

        String description = '';
        if (messageObj is Map) {
          description = messageObj[_lang] ?? messageObj['en'] ?? messageObj['ar'] ?? '';
        } else {
          description = messageObj?.toString() ?? '';
        }

        final bool isRead = item['read_at'] != null;
        final String time = _formatTimeString(item['created_at']);
        
        String type = 'system';
        final notifType = item['type']?.toString() ?? '';
        if (notifType == 'quotation_request' || notifType == 'quotation_updated' || (item['data'] is Map && item['data']['quotation_id'] != null)) {
          type = 'quote';
        } else if (notifType == 'invoice_requested' || notifType == 'invoice_issued' || (item['data'] is Map && item['data']['invoice_request_id'] != null)) {
          type = 'invoice';
        } else if (item['task_id'] != null) {
          type = 'task';
        } else if (item['maintenance_report_id'] != null) {
          type = 'report';
        } else if (title.toLowerCase().contains('message') || title.toLowerCase().contains('chat')) {
          type = 'chat';
        }

        loaded.add(
          AppNotification(
            id: id,
            title: title,
            description: description,
            isRead: isRead,
            time: time,
            type: type,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _notifications = loaded;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _notifications = List.from(_mockNotifications);
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimeString(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final difference = DateTime.now().difference(dateTime);
      
      if (difference.inMinutes < 60) {
        return _lang == 'ar' ? 'منذ ${difference.inMinutes} دقيقة' : '${difference.inMinutes} mins ago';
      } else if (difference.inHours < 24) {
        return _lang == 'ar' ? 'منذ ${difference.inHours} ساعة' : '${difference.inHours} hours ago';
      } else {
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }

  Future<void> _markAsRead(int index) async {
    final notification = _notifications[index];
    if (notification.isRead) return;

    setState(() {
      _notifications[index] = AppNotification(
        id: notification.id,
        title: notification.title,
        description: notification.description,
        isRead: true,
        time: notification.time,
        type: notification.type,
      );
    });

    if (widget.token.isEmpty) return;

    try {
      await http.patch(
        Uri.parse('${widget.backendUrl}/notifications/${notification.id}/read'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    bool hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = AppNotification(
          id: _notifications[i].id,
          title: _notifications[i].title,
          description: _notifications[i].description,
          isRead: true,
          time: _notifications[i].time,
          type: _notifications[i].type,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('success_read_all')),
        backgroundColor: Colors.teal[800],
      ),
    );

    if (widget.token.isEmpty) return;

    try {
      await http.post(
        Uri.parse('${widget.backendUrl}/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );
    } catch (_) {}
  }

  Future<void> _deleteNotification(int index) async {
    final notification = _notifications[index];
    
    setState(() {
      _notifications.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t('success_delete')),
        backgroundColor: Colors.teal[800],
        action: SnackBarAction(
          label: _lang == 'ar' ? 'تراجع' : 'Undo',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _notifications.insert(index, notification);
            });
          },
        ),
      ),
    );

    if (widget.token.isEmpty) return;

    try {
      await http.delete(
        Uri.parse('${widget.backendUrl}/notifications/${notification.id}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );
    } catch (_) {}
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'quote':
        return Icons.request_quote_outlined;
      case 'invoice':
        return Icons.receipt_long_outlined;
      case 'task':
        return Icons.assignment_outlined;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'report':
        return Icons.assessment_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'quote':
        return const Color(0xFF10B981);
      case 'invoice':
        return Colors.teal;
      case 'task':
        return Colors.blue;
      case 'chat':
        return Colors.indigo;
      case 'report':
        return Colors.amber;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _lang == 'ar';
    final hasUnread = _notifications.any((n) => !n.isRead);

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
          actions: [
            if (hasUnread)
              IconButton(
                icon: const Icon(Icons.done_all, color: Colors.white),
                tooltip: t('mark_all_read'),
                onPressed: _markAllAsRead,
              ),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.teal[800]))
            : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          t('empty'),
                          style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          t('empty_sub'),
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];

                      return Dismissible(
                        key: Key('notif_${notif.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red[800],
                          alignment: isRTL ? Alignment.centerLeft : Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (dir) => _deleteNotification(index),
                        child: GestureDetector(
                          onTap: () => _markAsRead(index),
                          child: Card(
                            elevation: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: notif.isRead ? Colors.white : Colors.teal[50]?.withValues(alpha: 0.3),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Colored icon background depending on type
                                  CircleAvatar(
                                    backgroundColor: _getColorForType(notif.type).withValues(alpha: 0.1),
                                    radius: 20,
                                    child: Icon(
                                      _getIconForType(notif.type),
                                      color: _getColorForType(notif.type),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif.title,
                                                style: TextStyle(
                                                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                                  fontSize: 14,
                                                  color: const Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                            // Blue unread indicator dot
                                            if (!notif.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif.description,
                                          style: TextStyle(
                                            color: notif.isRead ? Colors.grey[650] : Colors.black87,
                                            fontSize: 13,
                                            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notif.time,
                                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
