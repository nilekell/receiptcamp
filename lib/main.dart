import 'package:flutter/material.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/presentation/screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseRepository.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReceiptCamp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}
