import 'package:flutter/material.dart';
import 'package:receiptcamp/lib/widgets/home/appbar.dart';
import 'package:receiptcamp/lib/widgets/home/navbar.dart';
import 'package:receiptcamp/lib/widgets/home/navdrawer.dart';

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: NavDrawer(),
        appBar: HomeAppBar(),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const <Widget>[
              // _RecentlyViewedReceipts() to be implemented here at a later date
              Text("A List of recently viewed receipts")
            ]),
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
