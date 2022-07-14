import 'package:flutter/material.dart';

import 'package:receiptcamp/route_generator.dart';
import 'package:receiptcamp/receipt_explorer_page.dart';

class BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        color: Colors.blue,
        shape: CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/');
                },
                icon: const Icon(Icons.home),
                color: Colors.white),
            IconButton(
              icon: const Icon(Icons.folder),
              color: Colors.white,
              onPressed: () {
                Navigator.of(context).pushNamed('ReceiptExplorer');
              },
            ),
          ],
        ));
  }
}
