// ignore_for_file: unused_field
import 'package:advanced_in_app_review/advanced_in_app_review.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/data/data_constants.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/data/services/directory_path_provider.dart';
import 'package:receiptcamp/data/services/preferences.dart';
import 'package:receiptcamp/data/services/purchases.dart';
import 'package:receiptcamp/data/services/sharing_intent.dart';
import 'package:receiptcamp/logic/blocs/home/home_bloc.dart';
import 'package:receiptcamp/bloc_observer.dart';
import 'package:receiptcamp/logic/blocs/search/search_bloc.dart';
import 'package:receiptcamp/logic/cubits/file_explorer/file_explorer_cubit.dart';
import 'package:receiptcamp/logic/cubits/folder_view/folder_view_cubit.dart';
import 'package:receiptcamp/logic/cubits/landing/landing_cubit.dart';
import 'package:receiptcamp/logic/cubits/onboarding/onboarding_cubit.dart';
import 'package:receiptcamp/logic/cubits/settings/settings_cubit.dart';
import 'package:receiptcamp/logic/cubits/sharing_intent/sharing_intent_cubit.dart';
import 'package:receiptcamp/presentation/screens/landing_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/ui/ui_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

// import 'package:flutter/scheduler.dart' show timeDilation;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  appVersion = appVersion + packageInfo.version;
  try {
    // Initializing DirectoryPathProvider.instance in `main()` ensures that the documents directory path is
    // fetched as soon as the application starts, making the path
    // immediately available to any part of the application that requires it.
    await DirectoryPathProvider.instance.initialize();
    await DatabaseRepository.instance.init();
    await PreferencesService.instance.init();
    Bloc.observer = AppBlocObserver();
    await PurchasesService.instance.initPlatformState();
  } on Exception catch (e) {
    print(e.toString());
    final appMultiBlocProvider = MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => SettingsCubit()..init(),
      ),
      BlocProvider(
        create: (context) => OnboardingCubit()..init(),
      ),
      BlocProvider<LandingCubit>(
          create: (BuildContext context) => LandingCubit()),
      BlocProvider<HomeBloc>(
        create: (BuildContext context) =>
            HomeBloc(databaseRepository: DatabaseRepository.instance)
              ..add(HomeInitialEvent()),
      ),
      BlocProvider<FileExplorerCubit>(
        create: (context) => FileExplorerCubit()..initializeFileExplorerCubit(),
      ),
      BlocProvider(
        create: (context) => FolderViewCubit(
            homeBloc: context.read<HomeBloc>(),
            prefs: PreferencesService.instance)
          ..initFolderView(),
      ),
      BlocProvider<SharingIntentCubit>(
        create: (context) => SharingIntentCubit(
            mediaStream: SharingIntentService.instance.mediaStream,
            initialMedia: SharingIntentService.instance.initialMedia,
            homeBloc: context.read<HomeBloc>(),
            fileExplorerCubit: context.read<FileExplorerCubit>(),
            landingCubit: context.read<LandingCubit>())
          ..init(),
      ),
      BlocProvider(
          create: (BuildContext context) =>
              SearchBloc(databaseRepository: DatabaseRepository.instance)
                ..add(const SearchInitialEvent()))
    ],
    child: const MyApp());

    runApp(appMultiBlocProvider);
  }

  final appMultiBlocProvider = MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (context) => SettingsCubit()..init(),
      ),
      BlocProvider(
        create: (context) => OnboardingCubit()..init(),
      ),
      BlocProvider<LandingCubit>(
          create: (BuildContext context) => LandingCubit()),
      BlocProvider<HomeBloc>(
        create: (BuildContext context) =>
            HomeBloc(databaseRepository: DatabaseRepository.instance)
              ..add(HomeInitialEvent()),
      ),
      BlocProvider<FileExplorerCubit>(
        create: (context) => FileExplorerCubit()..initializeFileExplorerCubit(),
      ),
      BlocProvider(
        create: (context) => FolderViewCubit(
            homeBloc: context.read<HomeBloc>(),
            prefs: PreferencesService.instance)
          ..initFolderView(),
      ),
      BlocProvider<SharingIntentCubit>(
        create: (context) => SharingIntentCubit(
            mediaStream: SharingIntentService.instance.mediaStream,
            initialMedia: SharingIntentService.instance.initialMedia,
            homeBloc: context.read<HomeBloc>(),
            fileExplorerCubit: context.read<FileExplorerCubit>(),
            landingCubit: context.read<LandingCubit>())
          ..init(),
      ),
      BlocProvider(
          create: (BuildContext context) =>
              SearchBloc(databaseRepository: DatabaseRepository.instance)
                ..add(const SearchInitialEvent()))
    ],
    child: const MyApp());
    
  runApp(appMultiBlocProvider);

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