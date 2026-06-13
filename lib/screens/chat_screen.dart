import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import '../utils/app_colors.dart';
import 'chat_list_screen.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatScreen({Key? key, required this.conversation}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final _scrollCtrl  = ScrollController();
  final _inputCtrl   = TextEditingController();
  StreamSubscription? _wsSub;
  bool   _loading    = true;
  bool   _sending    = false;
  bool   _otherOnline = false;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _init();
    _wsSub = WsService.stream.listen(_onWs);
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _myUserId = await ApiService.getMyId();
    await _loadMessages();
    // Check initial online status for direct chats
    if (widget.conversation.type == 'direct') {
      final uid = widget.conversation.otherUserId;
      if (uid != null) {
        try {
          final res = await ApiService.getChatUsers();
          final users = (res['data'] as List<dynamic>? ?? []);
          final other = users.firstWhere(
            (u) => (u as Map<String, dynamic>)['id'] == uid,
            orElse: () => null,
          );
          if (other != null && mounted) {
            setState(() => _otherOnline = (other as Map<String, dynamic>)['is_online'] as bool? ?? false);
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final res = await ApiService.getMessages(widget.conversation.id);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll((res['data'] as List<dynamic>? ?? [])
              .map((e) => e as Map<String, dynamic>));
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onWs(dynamic raw) {
    try {
      final msg = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      if (!mounted) return;

      if (msg['type'] == 'new_message') {
        final m   = msg['message'] as Map<String, dynamic>;
        if (m['conversation_id'] == widget.conversation.id) {
          setState(() => _messages.add(m));
          _scrollToBottom();
          // Mark as read
          ApiService.markAsRead(widget.conversation.id).catchError((_) {});
        }
      } else if (msg['type'] == 'user_online') {
        if (msg['user_id'] == widget.conversation.otherUserId) {
          setState(() => _otherOnline = true);
        }
      } else if (msg['type'] == 'user_offline') {
        if (msg['user_id'] == widget.conversation.otherUserId) {
          setState(() => _otherOnline = false);
        }
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() => _sending = true);

    try {
      final res = await ApiService.sendMessage(widget.conversation.id, text);
      if (!mounted) return;
      final msg = res['data'] as Map<String, dynamic>;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    } catch (_) {} finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = widget.conversation.type == 'group';
    final title   = widget.conversation.displayName;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(children: [
          Stack(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: isGroup
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.accent.withOpacity(0.15),
              child: isGroup
                  ? const Icon(Icons.group_rounded, color: AppColors.primary, size: 20)
                  : Text(title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 14, color: AppColors.primary)),
            ),
            if (!isGroup && _otherOnline)
              Positioned(
                bottom: 1, right: 1,
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.textH)),
            if (!isGroup)
              Text(
                _otherOnline ? 'Online' : 'Offline',
                style: TextStyle(
                    fontSize: 11,
                    color: _otherOnline ? const Color(0xFF22C55E) : AppColors.textMuted),
              ),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _messages.isEmpty
                  ? const Center(
                      child: Text('No messages yet. Say hello!',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 14)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) => _MessageBubble(
                        msg:     _messages[i],
                        isMe:    (_messages[i]['sender'] as Map<String, dynamic>?)?['id'] == _myUserId,
                        isGroup: isGroup,
                        showSenderName: isGroup &&
                            (i == 0 ||
                                (_messages[i - 1]['sender'] as Map<String, dynamic>?)?['id'] !=
                                    (_messages[i]['sender'] as Map<String, dynamic>?)?['id']),
                      ),
                    ),
        ),
        _buildInput(),
      ]),
    );
  }

  Widget _buildInput() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 14),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _inputCtrl,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Message…',
                hintStyle: TextStyle(color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}

// â”€â”€ Message bubble â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool isGroup;
  final bool showSenderName;

  const _MessageBubble({
    required this.msg,
    required this.isMe,
    required this.isGroup,
    required this.showSenderName,
  });

  @override
  Widget build(BuildContext context) {
    final content   = msg['content'] as String? ?? '';
    final sender    = msg['sender']  as Map<String, dynamic>? ?? {};
    final senderName = sender['name'] as String? ?? '';
    final createdAt = (DateTime.tryParse(msg['created_at'] as String? ?? '') ?? DateTime.now()).toLocal();
    final now       = DateTime.now();
    final isToday   = createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;
    final isYesterday = createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day - 1;
    final hhmm      = '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    final timeStr   = isToday
        ? hhmm
        : isYesterday
            ? 'Yesterday $hhmm'
            : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} $hhmm';

    return Padding(
      padding: EdgeInsets.only(
          bottom: 4,
          left:  isMe ? 48 : 0,
          right: isMe ? 0  : 48),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderName && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 2),
              child: Text(senderName,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(18),
                topRight:    const Radius.circular(18),
                bottomLeft:  Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4  : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(content,
                    style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : AppColors.textH)),
                const SizedBox(height: 4),
                Text(timeStr,
                    style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


