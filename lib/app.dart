import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _buildThemeData(),
      home: const LoginPage(),
    );
  }

  ThemeData _buildThemeData() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        color: Colors.black,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white10,
        labelStyle: TextStyle(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue, // Button text color
        ),
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        backgroundColor: Colors.black,
        collapsedBackgroundColor: Colors.black,
        textColor: Colors.white,
        iconColor: Colors.white,
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: const <Widget>[
          _DrawerHeader(),
          _DrawerItem(
            icon: Icons.home,
            text: 'Home',
            onTap: _navigateHome,
          ),
          _DrawerItem(
            icon: Icons.settings,
            text: 'Settings',
            onTap: _navigateSettings,
          ),
          _DrawerItem(
            icon: Icons.info,
            text: 'About',
            onTap: _navigateAbout,
          ),
        ],
      ),
    );
  }

  static void _navigateHome(BuildContext context) {
    Navigator.pop(context);
    // Navigate to the home page if necessary
  }

  static void _navigateSettings(BuildContext context) {
    Navigator.pop(context);
    // Navigate to the settings page if necessary
  }

  static void _navigateAbout(BuildContext context) {
    Navigator.pop(context);
    // Navigate to the about page if necessary
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return const DrawerHeader(
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Text(
        'Menu',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final void Function(BuildContext) onTap;

  const _DrawerItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(text, style: const TextStyle(color: Colors.white)),
      onTap: () => onTap(context),
    );
  }
}