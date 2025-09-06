import 'package:flutter/material.dart';
import 'package:gulai_kambing_kakek/data/database_instance.dart';
import 'package:gulai_kambing_kakek/presentation/main_shell.dart';
import 'package:gulai_kambing_kakek/providers/cart_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
