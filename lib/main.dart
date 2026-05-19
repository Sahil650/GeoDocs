import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'features/camera/screens/camera_screen.dart';
import 'features/folder/screens/folder_screen.dart';
import 'features/convert/screens/convert_screen.dart';
import 'features/doc_scanner/screens/scanner_screen.dart';
import 'features/profile/screens/profile_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'features/profile/services/app_settings.dart';
import 'core/utils/responsive_helper.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(

    ChangeNotifierProvider(

      create: (_) {

        final settings =
            AppSettings();

        settings.loadSettings(); // load here

        return settings;

      },

      child: const MyApp(),

    ),

  );

}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    final settings =
        context.watch<AppSettings>();

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'Geo Camera',

      themeMode:

          settings.darkMode

              ? ThemeMode.dark

              : ThemeMode.light,

      theme: ThemeData(

        colorScheme:

            ColorScheme.fromSeed(

          seedColor:
              Colors.deepPurple,

        ),

        useMaterial3: true,

      ),

      darkTheme: ThemeData.dark(),

      home: const MainScreen(),

    );

  }

}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 2;
  bool _permissionsGranted = false;
  bool _isRequesting = true;

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    await _requestPermissions();
    if (mounted) {
      setState(() {
        _isRequesting = false;
        _permissionsGranted = true; 
      });
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.location,
      // Standard storage for Android 12 and below
      Permission.storage,
      // Media permissions for Android 13+
      Permission.photos,
      Permission.videos,
    ].request();
  }

  final List<Widget> screens = [
    const FolderScreen(),
    const ScannerScreen(),
    const CameraScreen(),
    const ConvertScreen(),
    const ProfileScreen(),
  ];

  final List<NavigationDestination> navDestinations = const [
    NavigationDestination(icon: Icon(Icons.folder), label: "Folder"),
    NavigationDestination(icon: Icon(Icons.document_scanner), label: "Scanner"),
    NavigationDestination(icon: Icon(Icons.camera_alt), label: "Camera"),
    NavigationDestination(icon: Icon(Icons.sync), label: "Convert"),
    NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
  ];

  void onTabChange(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      body: Row(
        children: [
          if (isDesktop || isTablet)
            NavigationRail(
              extended: isDesktop,
              selectedIndex: selectedIndex,
              onDestinationSelected: onTabChange,
              leading: isDesktop
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Geo Camera',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    )
                  : null,
              trailing: isDesktop
                  ? const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.settings, color: Colors.grey),
                          SizedBox(height: 16),
                        ],
                      ),
                    )
                  : null,
              destinations: navDestinations
                  .map((dest) => NavigationRailDestination(
                        icon: dest.icon,
                        label: Text(dest.label),
                      ))
                  .toList(),
            ),
          Expanded(
            child: _isRequesting 
                ? const Center(child: CircularProgressIndicator()) 
                : screens[selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: isDesktop || isTablet
          ? null
          : BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: onTabChange,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.deepPurple,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Folder"),
                BottomNavigationBarItem(icon: Icon(Icons.document_scanner), label: "Scanner"),
                BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: "Camera"),
                BottomNavigationBarItem(icon: Icon(Icons.sync), label: "Convert"),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
              ],
            ),
    );
  }
}

