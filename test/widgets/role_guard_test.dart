import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_inventory/providers/auth_provider.dart';
import 'package:smart_inventory/widgets/role_guard.dart';

Widget _wrap({required String role, required Widget child}) {
  final auth = AuthProvider()
    ..setUser({'id': 'u-1', 'name': 'Test', 'email': 't@t.tn', 'role': role});
  return MaterialApp(
    home: ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: child,
    ),
  );
}

void main() {
  group('RoleGuard – access granted', () {
    testWidgets('admin sees content when admin is allowed', (tester) async {
      await tester.pumpWidget(_wrap(
        role: 'admin',
        child: const RoleGuard(
          roles: ['admin'],
          child: Text('Secret content'),
        ),
      ));

      expect(find.text('Secret content'), findsOneWidget);
    });

    testWidgets('technicien sees content when technicien is allowed', (tester) async {
      await tester.pumpWidget(_wrap(
        role: 'technicien',
        child: const RoleGuard(
          roles: ['admin', 'technicien'],
          child: Text('Map screen'),
        ),
      ));

      expect(find.text('Map screen'), findsOneWidget);
    });

    testWidgets('magazinier sees content when magazinier is allowed', (tester) async {
      await tester.pumpWidget(_wrap(
        role: 'magazinier',
        child: const RoleGuard(
          roles: ['magazinier'],
          child: Text('Add product'),
        ),
      ));

      expect(find.text('Add product'), findsOneWidget);
    });
  });

  group('RoleGuard – access denied', () {
    testWidgets('magazinier blocked from admin-only content', (tester) async {
      await tester.pumpWidget(_wrap(
        role: 'magazinier',
        child: const RoleGuard(
          roles: ['admin'],
          child: Text('Admin panel'),
        ),
      ));

      expect(find.text('Admin panel'), findsNothing);
    });

    testWidgets('technicien blocked from magazinier-only content', (tester) async {
      await tester.pumpWidget(_wrap(
        role: 'technicien',
        child: const RoleGuard(
          roles: ['magazinier'],
          child: Text('Add product'),
        ),
      ));

      expect(find.text('Add product'), findsNothing);
    });

    testWidgets('magazinier blocked from map screen (admin+tech only)', (tester) async {
      await tester.pumpWidget(_wrap(
        role: 'magazinier',
        child: const RoleGuard(
          roles: ['admin', 'technicien'],
          child: Text('2D Map'),
        ),
      ));

      expect(find.text('2D Map'), findsNothing);
    });
  });

  group('RoleGuard – empty roles list', () {
    testWidgets('no role matches when roles list is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        role: 'admin',
        child: const RoleGuard(
          roles: [],
          child: Text('Unreachable'),
        ),
      ));

      expect(find.text('Unreachable'), findsNothing);
    });
  });
}
