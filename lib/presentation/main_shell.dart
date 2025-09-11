import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import 'pages/daftar_transaksi_page.dart';
import 'pages/laporan_penjualan_page.dart';
import 'pages/manajemen_menu_page.dart';
import 'pages/laporan_detail_transaksi_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  Timer? _syncTimer; // Variabel untuk menampung timer

  static final List<Widget> _pages = <Widget>[
    const DaftarTransaksiPage(),
    const ManajemenMenuPage(),
    const LaporanPenjualanPage(),
    LaporanDetailTransaksiPage(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Memulai timer sinkronisasi
  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      // Setiap 30 menit
      ApiService().sinkronkanTransaksiTertunda();
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.grey[850]!,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
    );

    // Jalankan sinkronisasi saat aplikasi pertama kali dibuka
    ApiService().sinkronkanTransaksiTertunda();

    // Mulai timer untuk sinkronisasi interval
    _startSyncTimer();
  }

  // Hentikan timer saat halaman ditutup
  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: SafeArea(
        child: Row(
          children: <Widget>[
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).canvasColor,
              elevation: 2,
              leading: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Admin',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: Text('Kasir'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: Text('Manajemen Menu'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assessment_outlined),
                  selectedIcon: Icon(Icons.assessment),
                  label: Text('Laporan Ringkas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Laporan Detail'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _pages.elementAt(_selectedIndex)),
          ],
        ),
      ),
    );
  }
}
