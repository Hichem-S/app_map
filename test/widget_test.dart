// Smoke test — verifies the app boots without crashing.
// Full tests are in test/models/, test/providers/, test/widgets/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_inventory/providers/auth_provider.dart';
import 'package:smart_inventory/providers/theme_provider.dart';
import 'package:smart_inventory/providers/language_provider.dart';
import 'package:smart_inventory/screens/login_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Login screen renders without crashing', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: Consumer2<ThemeProvider, LanguageProvider>(
          builder: (_, theme, lang, __) => MaterialApp(
            theme: theme.currentTheme,
            locale: lang.locale,
            home: const LoginScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    // Login screen should be visible
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
