import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:latlong2/latlong.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:provider/provider.dart';

import '../tracker/accessory_battery.dart';
import '../tracker/accessory_model.dart';
import '../tracker/accessory_registry.dart';
import '../tracker/findmy/find_my_controller.dart';
import '../tracker/location_model.dart';
import '../tracker/tracker_settings.dart';

// ─── Main screen ─────────────────────────────────────────────────────────────

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({Key? key}) : super(key: key);

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final registry = context.read<AccessoryRegistry>();
      final locModel = context.read<TrackerLocationModel>();
      if (!registry.initialLoadFinished && !registry.loading) {
        await registry.loadAccessories();
      }
      if (!mounted) return;
      locModel.requestLocationUpdates();
      if (registry.accessories.isNotEmpty) _refresh();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final registry = context.read<AccessoryRegistry>();
      final active = registry.accessories.where((a) => a.isActive);
      if (active.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active trackers to refresh.')),
          );
        }
        return;
      }
      final count = await registry.loadLocationReports(active);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A2340),
            content: Text('Fetched $count location report(s).'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddTrackerSheet(onAdded: () {
        Navigator.pop(context);
        _refresh();
      }),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2340),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.canPop(context)
              ? Navigator.pop(context)
              : Navigator.pushReplacementNamed(context, '/home'),
        ),
        title: const Text('AirTag Tracker',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh all',
              onPressed: _refresh,
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _showSettingsSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined),  text: 'Map'),
            Tab(icon: Icon(Icons.list_rounded),  text: 'Trackers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MapTab(onRefresh: _refresh),
          _ListTab(onRefresh: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A2340),
        foregroundColor: Colors.white,
        onPressed: _showAddSheet,
        tooltip: 'Add Tracker',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Map tab ──────────────────────────────────────────────────────────────────

class _MapTab extends StatefulWidget {
  final VoidCallback onRefresh;
  const _MapTab({required this.onRefresh});

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  final MapController _mapCtrl = MapController();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AccessoryRegistry, TrackerLocationModel>(
      builder: (_, registry, locModel, __) {
        final accessories = registry.accessories;
        final here = locModel.here;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final points = [
            if (here != null) here,
            ...accessories
                .where((a) => a.isActive && a.lastLocation != null)
                .map((a) => a.lastLocation!),
          ];
          if (points.isNotEmpty) {
            try {
              _mapCtrl.fitCamera(CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.all(48)));
            } catch (_) {}
          }
        });

        return FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: here ?? const LatLng(36.8, 10.18),
            initialZoom: 13,
            minZoom: 2,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'smart_inventory',
              tileProvider: NetworkTileProvider(),
            ),
            // Tracker markers
            MarkerLayer(
              markers: accessories
                  .where((a) => a.isActive && a.lastLocation != null)
                  .map((a) => Marker(
                        point: a.lastLocation!,
                        width: 46,
                        height: 46,
                        rotate: true,
                        child: GestureDetector(
                          onTap: () => _showTrackerInfo(context, a),
                          child: _TrackerMarker(accessory: a),
                        ),
                      ))
                  .toList(),
            ),
            // User location marker
            if (here != null)
              MarkerLayer(markers: [
                Marker(
                  point: here,
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ]),
          ],
        );
      },
    );
  }

  void _showTrackerInfo(BuildContext context, Accessory a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(children: [
          Icon(a.icon, color: a.color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(a.name, style: const TextStyle(fontSize: 16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (a.datePublished != null)
              _InfoRow('Last seen', _relativeTime(a.datePublished!)),
            if (a.lastLocation != null)
              _InfoRow('Coordinates',
                  '${a.lastLocation!.latitude.toStringAsFixed(5)}, '
                  '${a.lastLocation!.longitude.toStringAsFixed(5)}'),
            if (a.lastBatteryStatus != null)
              _InfoRow('Battery', _batteryLabel(a.lastBatteryStatus!)),
          ],
        ),
        actions: [
          if (a.lastLocation != null)
            TextButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('Navigate'),
              onPressed: () {
                Navigator.pop(context);
                MapsLauncher.launchCoordinates(
                    a.lastLocation!.latitude, a.lastLocation!.longitude, a.name);
              },
            ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

class _TrackerMarker extends StatelessWidget {
  final Accessory accessory;
  const _TrackerMarker({required this.accessory});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accessory.color.withValues(alpha: 0.15),
        border: Border.all(color: accessory.color, width: 2),
      ),
      child: Icon(accessory.icon, color: accessory.color, size: 22),
    );
  }
}

// ─── List tab ─────────────────────────────────────────────────────────────────

class _ListTab extends StatelessWidget {
  final VoidCallback onRefresh;
  const _ListTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessoryRegistry>(
      builder: (_, registry, __) {
        if (registry.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (registry.accessories.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text('No trackers yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text('Tap + to add a tracker',
                    style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }
        return SlidableAutoCloseBehavior(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: registry.accessories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 0),
            itemBuilder: (ctx, i) {
              final a = registry.accessories[i];
              return _TrackerListItem(
                accessory: a,
                onRefresh: onRefresh,
                onDelete: () {
                  registry.removeAccessory(a);
                },
                onToggleActive: () {
                  final updated = a.clone();
                  updated.isActive = !a.isActive;
                  registry.editAccessory(a, updated);
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _TrackerListItem extends StatelessWidget {
  final Accessory accessory;
  final VoidCallback onRefresh;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _TrackerListItem({
    required this.accessory,
    required this.onRefresh,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final a = accessory;
    return Slidable(
      key: ValueKey(a.hashedPublicKey),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onRefresh(),
            backgroundColor: const Color(0xFF1A2340),
            foregroundColor: Colors.white,
            icon: Icons.refresh,
            label: 'Refresh',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onToggleActive(),
            backgroundColor: a.isActive ? Colors.orange : Colors.green,
            foregroundColor: Colors.white,
            icon: a.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
            label: a.isActive ? 'Deactivate' : 'Activate',
          ),
          SlidableAction(
            onPressed: (_) => _confirmDelete(context),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: a.color.withValues(alpha: 0.15),
              border: Border.all(color: a.color, width: 1.5),
            ),
            child: Icon(a.icon, color: a.color, size: 22),
          ),
          title: Row(children: [
            Expanded(
              child: Text(a.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
            if (!a.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('Inactive',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600)),
              ),
          ]),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                a.datePublished != null
                    ? 'Last seen ${_relativeTime(a.datePublished!)}'
                    : 'No location data yet',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (a.lastLocation != null) ...[
                const SizedBox(height: 2),
                FutureBuilder(
                  future: a.place,
                  builder: (_, snap) {
                    if (snap.data != null) {
                      final p = snap.data!;
                      final parts = [p.street, p.locality, p.country]
                          .where((s) => s != null && s.isNotEmpty)
                          .take(2)
                          .join(', ');
                      return Text(parts,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis);
                    }
                    return Text(
                        '${a.lastLocation!.latitude.toStringAsFixed(4)}, '
                        '${a.lastLocation!.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500));
                  },
                ),
              ],
            ],
          ),
          trailing: a.lastBatteryStatus != null
              ? _BatteryIcon(status: a.lastBatteryStatus!)
              : null,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Tracker'),
        content: Text('Remove "${accessory.name}" from your tracker list?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  final AccessoryBatteryStatus status;
  const _BatteryIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      AccessoryBatteryStatus.ok          => (Icons.battery_full, Colors.green),
      AccessoryBatteryStatus.medium      => (Icons.battery_4_bar, Colors.orange),
      AccessoryBatteryStatus.low         => (Icons.battery_2_bar, Colors.red),
      AccessoryBatteryStatus.criticalLow => (Icons.battery_alert, Colors.red),
      _                                  => (Icons.battery_unknown, Colors.grey),
    };
    return Icon(icon, color: color, size: 20);
  }
}

// ─── Add tracker bottom sheet ─────────────────────────────────────────────────

class _AddTrackerSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddTrackerSheet({required this.onAdded});

  @override
  State<_AddTrackerSheet> createState() => _AddTrackerSheetState();
}

class _AddTrackerSheetState extends State<_AddTrackerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _keyCtrl  = TextEditingController();
  bool _saving    = false;
  bool _generate  = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final keyPair = _generate
          ? await FindMyController.generateKeyPair()
          : await FindMyController.importKeyPair(_keyCtrl.text.trim());

      final accessory = Accessory(
        id: keyPair.hashedPublicKey,
        name: _nameCtrl.text.trim(),
        hashedPublicKey: keyPair.hashedPublicKey,
        datePublished: DateTime(1970),
        additionalKeys: [],
        hashesWithTS: {},
        locationHistory: [],
        lastBatteryStatus: null,
        color: Colors.blueAccent,
        icon: 'mappin',
      );

      if (mounted) {
        context.read<AccessoryRegistry>().addAccessory(accessory);
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Tracker',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tracker Name',
                hintText: 'e.g. My Laptop',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Generate new key pair'),
              subtitle: const Text('Creates a new tracker key automatically'),
              value: _generate,
              onChanged: (v) => setState(() => _generate = v),
            ),
            if (!_generate) ...[
              const SizedBox(height: 4),
              TextFormField(
                controller: _keyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Private Key (Base64)',
                  hintText: 'Paste the base64 private key from generate_keys.py',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (v) {
                  if (_generate) return null;
                  return (v == null || v.trim().isEmpty)
                      ? 'Private key is required'
                      : null;
                },
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2340),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                            CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Tracker',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Settings bottom sheet ────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  const _SettingsSheet();

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  final _urlCtrl  = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  int _days = 7;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final url  = await TrackerSettings.getUrl();
    final user = await TrackerSettings.getUser();
    final pass = await TrackerSettings.getPass();
    final days = await TrackerSettings.getDays();
    if (mounted) {
      setState(() {
        _urlCtrl.text  = url;
        _userCtrl.text = user;
        _passCtrl.text = pass;
        _days   = days;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    await TrackerSettings.save(
      url:  _urlCtrl.text.trim(),
      user: _userCtrl.text.trim(),
      pass: _passCtrl.text,
      days: _days,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20, right: 20, top: 24),
      child: _loading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Haystack Settings',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint URL',
                    hintText: 'http://localhost:6176',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Days to fetch: ',
                      style: TextStyle(fontSize: 14)),
                  Expanded(
                    child: Slider(
                      value: _days.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_days days',
                      activeColor: const Color(0xFF1A2340),
                      onChanged: (v) => setState(() => _days = v.round()),
                    ),
                  ),
                  Text('$_days d',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A2340),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Save',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _InfoRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13))),
      ]),
    );

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)  return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String _batteryLabel(AccessoryBatteryStatus s) => switch (s) {
      AccessoryBatteryStatus.ok          => 'Good',
      AccessoryBatteryStatus.medium      => 'Medium',
      AccessoryBatteryStatus.low         => 'Low',
      AccessoryBatteryStatus.criticalLow => 'Critical',
      _                                  => 'Unknown',
    };
