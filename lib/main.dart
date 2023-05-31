import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/auth/authentication_bloc.dart';
import 'package:receiptcamp/presentation/router/app_router.dart';
import 'package:receiptcamp/presentation/screens/email_verification.dart';
import 'package:receiptcamp/presentation/screens/home.dart';
import 'package:receiptcamp/presentation/screens/login.dart';
import 'package:receiptcamp/presentation/screens/register.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(BlocProvider<AuthenticationBloc>(
      create: (BuildContext context) => AuthenticationBloc()..add(AuthenticationInitialEvent()),
      child: const MyApp(),
    ));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const BlocNavigate(),
        onGenerateRoute: AppRouter().onGenerateRoute,
        title: 'ReceiptCamp',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ));
  }
}

class BlocNavigate extends StatelessWidget {
  const BlocNavigate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {},
      buildWhen: (previous, current) {
        print('previous: ${previous.runtimeType}');
        print('current: ${current.runtimeType}');
        return previous != current;
      },
      builder: (context, state) {
        if (state is AuthenticationLogoutSuccessState) {
          return const Login();
        }
        if (state is AuthenticationRegistrationFailedState) {
          return const Register();
        }
        if (state is AuthenticationEmailVerificationInProgressState) {
          return const EmailVerification();
        }
        if (state is AuthenticationSuccessState) {
          return const Home();
        } else {
          return const Login();
        }
      },
    );
  }
}