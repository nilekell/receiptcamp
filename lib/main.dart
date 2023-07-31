import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receiptcamp/data/repositories/database_repository.dart';
import 'package:receiptcamp/logic/blocs/home/home_bloc.dart';
import 'package:receiptcamp/bloc_observer.dart';
import 'package:receiptcamp/logic/blocs/search/search_bloc.dart';
import 'package:receiptcamp/logic/cubits/landing/landing_cubit.dart';
import 'package:receiptcamp/presentation/router/app_router.dart';
import 'package:receiptcamp/presentation/screens/landing_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'presentation/ui/ui_constants.dart';

// import 'package:flutter/scheduler.dart' show timeDilation;

void main() async {
  Bloc.observer = AppBlocObserver();
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseRepository.instance.init();
  // timeDilation = 8;
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: await getTemporaryDirectory(),
  );
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: (context) => DatabaseRepository.instance,
      child: MaterialApp(
        title: appName,
        theme: ThemeData(
          textTheme: GoogleFonts.latoTextTheme(),
          primarySwatch: Colors.blue,
        ),
        onGenerateRoute: AppRouter().onGenerateRoute,
        home: const LandingScreen(),
      ),
    );
  }
}
