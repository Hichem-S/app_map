import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/ws_service.dart';
import '../utils/app_colors.dart';
import 'chat_screen.dart';

// â”€â”€ Models â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ChatUser {
  final String  id;
  final String  name;
  final String? avatar;
  final String  role;
  bool          isOnline;

  ChatUser.fromJson(Map<String, dynamic> j)
      : id       = j['id']     as String,
        name     = j['name']   as String,
        avatar   = j['avatar'] as String?,
        role     = j['role']   as String? ?? 'user',
        isOnline = j['is_online'] as bool? ?? false;
}

class Conversation {
  final String   id;
  final String   type;
  final String?  name;
  final DateTime createdAt;
  Map<String, dynamic>? lastMessage;
  int            unreadCount;
  List<dynamic>  otherMembers;

  Conversation.fromJson(Map<String, dynamic> j)
      : id           = j['id']           as String,
        type         = j['type']         as String,
        name         = j['name']         as String?,
        createdAt    = (DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now()).toLocal(),
        lastMessage  = j['last_message'] as Map<String, dynamic>?,
        unreadCount  = (j['unread_count'] as num?)?.toInt() ?? 0,
        otherMembers = j['other_members'] as List<dynamic>? ?? [];

  String get displayName {
    if (type == 'group') return name ?? 'Group';
    if (otherMembers.isEmpty) return 'Unknown';
    return (otherMembers.first as Map<String, dynamic>)['name'] as String? ?? 'Unknown';
  }

  String? get otherUserId {
    if (type != 'direct' || otherMembers.isEmpty) return null;
    return (otherMembers.first as Map<String, dynamic>)['id'] as String?;
  }
}

// â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Conversation> _convs = [];
  final Map<String, bool>  _online = {};
  StreamSubscription?      _wsSub;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _wsSub = WsService.stream.listen(_onWs);
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  void _onWs(dynamic raw) {
    try {
      final msg = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : raw as Map<String, dynamic>;
      if (!mounted) return;

      if (msg['type'] == 'new_message') {
        final m   = msg['message'] as Map<String, dynamic>;
        final cid = m['conversation_id'] as String;
        setState(() {
          final idx = _convs.indexWhere((c) => c.id == cid);
          if (idx != -1) {
            _convs[idx].lastMessage = m;
            _convs[idx].unreadCount++;
            final conv = _convs.removeAt(idx);
            _convs.insert(0, conv);
          }
        });
      } else if (msg['type'] == 'user_online') {
        setState(() => _online[msg['user_id'] as String] = true);
      } else if (msg['type'] == 'user_offline') {
        setState(() => _online[msg['user_id'] as String] = false);
      }
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.getConversations();
      if (!mounted) return;
      setState(() {
        _convs
          ..clear()
          ..addAll((res['data'] as List<dynamic>? ?? [])
              .map((e) => Conversation.fromJson(e as Map<String, dynamic>)));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _relTime(DateTime dt) {
    final local = dt.toLocal();
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day   = DateTime(local.year, local.month, local.day);
    final hm    = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (day == today) return hm;
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  }

  bool _isOnline(Conversation c) {
    final uid = c.otherUserId;
    return uid != null && (_online[uid] ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Messages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textH)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'New conversation',
            onPressed: _showNewConvSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _convs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _convs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 74, color: AppColors.border),
                    itemBuilder: (_, i) {
                      final conv = _convs[i];
                      return Dismissible(
                        key: Key(conv.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: const Color(0xFFEF4444),
                          child: const Icon(Icons.delete_outline_rounded,
                              color: Colors.white, size: 26),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete conversation'),
                              content: const Text('This will permanently delete the conversation and all its messages.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) async {
                          setState(() => _convs.removeAt(i));
                          try {
                            await ApiService.deleteConversation(conv.id);
                          } catch (_) {
                            if (mounted) _load();
                          }
                        },
                        child: _ConvTile(
                          conv: conv,
                          online: _isOnline(conv),
                          rel:    _relTime(conv.lastMessage != null
                              ? ((DateTime.tryParse(
                                      conv.lastMessage!['created_at'] as String? ?? '')
                                  ?.toLocal()) ?? conv.createdAt)
                              : conv.createdAt),
                          onTap: () => _openChat(conv),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No conversations yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textH)),
          const SizedBox(height: 8),
          const Text('Tap the pencil icon to start chatting.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showNewConvSheet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      );

  void _openChat(Conversation c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: c)),
    ).then((_) => _load());
  }

  void _showNewConvSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewConvSheet(
        onCreated: (conv) {
          Navigator.pop(context);
          setState(() {
            final idx = _convs.indexWhere((c) => c.id == conv.id);
            if (idx == -1) _convs.insert(0, conv);
          });
          _openChat(conv);
        },
      ),
    );
  }
}

// â”€â”€ Conversation tile â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final bool         online;
  final String       rel;
  final VoidCallback onTap;
  const _ConvTile({required this.conv, required this.online, required this.rel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isGroup  = conv.type == 'group';
    final initials = conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?';
    final lastMsg  = conv.lastMessage?['content'] as String? ?? 'No messages yet';

    String? avatarPath;
    if (!isGroup && conv.otherMembers.isNotEmpty) {
      avatarPath = (conv.otherMembers.first as Map<String, dynamic>)['avatar'] as String?;
    }
    final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
        ? ApiService.avatarUrl(avatarPath)
        : null;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: isGroup
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.accent.withOpacity(0.15),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl != null
              ? null
              : isGroup
                  ? const Icon(Icons.group_rounded, color: AppColors.primary, size: 26)
                  : Text(initials,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary)),
        ),
        if (!isGroup && online)
          Positioned(
            bottom: 2, right: 2,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ]),
      title: Row(children: [
        Expanded(
          child: Text(conv.displayName,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 15, color: AppColors.textH)),
        ),
        Text(rel, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ]),
      subtitle: Row(children: [
        Expanded(
          child: Text(lastMsg,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: conv.unreadCount > 0 ? AppColors.textBody : AppColors.textMuted,
                  fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal)),
        ),
        if (conv.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Text('${conv.unreadCount}',
                style: const TextStyle(
                    fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
      ]),
    );
  }
}

// â”€â”€ New conversation bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NewConvSheet extends StatefulWidget {
  final void Function(Conversation) onCreated;
  const _NewConvSheet({required this.onCreated});

  @override
  State<_NewConvSheet> createState() => _NewConvSheetState();
}

class _NewConvSheetState extends State<_NewConvSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<ChatUser> _users    = [];
  List<ChatUser> _filtered = [];
  Set<String>    _selected = {};
  String         _groupName = '';
  bool           _loading  = true;
  bool           _saving   = false;
  final _search  = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadUsers();
    _search.addListener(_filter);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final res = await ApiService.getChatUsers();
      if (!mounted) return;
      final list = (res['data'] as List<dynamic>? ?? [])
          .map((e) => ChatUser.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() { _users = list; _filtered = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _search.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _users
          : _users.where((u) => u.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _create(String type) async {
    if (_selected.isEmpty) return;
    if (type == 'group' && _groupName.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final res = await ApiService.createConversation(
        type: type,
        memberIds: _selected.toList(),
        name: type == 'group' ? _groupName.trim() : null,
      );
      if (!mounted) return;
      final conv = Conversation.fromJson(res['data'] as Map<String, dynamic>);
      widget.onCreated(conv);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Center(
          child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Row(children: [
            const Text('New Conversation',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textH)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.textMuted),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Direct'), Tab(text: 'Group')],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search users…',
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
              filled: true, fillColor: AppColors.bgPage,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: TabBarView(controller: _tabs, children: [
            // Direct tab
            _UserList(
              users: _filtered,
              loading: _loading,
              selected: _selected,
              singleSelect: true,
              onToggle: (id) => setState(() {
                _selected = {id};
              }),
            ),
            // Group tab
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (v) => _groupName = v,
                  decoration: InputDecoration(
                    hintText: 'Group name…',
                    filled: true, fillColor: AppColors.bgPage,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: _UserList(
                  users: _filtered,
                  loading: _loading,
                  selected: _selected,
                  singleSelect: false,
                  onToggle: (id) => setState(() {
                    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
                  }),
                ),
              ),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selected.isEmpty || _saving
                  ? null
                  : () => _create(_tabs.index == 0 ? 'direct' : 'group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _tabs.index == 0 ? 'Open Chat' : 'Create Group (${_selected.length} selected)',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<ChatUser> users;
  final bool           loading;
  final Set<String>    selected;
  final bool           singleSelect;
  final void Function(String) onToggle;

  const _UserList({
    required this.users,
    required this.loading,
    required this.selected,
    required this.singleSelect,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (users.isEmpty) return const Center(
        child: Text('No users found', style: TextStyle(color: AppColors.textMuted)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final u   = users[i];
        final sel = selected.contains(u.id);
        return ListTile(
          onTap: () => onToggle(u.id),
          leading: Stack(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Text(u.name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700,
                      fontSize: 16, color: AppColors.primary)),
            ),
            if (u.isOnline)
              Positioned(
                bottom: 1, right: 1,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ]),
          title: Text(u.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColors.textH)),
          subtitle: Row(children: [
            Text(u.role,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            if (u.isOnline) ...[
              const SizedBox(width: 6),
              const Text('â— Online',
                  style: TextStyle(fontSize: 11, color: Color(0xFF22C55E),
                      fontWeight: FontWeight.w500)),
            ],
          ]),
          trailing: sel
              ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
              : (singleSelect
                  ? null
                  : const Icon(Icons.radio_button_unchecked, color: AppColors.textMuted)),
        );
      },
    );
  }
}


