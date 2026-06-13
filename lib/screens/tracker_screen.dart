import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_inventory/tracker/accessory/accessory_registry.dart';
import 'package:smart_inventory/tracker/dashboard/dashboard.dart';
import 'package:smart_inventory/tracker/splashscreen.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({Key? key}) : super(key: key);

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final registry = context.read<AccessoryRegistry>();
      if (!registry.initialLoadFinished && !registry.loading) {
        registry.loadAccessories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessoryRegistry>(
      builder: (context, registry, _) {
        if (registry.loading) return const Splashscreen();
        return const Dashboard();
      },
    );
  }
}
