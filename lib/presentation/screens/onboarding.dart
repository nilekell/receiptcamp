// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:receiptcamp/extensions/user_status_handler.dart';
import 'package:receiptcamp/logic/cubits/onboarding/onboarding_cubit.dart';
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
        showNextButton: false,
        done: const Text("Done", style: TextStyle(fontWeight: FontWeight.w700)),
        onDone: () {
          context.read<OnboardingCubit>().closeScreen();
          // show paywall
          // do nothing if the user is not pro
          context.handleUserStatus(() {});
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


class PageViewContent extends StatelessWidget {
  const PageViewContent({super.key, required this.imageAsset, required this.subtitle});

  final String imageAsset;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
    children: [
      Image.asset(imageAsset, height: 450,),
      const SizedBox(height: 60,),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(subtitle, style: const TextStyle(fontSize: 18), textAlign: TextAlign.center, softWrap: true,),
      )
    ],
  );
  }
}


PageViewModel FirstPage = PageViewModel(
    titleWidget: const Text(
      'Welcome to ReceiptCamp',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
    ),
    bodyWidget: const PageViewContent(
      imageAsset: 'assets/onboarding_home.png',
      subtitle: 'Simply manage your everyday receipts.',
    ));


PageViewModel SecondPage = PageViewModel(
    titleWidget: const Text(
      'Upload',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
    ),
    bodyWidget: const PageViewContent(
        imageAsset: 'assets/onboarding_upload.png',
        subtitle: 'Upload from your photos, camera roll or scan as documents.'));


PageViewModel ThirdPage = PageViewModel(
    titleWidget: const Text(
      'Search',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
    ),
    bodyWidget: const PageViewContent(
        imageAsset: 'assets/onboarding_search.png',
        subtitle: 'Instantly find any receipt with a single phrase.'));


PageViewModel FourthPage = PageViewModel(
  titleWidget: const Text('Export', style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 24),),
  bodyWidget: const PageViewContent(
        imageAsset: 'assets/onboarding_options.png',
        subtitle: 'Export your receipts collectively as folders, PDFs & more.'));



