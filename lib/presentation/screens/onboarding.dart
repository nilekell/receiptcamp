// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:receiptcamp/logic/cubits/onboarding/onboarding_cubit.dart';
import 'package:receiptcamp/presentation/screens/paywall.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _introKey = GlobalKey<IntroductionScreenState>();

  final List<PageViewModel> _listPagesViewModel = [FirstPage, SecondPage, ThirdPage, FourthPage];

  @override
  void initState() {
    super.initState();
    // hiding top and bottom platform overlays when screen is displayed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  @override
  void dispose() {
    // re-showing top and bottom platform overlays when screen is closed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: IntroductionScreen(
        key: _introKey,
        pages: _listPagesViewModel,
        showBackButton: true,
        showNextButton: false,
        skip: const Text("Skip"),
        done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w700)),
        back: const Icon(Icons.arrow_back),
        onDone: () {
          context.read<OnboardingCubit>().closeScreen();
        },
        onSkip: () {
          context.read<OnboardingCubit>().closeScreen();
        },
        dotsDecorator: DotsDecorator(
          size: const Size.square(10.0),
          activeSize: const Size(20.0, 10.0),
          activeColor: const Color(primaryLightBlue),
          color: Colors.black26,
          spacing: const EdgeInsets.symmetric(horizontal: 3.0),
          activeShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
        ),
        baseBtnStyle: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}




PageViewModel FirstPage = PageViewModel(
  titleWidget: const Text('Welcome to ReceiptCamp', style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
  bodyWidget: Container()
);




PageViewModel SecondPage = PageViewModel(
  titleWidget: const Text('Second Page', style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
  bodyWidget: const PaywallView()
);




PageViewModel ThirdPage = PageViewModel(
  titleWidget: const Text('Third Page', style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
  bodyWidget: Container()
);




PageViewModel FourthPage = PageViewModel(
  titleWidget: const Text('Fourth Page', style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
  bodyWidget: Container()
);



