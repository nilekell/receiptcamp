// ignore_for_file: avoid_types_as_parameter_names, non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/home/home_bloc.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeInitialEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (previous, current) => current is HomeActionState,
      buildWhen: (previous, current) => current is! HomeActionState,
      listener: (context, state) {
        switch (state) {
          case HomeNavigateToFileExplorerState():
            Navigator.of(context).pushNamed('/explorer');
          default:
            print('Home Screen: ${state.toString()}');
            return;
        }
      },
      builder: (context, state) {
        return BlocBuilder<HomeBloc, HomeState>(builder: (context, state) {
          switch (state) {
            case HomeInitialState():
              return const CircularProgressIndicator();
            case HomeLoadingState():
              return const CircularProgressIndicator();
            case HomeErrorState():
              return const Text('Error showing receipts');
            case HomeEmptyReceiptsState():
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(HomeInitialEvent());
                },
                child: const Center(child: Text('No receipts to show')),
              );
            case HomeLoadedSuccessState():
              return RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeBloc>().add(HomeInitialEvent());
                  },
                  child: ListView.builder(
                      itemCount: state.receipts.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                            title: Text(state.receipts[index].name));
                      }));
            default:
              print('Home Screen: ${state.toString()}');
              return Container();
          }
        });
      },
    );
  }
}
