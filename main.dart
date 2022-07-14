import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receiptcamp/route_generator.dart';

import 'lib/widgets/home/navdrawer.dart';
import 'lib/widgets/home/navbar.dart';
import 'lib/widgets/home/recentlyviewed.dart';
import 'route_generator.dart';

void main() {
  runApp(MyApp());
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
      initialRoute: "/",
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: NavDrawer(),
        appBar: AppBar(
            backgroundColor: Colors.blue, title: const Text("ReceiptCamp")),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const <Widget>[
              Text("A List of recently viewed receipts")
            ]),
        // _RecentlyViewedReceipts() to be implemented here at a later date
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              print("Button has been pressed");
              // Add code to open button module here
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.camera_alt)),
        bottomNavigationBar: BottomNavBar());
  }
}
