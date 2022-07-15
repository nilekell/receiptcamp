// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:receiptcamp/lib/widgets/home/appbar.dart';
import 'package:receiptcamp/pages/route_generator.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

// This class holds the data related to the Form.
class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 30),
          child: Container(
            height: 140.0,
            width: 140.0,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue),
              // color: Colors.blue
            ),
          ),
        ),
        Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 100.0,
              vertical: 10.0,
            ),
            child: TextField(
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your email',
                  hintStyle: TextStyle(fontSize: 13),
                  prefixIcon: Icon(Icons.email, color: Colors.blue)),
            )),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 100.0, vertical: 0),
            child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(fontSize: 13),
                    prefixIcon: Icon(Icons.password, color: Colors.blue)))),
        TextButton(
          style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 10)),
          child: Text('Forgot password?'),
          onPressed: () {},
        ),
        TextButton(
          style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 10)),
          child: Text('New to ReceiptCamp? Signup instead'),
          onPressed: () {},
        ),
        Container(
            height: 50,
            width: 100,
            decoration: BoxDecoration(
                color: Colors.blue, border: Border.all(color: Colors.blue)),
            child: TextButton(
              style: TextButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 20)),
              child: Text('Login',
                  style: TextStyle(color: Colors.white, fontSize: 25)),
              onPressed: () {
                //will need to validate inputs with backend
                Navigator.of(context).pushNamed('/');
              },
            ))
      ],
    ));
  }
}
