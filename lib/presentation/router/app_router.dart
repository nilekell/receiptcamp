import 'package:flutter/material.dart';
import 'package:receiptcamp/presentation/screens/file_explorer.dart';
import 'package:receiptcamp/presentation/screens/home.dart';
import 'package:receiptcamp/presentation/screens/login.dart';
import 'package:receiptcamp/presentation/screens/register.dart';

class AppRouter {
  Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const Home(),
        );
      case '/register':
        return MaterialPageRoute(
          builder: (_) => const Register()
        );
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const Login()
        );
      case '/explorer':
        return MaterialPageRoute(
          builder: (_) => const FileExplorer()
        );
      default:
        return _errorRoute();
    }
  }
}

Route<dynamic> _errorRoute() {
  return MaterialPageRoute(builder: (_) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Error"),
        ),
        body: const Center(
          child: Text('ERROR'),
        ));
  });
}