import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/webview_init.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'widgets/role_guard.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/2dmap.dart';
import 'screens/3dmap.dart';
import 'screens/profile.dart';
import 'screens/add_new_product.dart' as add_product;
import 'screens/vue_institut.dart' as vue_institut;
import 'screens/scan_qr_hiearchique.dart' as scan_qr_hiearchique;
import 'screens/departement_informatique.dart' as dept_gi;
import 'screens/departement_electrique.dart' as dept_ge;
import 'screens/departement_gestion.dart' as dept_tc;
import 'screens/administration_screen.dart' as dept_adm;
import 'screens/list_equipment_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/move_log_screen.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/tracker_screen.dart';
import 'screens/rfid_screen.dart';
import 'screens/ble_screen.dart';
import 'screens/iot_live_feed_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/ai_query_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/import_products_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/rfid_scan_history_screen.dart';
import 'screens/tracker_management_screen.dart';
import 'screens/ble_proximity_screen.dart';
import 'providers/language_provider.dart';
import 'tracker/accessory/accessory_registry.dart';
import 'tracker/location/location_model.dart';
import 'tracker/preferences/user_preferences_model.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldKey =
    GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init();
  initializeDateFormatting();
  initWebViewPlatform();
  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AccessoryRegistry()),
        ChangeNotifierProvider(create: (_) => LocationModel()),
        ChangeNotifierProvider(create: (_) => UserPreferences()),
      ],
      child: MyApp(onboardingDone: onboardingDone),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool onboardingDone;
  const MyApp({Key? key, required this.onboardingDone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, langProvider, child) {
        return MaterialApp(
          scaffoldMessengerKey: rootScaffoldKey,
          navigatorKey: rootNavigatorKey,
          title: 'Smart Inventory',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          locale: langProvider.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (ctx, child) => Directionality(
            textDirection: langProvider.isArabic
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: child!,
          ),
          initialRoute: onboardingDone ? '/login' : '/onboarding',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeScreen(),
            '/qrscanner': (context) => const QRScannerScreen(),
            '/rfidscanner': (context) => const RfidScreen(),
            '/iot-feed':    (context) => const RoleGuard(roles: ['admin', 'technicien'], child: IotLiveFeedScreen()),
            '/chat':        (context) => const ChatListScreen(),
            '/ai':          (context) => const AiQueryScreen(),
            '/maintenance': (context) => const RoleGuard(roles: ['admin', 'technicien'], child: MaintenanceScreen()),
            '/blescanner': (context) => const BleScreen(),
            '/addproduct': (context) => const RoleGuard(
                  roles: ['magazinier'],
                  child: add_product.AddNewProductScreen(),
                ),
            '/equipmentmap': (context) => const RoleGuard(
                  roles: ['admin', 'technicien'],
                  child: EquipmentMapScreen(),
                ),
            '/3dmap': (context) => const RoleGuard(
                  roles: ['admin', 'technicien'],
                  child: Product3DMapScreen(),
                ),
            '/profile': (context) => const ProfileScreen(),
            '/vueinstitut': (context) => const RoleGuard(
                  roles: ['admin', 'technicien'],
                  child: vue_institut.IsetMahdiaScreen(),
                ),
            '/scan_qr_hiearchique': (context) => const RoleGuard(
                  roles: ['admin', 'technicien'],
                  child: scan_qr_hiearchique.ScannerHierarchique(),
                ),
            '/departement_gi': (context) => const dept_gi.DepartementGIScreen(),
            '/departement_ge': (context) => const dept_ge.DepartementGEScreen(),
            '/departement_tc': (context) => const dept_tc.TCDepartmentScreen(),
            '/departement_adm': (context) =>
                const dept_adm.ADMDepartmentScreen(),
            '/list_equipment': (context) =>
                const ListEquipmentScreen(),
            '/admin/users': (context) => const RoleGuard(
                  roles: ['admin'],
                  child: AdminUsersScreen(),
                ),
            '/movelog': (context) => const RoleGuard(
                  roles: ['admin', 'technicien'],
                  child: MoveLogScreen(),
                ),
            '/tracker': (context) => const RoleGuard(
                  roles: ['admin', 'technicien'],
                  child: TrackerScreen(),
                ),
            '/onboarding':       (context) => const OnboardingScreen(),
            '/analytics':        (context) => const AnalyticsScreen(),
            '/import-products':  (context) => const RoleGuard(
                  roles: ['admin', 'magazinier'],
                  child: ImportProductsScreen(),
                ),
            '/forgot-password':    (context) => const ForgotPasswordScreen(),
            '/reset-password':     (context) => const ResetPasswordScreen(),
            '/verify-email':       (context) => const VerifyEmailScreen(),
            '/rfid-scan-history':  (context) => const RoleGuard(roles: ['admin', 'technicien'], child: RfidScanHistoryScreen()),
            '/tracker-management': (context) => const RoleGuard(roles: ['admin', 'technicien'], child: TrackerManagementScreen()),
            '/ble-proximity':      (context) => const RoleGuard(roles: ['admin', 'technicien'], child: BleProximityScreen()),
          },
        );
      },
    );
  }
}
