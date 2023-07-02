import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/cubits/landing/landing_cubit.dart';
import 'package:receiptcamp/presentation/screens/a_file_explorer.dart';
import 'package:receiptcamp/presentation/screens/home.dart';
import 'package:receiptcamp/presentation/ui/landing/app_bar.dart';
import 'package:receiptcamp/presentation/ui/landing/drawer.dart';
import 'package:receiptcamp/presentation/ui/landing/nav_bar.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandingCubit, int>(
      builder: (context, state) => Scaffold(
        drawer: const NavDrawer(),
        appBar: const HomeAppBar(),
        body: _getChildBasedOnTab(state),
        bottomNavigationBar: bottomNavigationBar(state, context),
      ),
    );
  }

  Widget _getChildBasedOnTab(int index) {
    switch (index) {
      case 0:
        return const Home();
      case 1:
        return const FileExplorer();
      default:
        return const Scaffold(
          body: Center(
            child: Text('error'),
          ),
        );
    }
  }
}
