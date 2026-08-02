import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/db_helper.dart';

class ChatConversation {
  final int id;
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isGroup;

  ChatConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isGroup,
  });
}

class ChatMessage {
  final int id;
  final int conversationId;
  final String senderName;
  final bool isMe;
  final String body;
  final String time;
  final String status; // 'sent', 'pending', 'failed'

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderName,
    required this.isMe,
    required this.body,
    required this.time,
    this.status = 'sent',
  });
}

class ChatScreen extends StatefulWidget {
  final String language;
  final String email;
  final String token;
  final String backendUrl;
  final bool isEmbed;

  const ChatScreen({
    super.key,
    required this.language,
    required this.email,
    this.token = '',
    this.backendUrl = '',
    this.isEmbed = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String _lang;
  int? _activeConversationId;
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  final TextEditingController _chatInputController = TextEditingController();
  String _searchQuery = '';
  String _employeeName = '';

  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];

  final List<ChatConversation> _mockConversations = [
    ChatConversation(
      id: 1,
      name: 'Engineer Ahmad',
      lastMessage: 'Yes, I just uploaded it. Please review and approve it.',
      time: '10:45 AM',
      unreadCount: 1,
      isGroup: false,
    ),
    ChatConversation(
      id: 2,
      name: 'Maintenance Group',
      lastMessage: 'Technician Ali: I will check the X-Ray device tomorrow.',
      time: 'Yesterday',
      unreadCount: 0,
      isGroup: true,
    ),
  ];

  final List<ChatMessage> _mockMessages = [
    ChatMessage(
      id: 1,
      conversationId: 1,
      senderName: 'Engineer Ahmad',
      isMe: false,
      body: 'Hello Admin, I have finished calibrating the ultrasound device at Nasr City Clinic.',
      time: '10:30 AM',
    ),
    ChatMessage(
      id: 2,
      conversationId: 1,
      senderName: 'Test User',
      isMe: true,
      body: 'Great work, Ahmad. Did you submit the maintenance report?',
      time: '10:35 AM',
    ),
    ChatMessage(
      id: 3,
      conversationId: 1,
      senderName: 'Engineer Ahmad',
      isMe: false,
      body: 'Yes, I just uploaded it. Please review and approve it.',
      time: '10:45 AM',
    ),
    ChatMessage(
      id: 4,
      conversationId: 2,
      senderName: 'Technician Ali',
      isMe: false,
      body: 'I will check the X-Ray device tomorrow.',
      time: 'Yesterday',
    ),
  ];

  Timer? _conversationTimer;
  Timer? _messageTimer;
  bool _isSyncingPending = false;

  void _startConversationTimer() {
    _conversationTimer?.cancel();
    _conversationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchConversations(silent: true);
      _syncPendingMessages();
    });
  }

  void _stopConversationTimer() {
    _conversationTimer?.cancel();
    _conversationTimer = null;
  }

  void _startMessageTimer(int conversationId) {
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessagesFromServerOnly(conversationId);
      _syncPendingMessages();
    });
  }

  void _stopMessageTimer() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  Future<void> _loadMessagesFromDb(int conversationId) async {
    final cached = await ChatDatabaseHelper.instance.getMessages(conversationId);
    if (mounted && _activeConversationId == conversationId) {
      setState(() {
        _messages = cached;
      });
    }
  }

  Future<void> _fetchConversationsFromDb() async {
    final cached = await ChatDatabaseHelper.instance.getConversations();
    if (mounted && _activeConversationId == null) {
      setState(() {
        _conversations = cached;
      });
    }
  }

  Future<void> _syncPendingMessages() async {
    if (_isSyncingPending || widget.token.isEmpty) return;
    _isSyncingPending = true;

    try {
      final pending = await ChatDatabaseHelper.instance.getPendingMessages();
      for (var msg in pending) {
        final response = await http.post(
          Uri.parse('${widget.backendUrl}/conversations/${msg.conversationId}/messages'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'body': msg.body,
          }),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 201) {
          final decoded = jsonDecode(response.body);
          final item = decoded['message_data'] ?? {};
          final int serverId = item['id'];
          final String serverTime = _formatDateTimeString(item['created_at']);
          
          await ChatDatabaseHelper.instance.deleteMessage(msg.id);
          final syncedMsg = ChatMessage(
            id: serverId,
            conversationId: msg.conversationId,
            senderName: msg.senderName,
            isMe: true,
            body: msg.body,
            time: serverTime,
            status: 'sent',
          );
          await ChatDatabaseHelper.instance.upsertMessage(syncedMsg);

          final convIdx = _conversations.indexWhere((c) => c.id == msg.conversationId);
          if (convIdx != -1) {
            final c = _conversations[convIdx];
            final updatedConv = ChatConversation(
              id: c.id,
              name: c.name,
              lastMessage: msg.body,
              time: serverTime,
              unreadCount: 0,
              isGroup: c.isGroup,
            );
            await ChatDatabaseHelper.instance.upsertConversation(updatedConv);
          }
        }
      }
      
      final activeId = _activeConversationId;
      if (activeId != null) {
        await _loadMessagesFromDb(activeId);
      }
      await _fetchConversationsFromDb();
    } catch (_) {
    } finally {
      _isSyncingPending = false;
    }
  }

  Future<void> _fetchMessagesFromServerOnly(int conversationId) async {
    if (widget.token.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse('${widget.backendUrl}/conversations/$conversationId/messages'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] as List? ?? [];
        for (var item in data) {
          final int id = item['id'];
          final sender = item['sender'] ?? {};
          final String senderName = sender['name'] ?? 'User';
          final String senderEmail = sender['email'] ?? '';
          final bool isMe = senderEmail.toLowerCase() == widget.email.toLowerCase();
          final String time = _formatDateTimeString(item['created_at']);

          final msg = ChatMessage(
            id: id,
            conversationId: conversationId,
            senderName: senderName,
            isMe: isMe,
            body: item['body'] ?? '',
            time: time,
            status: 'sent',
          );
          await ChatDatabaseHelper.instance.upsertMessage(msg);
        }
        await _loadMessagesFromDb(conversationId);
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _lang = widget.language;
    _employeeName = widget.email.contains('@') 
        ? widget.email.split('@')[0] 
        : widget.email;
    if (_employeeName.isNotEmpty) {
      _employeeName = _employeeName[0].toUpperCase() + _employeeName.substring(1);
    }
    _fetchConversations();
    _startConversationTimer();
  }

  @override
  void dispose() {
    _stopConversationTimer();
    _stopMessageTimer();
    _chatInputController.dispose();
    super.dispose();
  }

  String _getConversationName(Map<String, dynamic> conv) {
    if (conv['is_group'] == true && conv['name'] != null) {
      return conv['name'];
    }
    final participants = conv['participants'] as List? ?? [];
    for (var p in participants) {
      final email = p['email']?.toString() ?? '';
      if (email.toLowerCase() != widget.email.toLowerCase()) {
        return p['name']?.toString() ?? 'User';
      }
    }
    return conv['name']?.toString() ?? 'Direct Chat';
  }

  String _formatDateTimeString(String? isoString) {
    if (isoString == null) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
        final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $ampm';
      } else {
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      }
    } catch (_) {
      return '';
    }
  }

  String _getMyUserId(Map<String, dynamic> conv) {
    final participants = conv['participants'] as List? ?? [];
    for (var p in participants) {
      final email = p['email']?.toString() ?? '';
      if (email.toLowerCase() == widget.email.toLowerCase()) {
        return p['id']?.toString() ?? '';
      }
    }
    return '';
  }

  Future<void> _fetchConversations({bool silent = false}) async {
    // 1. Load from DB first
    final cached = await ChatDatabaseHelper.instance.getConversations();
    if (cached.isNotEmpty && mounted && _activeConversationId == null) {
      setState(() {
        _conversations = cached;
      });
    }

    if (widget.token.isEmpty) {
      if (_conversations.isEmpty && mounted) {
        setState(() {
          _conversations = List.from(_mockConversations);
        });
      }
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _isLoadingConversations = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse('${widget.backendUrl}/conversations'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] as List? ?? [];
        for (var item in data) {
          final int id = item['id'];
          final String name = _getConversationName(item);
          final latestMsg = item['latest_message'];
          final String lastMessage = latestMsg != null ? latestMsg['body'] ?? '' : '';
          final String time = latestMsg != null ? _formatDateTimeString(latestMsg['created_at']) : '';
          
          int unreadCount = 0;
          if (latestMsg != null && latestMsg['read_at'] == null && latestMsg['user_id']?.toString() != _getMyUserId(item)) {
            unreadCount = 1;
          }

          final conv = ChatConversation(
            id: id,
            name: name,
            lastMessage: lastMessage,
            time: time,
            unreadCount: unreadCount,
            isGroup: item['is_group'] ?? false,
          );
          await ChatDatabaseHelper.instance.upsertConversation(conv);
        }
        await _fetchConversationsFromDb();
      } else {
        throw Exception();
      }
    } catch (_) {
      if (_conversations.isEmpty && mounted) {
        setState(() {
          _conversations = List.from(_mockConversations);
        });
      }
    } finally {
      if (!silent && mounted) {
        setState(() {
          _isLoadingConversations = false;
        });
      }
    }
  }

  Future<void> _fetchMessages(int conversationId) async {
    // 1. Load from DB first
    final cached = await ChatDatabaseHelper.instance.getMessages(conversationId);
    if (mounted) {
      setState(() {
        _messages = cached;
      });
    }

    if (widget.token.isEmpty) {
      if (_messages.isEmpty && mounted) {
        setState(() {
          _messages = _mockMessages.where((m) => m.conversationId == conversationId).toList();
        });
      }
      return;
    }

    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${widget.backendUrl}/conversations/$conversationId/messages'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] as List? ?? [];
        for (var item in data) {
          final int id = item['id'];
          final sender = item['sender'] ?? {};
          final String senderName = sender['name'] ?? 'User';
          final String senderEmail = sender['email'] ?? '';
          final bool isMe = senderEmail.toLowerCase() == widget.email.toLowerCase();
          final String time = _formatDateTimeString(item['created_at']);

          final msg = ChatMessage(
            id: id,
            conversationId: conversationId,
            senderName: senderName,
            isMe: isMe,
            body: item['body'] ?? '',
            time: time,
            status: 'sent',
          );
          await ChatDatabaseHelper.instance.upsertMessage(msg);
        }

        // mark as read
        http.post(
          Uri.parse('${widget.backendUrl}/conversations/$conversationId/read'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Accept': 'application/json',
          },
        );

        await _loadMessagesFromDb(conversationId);
      } else {
        throw Exception();
      }
    } catch (_) {
      if (_messages.isEmpty && mounted) {
        setState(() {
          _messages = _mockMessages.where((m) => m.conversationId == conversationId).toList();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  Future<void> _sendMessage(String bodyText) async {
    if (bodyText.trim().isEmpty) return;
    
    final activeId = _activeConversationId;
    if (activeId == null) return;
 
    _chatInputController.clear();
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final timeStr = _formatDateTimeString(DateTime.now().toIso8601String());

    // Create the message locally as 'pending'
    final pendingMsg = ChatMessage(
      id: tempId,
      conversationId: activeId,
      senderName: _employeeName,
      isMe: true,
      body: bodyText,
      time: timeStr,
      status: 'pending',
    );

    // Save to local database
    await ChatDatabaseHelper.instance.upsertMessage(pendingMsg);

    // Update active conversation's last message locally
    final convIdx = _conversations.indexWhere((c) => c.id == activeId);
    if (convIdx != -1) {
      final c = _conversations[convIdx];
      final updatedConv = ChatConversation(
        id: c.id,
        name: c.name,
        lastMessage: bodyText,
        time: timeStr,
        unreadCount: 0,
        isGroup: c.isGroup,
      );
      await ChatDatabaseHelper.instance.upsertConversation(updatedConv);
    }

    // Refresh UI instantly from DB
    await _loadMessagesFromDb(activeId);
    await _fetchConversationsFromDb();

    if (widget.token.isEmpty) {
      // Mock mode
      setState(() {
        _mockMessages.add(pendingMsg);
      });
      // Mark mock message as sent after 500ms
      Future.delayed(const Duration(milliseconds: 500), () async {
        await ChatDatabaseHelper.instance.updateMessageIdAndStatus(tempId, DateTime.now().millisecondsSinceEpoch, timeStr, 'sent');
        await _loadMessagesFromDb(activeId);
      });
      return;
    }
 
    try {
      final response = await http.post(
        Uri.parse('${widget.backendUrl}/conversations/$activeId/messages'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'body': bodyText,
        }),
      ).timeout(const Duration(seconds: 5));
 
      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final item = decoded['message_data'] ?? {};
        
        final int serverId = item['id'] ?? DateTime.now().millisecondsSinceEpoch;
        final String serverTime = _formatDateTimeString(item['created_at'] ?? DateTime.now().toIso8601String());
 
        // Update database: delete pending, insert sent message
        await ChatDatabaseHelper.instance.deleteMessage(tempId);
        final syncedMsg = ChatMessage(
          id: serverId,
          conversationId: activeId,
          senderName: _employeeName,
          isMe: true,
          body: bodyText,
          time: serverTime,
          status: 'sent',
        );
        await ChatDatabaseHelper.instance.upsertMessage(syncedMsg);

        // Update active conversation's last message with server time
        if (convIdx != -1) {
          final c = _conversations[convIdx];
          final updatedConv = ChatConversation(
            id: c.id,
            name: c.name,
            lastMessage: bodyText,
            time: serverTime,
            unreadCount: 0,
            isGroup: c.isGroup,
          );
          await ChatDatabaseHelper.instance.upsertConversation(updatedConv);
        }

        await _loadMessagesFromDb(activeId);
        await _fetchConversationsFromDb();
      } else {
        throw Exception();
      }
    } catch (_) {
      // Keep it as pending in SQLite, no server response. 
      // The background polling timer will retry sending it automatically.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _lang == 'ar'
                  ? 'تم الحفظ محلياً. سيتم الإرسال عند توفر الشبكة.'
                  : 'Saved locally. Will send when connection is restored.',
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
 
  void _startNewConversationDialog() {
    final List<Map<String, dynamic>> mockUsers = [
      {'id': 2, 'name': 'Engineer Ahmad', 'email': 'tech@example.com'},
      {'id': 3, 'name': 'Technician Ali', 'email': 'ali@example.com'},
      {'id': 4, 'name': 'Accountant Sarah', 'email': 'sarah@example.com'},
    ];
 
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: _lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              _lang == 'ar' ? 'بدء محادثة جديدة' : 'Start New Conversation',
              style: TextStyle(color: Colors.teal[900], fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mockUsers.length,
                itemBuilder: (context, index) {
                  final u = mockUsers[index];
                  if (u['email']?.toString().toLowerCase() == widget.email.toLowerCase()) {
                    return const SizedBox.shrink();
                  }
 
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal[50],
                      child: Text(
                        u['name']![0],
                        style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(u['name']!),
                    subtitle: Text(u['email']!),
                    onTap: () {
                      Navigator.of(context).pop();
                      _startOrGetConversation(u['id'], u['name'], u['email']);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
 
  Future<void> _startOrGetConversation(int targetUserId, String targetName, String targetEmail) async {
    if (widget.token.isEmpty) {
      final existingIdx = _mockConversations.indexWhere((c) => c.name == targetName);
      if (existingIdx != -1) {
        final c = _mockConversations[existingIdx];
        setState(() {
          _activeConversationId = c.id;
        });
        _stopConversationTimer();
        _startMessageTimer(c.id);
        _fetchMessages(c.id);
      } else {
        final newId = _mockConversations.length + 10;
        final newConv = ChatConversation(
          id: newId,
          name: targetName,
          lastMessage: '',
          time: '',
          unreadCount: 0,
          isGroup: false,
        );
        setState(() {
          _mockConversations.add(newConv);
          _conversations = List.from(_mockConversations);
          _activeConversationId = newId;
        });
        _stopConversationTimer();
        _startMessageTimer(newId);
        _fetchMessages(newId);
      }
      return;
    }
 
    try {
      final response = await http.post(
        Uri.parse('${widget.backendUrl}/conversations'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'participant_ids': [targetUserId],
        }),
      ).timeout(const Duration(seconds: 6));
 
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final conv = decoded['conversation'] ?? {};
        final int id = conv['id'];
        
        setState(() {
          _activeConversationId = id;
        });
        _stopConversationTimer();
        _startMessageTimer(id);
        
        _fetchConversations(silent: true);
        _fetchMessages(id);
      }
    } catch (_) {
      setState(() {
        final existingIdx = _mockConversations.indexWhere((c) => c.name == targetName);
        if (existingIdx != -1) {
          final c = _mockConversations[existingIdx];
          _activeConversationId = c.id;
          _stopConversationTimer();
          _startMessageTimer(c.id);
          _fetchMessages(c.id);
        } else {
          final newId = _mockConversations.length + 10;
          final newConv = ChatConversation(id: newId, name: targetName, lastMessage: '', time: '', unreadCount: 0, isGroup: false);
          _mockConversations.add(newConv);
          _conversations = List.from(_mockConversations);
          _activeConversationId = newId;
          _stopConversationTimer();
          _startMessageTimer(newId);
          _fetchMessages(newId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = _lang == 'ar';
    Widget content;

    if (_activeConversationId != null) {
      content = _buildActiveChat();
    } else {
      content = _buildConversationList();
    }

    if (widget.isEmbed) {
      return content;
    }

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: _activeConversationId == null 
            ? AppBar(
                elevation: 2,
                backgroundColor: Colors.teal[800],
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Text(
                  _lang == 'ar' ? 'المحادثات' : 'Conversations',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              )
            : null, // active chat screen already builds its own appBar
        body: content,
      ),
    );
  }

  Widget _buildConversationList() {
    final filtered = _conversations.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    final isRTL = _lang == 'ar';

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
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
                      hintText: _lang == 'ar' ? 'البحث في الرسائل...' : 'Search messages...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.teal[800]),
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: _isLoadingConversations
                  ? Center(child: CircularProgressIndicator(color: Colors.teal[800]))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _lang == 'ar' ? 'لا توجد محادثات بعد' : 'No conversations yet',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _lang == 'ar' ? 'اضغط على زر الإضافة لبدء محادثة جديدة' : 'Tap the + button to start a new chat',
                                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final conv = filtered[index];
                            final hasUnread = conv.unreadCount > 0;

                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _activeConversationId = conv.id;
                                  });
                                  _stopConversationTimer();
                                  _startMessageTimer(conv.id);
                                  _fetchMessages(conv.id);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: conv.isGroup 
                                                ? [Colors.cyan[700]!, Colors.cyan[500]!] 
                                                : [Colors.teal[700]!, Colors.teal[500]!],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            conv.name.isNotEmpty ? conv.name[0].toUpperCase() : 'C',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              conv.name,
                                              style: TextStyle(
                                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                                                fontSize: 15,
                                                color: const Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              conv.lastMessage.isNotEmpty ? conv.lastMessage : (_lang == 'ar' ? 'محادثة فارغة' : 'Empty conversation'),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: hasUnread ? Colors.black87 : Colors.grey[600],
                                                fontSize: 13,
                                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            conv.time,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: hasUnread ? Colors.teal[800] : Colors.grey[400],
                                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (hasUnread)
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.teal[800],
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${conv.unreadCount}',
                                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            )
                                          else
                                            const SizedBox(height: 22),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _startNewConversationDialog,
          backgroundColor: Colors.teal[800],
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActiveChat() {
    final isRTL = _lang == 'ar';
    final activeId = _activeConversationId;
    if (activeId == null) return const SizedBox.shrink();

    final conv = _conversations.firstWhere(
      (c) => c.id == activeId,
      orElse: () => ChatConversation(id: activeId, name: 'Chat', lastMessage: '', time: '', unreadCount: 0, isGroup: false),
    );

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          elevation: 2,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.teal[800]),
            onPressed: () {
              setState(() {
                _activeConversationId = null;
              });
              _stopMessageTimer();
              _startConversationTimer();
              _fetchConversations();
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal[50],
                radius: 18,
                child: Text(
                  conv.name.isNotEmpty ? conv.name[0].toUpperCase() : 'C',
                  style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    conv.name,
                    style: const TextStyle(color: Color(0xFF1F2937), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _lang == 'ar' ? 'نشط الآن' : 'Active now',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        body: Column(
          children: [
            Expanded(
              child: _isLoadingMessages
                  ? Center(child: CircularProgressIndicator(color: Colors.teal[800]))
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            _lang == 'ar' ? 'لا توجد رسائل بعد. ابدأ الكتابة...' : 'No messages yet. Start typing...',
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg.isMe;

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.teal[800] : Colors.white,
                                  borderRadius: isMe
                                      ? BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isRTL ? Radius.zero : const Radius.circular(16),
                                          bottomRight: isRTL ? const Radius.circular(16) : Radius.zero,
                                        )
                                      : BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: isRTL ? const Radius.circular(16) : Radius.zero,
                                          bottomRight: isRTL ? Radius.zero : const Radius.circular(16),
                                        ),
                                  boxShadow: [
                                    if (!isMe)
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe && conv.isGroup)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          msg.senderName,
                                          style: TextStyle(
                                            color: Colors.cyan[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      msg.body,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            msg.time,
                                            style: TextStyle(
                                              color: isMe ? Colors.white60 : Colors.grey[400],
                                              fontSize: 10,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              msg.status == 'pending' 
                                                  ? Icons.access_time 
                                                  : Icons.done_all,
                                              size: 12,
                                              color: Colors.white70,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.teal[800]),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _chatInputController,
                      decoration: InputDecoration(
                        hintText: _lang == 'ar' ? 'اكتب رسالة...' : 'Write a message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal[800],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_chatInputController.text),
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
