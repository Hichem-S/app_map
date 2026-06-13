import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

// â”€â”€ Model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AiMessage {
  final bool   isUser;
  final String text;
  final String? sql;
  final List<Map<String, dynamic>> rows;
  final int rowCount;

  _AiMessage.user(this.text)
      : isUser = true, sql = null, rows = const [], rowCount = 0;

  _AiMessage.ai({required this.text, this.sql, required this.rows, required this.rowCount})
      : isUser = false;
}

// â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AiQueryScreen extends StatefulWidget {
  const AiQueryScreen({Key? key}) : super(key: key);

  @override
  State<AiQueryScreen> createState() => _AiQueryScreenState();
}

class _AiQueryScreenState extends State<AiQueryScreen> {
  final List<_AiMessage> _messages = [];
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading = false;

  static const _suggestions = [
    'How many products are in each room?',
    'Which items have critical status?',
    'Show products not scanned in 7 days',
    'How many items per department?',
    'List all rooms in Informatique',
  ];

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  Future<void> _send([String? override]) async {
    final text = (override ?? _inputCtrl.text).trim();
    if (text.isEmpty || _loading) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_AiMessage.user(text));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final res = await ApiService.queryAI(text);
      final data = res['data'] as Map<String, dynamic>? ??
          {'answer': res['message'] ?? 'Something went wrong.', 'sql': null, 'rows': [], 'row_count': 0};
      final rows = (data['rows'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      setState(() {
        _messages.add(_AiMessage.ai(
          text:     data['answer'] as String? ?? 'No answer.',
          sql:      data['sql']    as String?,
          rows:     rows,
          rowCount: (data['row_count'] as num?)?.toInt() ?? rows.length,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(_AiMessage.ai(
          text:     'Error: ${e.toString()}',
          rows:     const [],
          rowCount: 0,
        ));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
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
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AI Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                      color: AppColors.textH)),
              Text('Ask anything about your inventory',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildWelcome()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == _messages.length) return _buildTyping();
                    return _MessageBubble(
                      msg: _messages[i],
                      onSqlTap: (sql) => _showSql(context, sql),
                    );
                  },
                ),
        ),
        _buildInput(),
      ]),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF6D28D9).withOpacity(0.3),
                  blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('AI Inventory Assistant',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: AppColors.textH)),
        const SizedBox(height: 8),
        const Text(
          'Ask questions about your inventory in plain language.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
        ),
        const SizedBox(height: 28),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Try asking:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textBody)),
        ),
        const SizedBox(height: 12),
        ..._suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _send(s),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6D28D9).withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    size: 16, color: Color(0xFF6D28D9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s,
                      style: const TextStyle(fontSize: 13,
                          color: AppColors.textBody, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: AppColors.textMuted),
              ]),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome_rounded,
              color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: AppColors.shadowMd,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _Dot(delay: 0), _Dot(delay: 200), _Dot(delay: 400),
          ]),
        ),
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
              maxLines: 3, minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Ask about your inventory…',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _loading ? null : () => _send(),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: _loading
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]),
              color: _loading ? AppColors.border : null,
              shape: BoxShape.circle,
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  void _showSql(BuildContext context, String sql) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Text('Generated SQL',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white60, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: sql));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SQL copied'),
                      backgroundColor: Color(0xFF22C55E),
                      behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ]),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF13131F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(sql,
                style: const TextStyle(fontSize: 12, color: Color(0xFF98C379),
                    fontFamily: 'monospace', height: 1.5)),
          ),
        ]),
      ),
    );
  }
}

// â”€â”€ Message bubble â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MessageBubble extends StatefulWidget {
  final _AiMessage msg;
  final void Function(String) onSqlTap;
  const _MessageBubble({required this.msg, required this.onSqlTap});

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    if (msg.isUser) return _userBubble(msg.text);
    return _aiBubble(msg);
  }

  Widget _userBubble(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 60),
    child: Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]),
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(18),
            topRight:    Radius.circular(18),
            bottomLeft:  Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.4)),
      ),
    ),
  );

  Widget _aiBubble(_AiMessage msg) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.auto_awesome_rounded,
            color: Colors.white, size: 16),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(4),
                topRight:    Radius.circular(18),
                bottomLeft:  Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: AppColors.shadowMd,
            ),
            child: Text(msg.text,
                style: const TextStyle(fontSize: 14, color: AppColors.textH,
                    height: 1.5)),
          ),
          if (msg.sql != null || msg.rows.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (msg.sql != null)
                _ChipBtn(
                  icon: Icons.code_rounded,
                  label: 'SQL',
                  onTap: () => widget.onSqlTap(msg.sql!),
                ),
              if (msg.rows.isNotEmpty) ...[
                const SizedBox(width: 8),
                _ChipBtn(
                  icon: _showTable
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.table_chart_outlined,
                  label: _showTable
                      ? 'Hide table'
                      : '${msg.rowCount} row${msg.rowCount == 1 ? '' : 's'}',
                  onTap: () => setState(() => _showTable = !_showTable),
                ),
              ],
            ]),
            if (_showTable && msg.rows.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DataTable(rows: msg.rows),
            ],
          ],
        ]),
      ),
    ]),
  );
}

class _ChipBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6D28D9).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6D28D9).withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: const Color(0xFF6D28D9)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Color(0xFF6D28D9))),
      ]),
    ),
  );
}

class _DataTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _DataTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox();
    final cols = rows.first.keys.toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowMd,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
                const Color(0xFF6D28D9).withOpacity(0.06)),
            dataRowMinHeight: 36,
            dataRowMaxHeight: 48,
            columnSpacing: 20,
            horizontalMargin: 14,
            columns: cols
                .map((c) => DataColumn(
                      label: Text(c,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: Color(0xFF6D28D9))),
                    ))
                .toList(),
            rows: rows
                .map((row) => DataRow(
                      cells: cols
                          .map((c) => DataCell(Text(
                                '${row[c] ?? 'â€”'}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textBody),
                              )))
                          .toList(),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Animated typing dots â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(
            color: Color(0xFF6D28D9), shape: BoxShape.circle),
      ),
    ),
  );
}


