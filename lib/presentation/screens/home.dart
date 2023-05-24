import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/auth/authentication_bloc.dart';
import 'package:receiptcamp/presentation/widgets/home/app_bar.dart';
import 'package:receiptcamp/presentation/widgets/home/drawer.dart';
import 'package:receiptcamp/presentation/widgets/home/nav_bar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationLogoutSuccessState) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      builder: (context, state) {
        switch (state.runtimeType) {
          case AuthenticationLoadingState:
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          default:
            return Scaffold(
                drawer: NavDrawer(),
                appBar: const HomeAppBar(),
                body: const Placeholder(),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.endFloat,
                floatingActionButton: FloatingActionButton(
                  onPressed: () {},
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.camera_alt),
                ),
                bottomNavigationBar: NavBar());
        }
      },
    );
  }
}
