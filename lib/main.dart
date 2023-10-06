// ignore_for_file: unused_field
import 'package:advanced_in_app_review/advanced_in_app_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/data/services/document_path_provider.dart';
import 'package:receiptcamp/data/services/preferences.dart';
import 'package:receiptcamp/logic/blocs/home/home_bloc.dart';
import 'package:receiptcamp/bloc_observer.dart';
import 'package:receiptcamp/logic/blocs/search/search_bloc.dart';
import 'package:receiptcamp/logic/cubits/landing/landing_cubit.dart';
import 'package:receiptcamp/presentation/screens/landing_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/ui/ui_constants.dart';

// import 'package:flutter/scheduler.dart' show timeDilation;

void main() async {
  Bloc.observer = AppBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();
  // Initializing DocumentDirectoryProvider.instance in `main()` ensures that the documents directory path is
  // fetched and set as soon as the application starts, making the path
  // immediately available to any part of the application that requires it.
  await DocumentDirectoryProvider.instance.initialize();
  await DatabaseRepository.instance.init();
  await PreferencesService.instance.init();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  // timeDilation = 8;
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<LandingCubit>(
          create: (BuildContext context) => LandingCubit()),
      BlocProvider<HomeBloc>(
        create: (BuildContext context) =>
            HomeBloc(databaseRepository: DatabaseRepository.instance)
              ..add(HomeInitialEvent()),
      ),
      BlocProvider(create: (BuildContext context) => SearchBloc(databaseRepository: DatabaseRepository.instance)
              ..add(const SearchInitialEvent()))
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    AdvancedInAppReview()
        .setMinDaysBeforeRemind(7) 
        .setMinDaysAfterInstall(2) 
        .setMinLaunchTimes(2) 
        .setMinSecondsBeforeShowDialog(4) 
        .monitor();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await AdvancedInAppReview.platformVersion ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: (context) => DatabaseRepository.instance,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: appName,
        theme: ThemeData(
          textTheme: GoogleFonts.rubikTextTheme(),
          primarySwatch: Colors.blue,
        ),
        home: const LandingScreen(),
      ),
    );
  }
}
