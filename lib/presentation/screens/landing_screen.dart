// ignore_for_file: prefer_final_fields, unused_field
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/extensions/user_status_handler.dart';
import 'package:receiptcamp/logic/cubits/landing/landing_cubit.dart';
import 'package:receiptcamp/logic/cubits/onboarding/onboarding_cubit.dart';
import 'package:receiptcamp/logic/cubits/sharing_intent/sharing_intent_cubit.dart';
import 'package:receiptcamp/presentation/screens/file_explorer.dart';
import 'package:receiptcamp/presentation/screens/home.dart';
import 'package:receiptcamp/presentation/screens/import_screen.dart';
import 'package:receiptcamp/presentation/screens/onboarding.dart';
import 'package:receiptcamp/presentation/screens/recieve_receipts_screen.dart';
import 'package:receiptcamp/presentation/ui/landing/app_bar.dart';
import 'package:receiptcamp/presentation/ui/landing/drawer.dart';
import 'package:receiptcamp/presentation/ui/landing/nav_bar.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: switchTabfadeDuration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        if (state is OnboardingShowScreen) {
          return Scaffold(
            body: Container(
              color: Colors.transparent,
              child: const OnboardingView()),
          );
        } else {
          return Scaffold(
          drawer: const AppDrawer(),
          appBar: HomeAppBar(),
          body: BlocListener<SharingIntentCubit, SharingIntentState>(
            listener: (context, state) {
              switch (state) {
                case SharingIntentFilesRecieved():
                  final sharedFiles = state.files;
                  Navigator.of(context).push(
                      SlidingReceiveReceiptTransitionRoute(
                          receiptFiles: sharedFiles));
                case SharingIntentZipFileReceived():
                  context.handleUserStatus((BuildContext context) {
                    final zipFile = state.zipFile;
                    Navigator.of(context)
                        .push(SlidingImportTransitionRoute(zipFile: zipFile));
                  });
                default:
                  return;
              }
            },
            child: FadeTransition(
              opacity: _controller,
              child: BlocBuilder<LandingCubit, int>(
                builder: (context, state) {
                  _controller.forward(from: 0.0);
                  return IndexedStack(
                    index: state,
                    children: const [
                      Home(),
                      FileExplorer(),
                    ],
                  );
                },
              ),
            ),
          ),
          bottomNavigationBar: BlocBuilder<LandingCubit, int>(
            builder: (context, state) {
              return bottomNavigationBar(state, context);
            },
          ),
        );
        }
      },
    );
  }
}
