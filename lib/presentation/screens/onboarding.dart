// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingView extends StatelessWidget {
  OnboardingView({super.key});

  final List<PageViewModel> _listPagesViewModel = [FirstPage, SecondPage, ThirdPage, FourthPage];

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: _listPagesViewModel,
      showBackButton: true,
      showNextButton: false,
      back: const Icon(Icons.arrow_back),
      onDone: () {
        Navigator.of(context).pop();
      },
    );
  }
}




PageViewModel FirstPage = PageViewModel();




PageViewModel SecondPage = PageViewModel();




PageViewModel ThirdPage = PageViewModel();




PageViewModel FourthPage = PageViewModel();



