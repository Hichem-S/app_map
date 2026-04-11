import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
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

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Smart Inventory',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeScreen(),
            '/qrscanner': (context) => const QRScannerScreen(),
            '/addproduct': (context) => const add_product.AddNewProductScreen(),
            '/equipmentmap': (context) => const EquipmentMapScreen(),
            '/3dmap': (context) => const Product3DMapScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/vueinstitut': (context) => const vue_institut.IsetMahdiaScreen(),
            '/scan_qr_hiearchique': (context) =>
                const scan_qr_hiearchique.ScannerHierarchique(),
            '/departement_gi': (context) => const dept_gi.DepartementGIScreen(),
            '/departement_ge': (context) => const dept_ge.DepartementGEScreen(),
            '/departement_tc': (context) => const dept_tc.TCDepartmentScreen(),
            '/departement_adm': (context) =>
                const dept_adm.ADMDepartmentScreen(),
          },
        );
      },
    );
  }
}
