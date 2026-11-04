import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/clients_quotations_screen.dart';
import 'screens/cutting_optimizer_screen.dart';
import 'screens/pricing_settings_screen.dart';
import 'screens/sectors_manager_screen.dart';
import 'services/workshop_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = WorkshopStorage();
  await storage.init();
  runApp(SmartWorkshopApp(storage: storage));
}

class SmartWorkshopApp extends StatelessWidget {
  final WorkshopStorage storage;
  const SmartWorkshopApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: storage,
      builder: (context, _) {
        return MaterialApp(
          title: 'الورشة الذكية',
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar', 'EG'),
          supportedLocales: const [
            Locale('ar', 'EG'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Rubik',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF991B1B),
              primary: const Color(0xFF991B1B),
              secondary: const Color(0xFF15803D),
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
          ),
          home: MainWorkshopShell(storage: storage),
        );
      },
    );
  }
}

class MainWorkshopShell extends StatefulWidget {
  final WorkshopStorage storage;
  const MainWorkshopShell({super.key, required this.storage});

  @override
  State<MainWorkshopShell> createState() => _MainWorkshopShellState();
}

class _MainWorkshopShellState extends State<MainWorkshopShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final titles = [
      'الورشة الذكية — سجل العملاء وعروض الأسعار (2 PDF)',
      'إدارة القطاعات (+ إضافة قطاع بالصورة والأجزاء)',
      'قائمة التسعير الخارجية (القطاعات والزجاج والدبل والجورجيا)',
      'تقسيم الأعواد (600 سم) وتقسيم الألواح',
    ];

    final pages = [
      ClientsQuotationsScreen(storage: widget.storage),
      SectorsManagerScreen(storage: widget.storage),
      PricingSettingsScreen(storage: widget.storage),
      CuttingOptimizerScreen(storage: widget.storage),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF991B1B),
        foregroundColor: Colors.white,
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
        ),
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.assignment_ind_outlined),
            selectedIcon: Icon(Icons.assignment_ind, color: Color(0xFF991B1B)),
            label: 'العملاء و PDF',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_carousel_outlined),
            selectedIcon: Icon(Icons.view_carousel, color: Color(0xFF991B1B)),
            label: 'إضافة القطاعات',
          ),
          NavigationDestination(
            icon: Icon(Icons.price_change_outlined),
            selectedIcon: Icon(Icons.price_change, color: Color(0xFF991B1B)),
            label: 'قائمة التسعير',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_cut_outlined),
            selectedIcon: Icon(Icons.content_cut, color: Color(0xFF991B1B)),
            label: 'تقسيم الأعواد',
          ),
        ],
      ),
    );
  }
}
