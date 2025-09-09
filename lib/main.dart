import 'package:flutter/material.dart';
import 'package:gulai_kambing_kakek/data/database_instance.dart';
import 'package:gulai_kambing_kakek/presentation/main_shell.dart';
import 'package:gulai_kambing_kakek/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final databasesPath = await getDatabasesPath();
  final path = p.join(databasesPath, 'gulai_kambiang_kakek.db');

  if (await databaseExists(path)) {
    print("--- DEBUG: Menemukan database lama, MENGHAPUS PAKSA! ---");
    await deleteDatabase(path);
    print("--- DEBUG: Database lama berhasil dihapus. ---");
  } else {
    print("--- DEBUG: Database tidak ditemukan, memulai dari awal. ---");
  }

  await DatabaseInstance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: MaterialApp(
        title: 'Gulai Kambiang Kakek',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          useMaterial3: true,
        ),
        home: const MainShell(),
      ),
    );
  }
}
