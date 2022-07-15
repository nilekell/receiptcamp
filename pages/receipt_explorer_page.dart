import 'package:flutter/material.dart';

import 'package:receiptcamp/lib/widgets/home/appbar.dart';
import 'package:receiptcamp/lib/widgets/home/navdrawer.dart';
import 'package:receiptcamp/lib/widgets/home/navbar.dart';

class ReceiptExplorer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HomeAppBar(),
        drawer: NavDrawer(),
        bottomNavigationBar: BottomNavBar(),
        body: Container(
            child: const Placeholder(
          fallbackHeight: 400,
          fallbackWidth: 400,
        )),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
            onPressed: () {
              print("Button has been pressed");
              // Add code to open button module here
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.camera_alt)));
  }
}
