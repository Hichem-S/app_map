import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import '../utils/app_colors.dart';

enum _ScanState { waiting, detected, error }

class NfcScanScreen extends StatefulWidget {
  const NfcScanScreen({super.key});

  @override
  State<NfcScanScreen> createState() => _NfcScanScreenState();
}

class _NfcScanScreenState extends State<NfcScanScreen>
    with SingleTickerProviderStateMixin {
  _ScanState _state = _ScanState.waiting;
  String? _errorMessage;
  _TagInfo? _tagInfo;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _startSession();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  Future<void> _startSession() async {
    final availability = await NfcManager.instance.checkAvailability();
    if (!mounted) return;

    if (availability != NfcAvailability.enabled) {
      setState(() {
        _state = _ScanState.error;
        _errorMessage = availability == NfcAvailability.disabled
            ? 'NFC is disabled on this device.\nPlease enable NFC in Settings.'
            : 'NFC unavailable.\nEnable NFC in Settings → Connected devices → NFC, or your device may not support it.';
      });
      return;
    }

    setState(() { _state = _ScanState.waiting; });

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          try {
            final info = _TagInfo.fromTag(tag);
            await NfcManager.instance.stopSession();
            if (mounted) setState(() { _tagInfo = info; _state = _ScanState.detected; });
          } catch (e) {
            await NfcManager.instance.stopSession();
            if (mounted) {
              setState(() {
                _state = _ScanState.error;
                _errorMessage = 'Failed to read tag: $e';
              });
            }
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ScanState.error;
          _errorMessage = 'Could not start NFC session: $e';
        });
      }
    }
  }

  Future<void> _retry() async {
    await NfcManager.instance.stopSession().catchError((_) {});
    setState(() { _state = _ScanState.waiting; _tagInfo = null; _errorMessage = null; });
    await _startSession();
  }

  void _confirmTag() {
    if (_tagInfo == null) return;
    Navigator.pop(context, _tagInfo!.uid);
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textH),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NFC Tag Scanner',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textH)),
            Text('Approach a tag to scan it',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: _state == _ScanState.detected && _tagInfo != null
          ? _buildDetectedView()
          : _buildWaitingView(),
    );
  }

  // ─── Waiting / error view ─────────────────────────────────────────────────────

  Widget _buildWaitingView() {
    final isError = _state == _ScanState.error;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: isError ? const AlwaysStoppedAnimation(1.0) : _pulseAnim,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isError ? AppColors.errorBg : const Color(0xFFF5F3FF),
                  border: Border.all(
                    color: isError ? AppColors.error : const Color(0xFF6D28D9),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.nfc_rounded,
                  size: 70,
                  color: isError ? AppColors.error : const Color(0xFF6D28D9),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isError ? 'NFC Unavailable' : 'Approach an NFC Tag',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textH),
            ),
            const SizedBox(height: 12),
            Text(
              isError
                  ? (_errorMessage ?? 'An error occurred')
                  : 'Hold the NFC tag close to the\nback of your phone to scan it.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textBody, height: 1.6),
            ),
            const SizedBox(height: 40),
            if (isError)
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              )
            else
              _WaitingDots(),
          ],
        ),
      ),
    );
  }

  // ─── Detected view ────────────────────────────────────────────────────────────

  Widget _buildDetectedView() {
    final tag = _tagInfo!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          color: const Color(0xFFF5F3FF),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF6D28D9), size: 20),
              SizedBox(width: 8),
              Text('NFC Tag Detected',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: Color(0xFF6D28D9))),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoCard(
                  icon: Icons.tag_rounded,
                  title: 'Serial Number (UID)',
                  value: tag.uid,
                  highlight: true,
                ),
                if (tag.techList.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _infoCard(
                    icon: Icons.layers_outlined,
                    title: 'Technologies Available',
                    value: tag.techList.join(', '),
                  ),
                ],
                if (tag.tagType != null) ...[
                  const SizedBox(height: 10),
                  _infoCard(
                    icon: Icons.label_outline,
                    title: 'Tag Type',
                    value: tag.tagType!,
                  ),
                ],
                if (tag.atqa != null) ...[
                  const SizedBox(height: 10),
                  _infoCard(icon: Icons.memory_outlined, title: 'ATQA', value: tag.atqa!),
                ],
                if (tag.sak != null) ...[
                  const SizedBox(height: 10),
                  _infoCard(icon: Icons.memory_outlined, title: 'SAK', value: tag.sak!),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _confirmTag,
                    icon: const Icon(Icons.nfc_rounded, size: 20),
                    label: const Text('Use This Tag',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D28D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh, size: 18, color: AppColors.textBody),
                    label: const Text('Scan Different Tag',
                        style: TextStyle(color: AppColors.textBody, fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    bool highlight = false,
  }) {
    const purple   = Color(0xFF6D28D9);
    const purpleBg = Color(0xFFF5F3FF);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? purpleBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? purple.withValues(alpha: 0.35) : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: AppColors.shadowMd,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: highlight ? purple.withValues(alpha: 0.1) : AppColors.bgMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: highlight ? purple : AppColors.textMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: highlight ? purple : AppColors.textMuted,
                        letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: highlight ? 15 : 14,
                        fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                        color: highlight ? purple : AppColors.textH,
                        letterSpacing: highlight ? 0.8 : 0)),
              ],
            ),
          ),
          if (highlight) const Icon(Icons.check_circle, color: purple, size: 20),
        ],
      ),
    );
  }
}

// ─── Tag info ─────────────────────────────────────────────────────────────────

class _TagInfo {
  final String uid;
  final List<String> techList;
  final String? tagType;
  final String? atqa;
  final String? sak;

  const _TagInfo({
    required this.uid,
    required this.techList,
    this.tagType,
    this.atqa,
    this.sak,
  });

  static _TagInfo fromTag(NfcTag tag) {
    final androidTag = NfcTagAndroid.from(tag);

    String? tagType;
    String? atqa;
    String? sakStr;

    // ISO 14443-3A — most NFC stickers and cards
    final nfca = NfcAAndroid.from(tag);
    if (nfca != null) {
      final a = nfca.atqa;
      if (a.length >= 2) {
        final val = (a[1] << 8) | a[0];
        atqa = '0x${val.toRadixString(16).padLeft(4, '0').toUpperCase()}';
      }
      sakStr = '0x${nfca.sak.toRadixString(16).padLeft(2, '0').toUpperCase()}';
      tagType = 'ISO 14443-3A';
    }

    if (NfcBAndroid.from(tag) != null)    tagType ??= 'ISO 14443-3B';
    if (NfcFAndroid.from(tag) != null)    tagType ??= 'JIS 6319-4 (FeliCa)';
    if (NfcVAndroid.from(tag) != null)    tagType ??= 'ISO 15693';
    if (IsoDepAndroid.from(tag) != null)  tagType ??= 'ISO-DEP';

    final uid = (androidTag != null && androidTag.id.isNotEmpty)
        ? androidTag.id
            .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
            .join(':')
        : 'Unknown';

    // Strip "android.nfc.tech." prefix for readable display
    final techs = androidTag?.techList
        .map((t) => t.replaceFirst('android.nfc.tech.', ''))
        .toList() ?? [];

    return _TagInfo(
      uid: uid,
      techList: techs,
      tagType: tagType,
      atqa: atqa,
      sak: sakStr,
    );
  }
}

// ─── Animated waiting dots ────────────────────────────────────────────────────

class _WaitingDots extends StatefulWidget {
  @override
  State<_WaitingDots> createState() => _WaitingDotsState();
}

class _WaitingDotsState extends State<_WaitingDots> {
  int _active = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (mounted) setState(() => _active = (_active + 1) % 3);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: i == _active ? 13 : 8,
        height: i == _active ? 13 : 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i == _active
              ? const Color(0xFF6D28D9)
              : const Color(0xFF6D28D9).withValues(alpha: 0.25),
        ),
      )),
    );
  }
}
