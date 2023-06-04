// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/explorer/explorer_bloc.dart';
import 'package:receiptcamp/logic/blocs/home/home_bloc.dart';
import 'package:receiptcamp/logic/blocs/upload/upload_bloc.dart';

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadBloc, UploadState>(
      listener: (context, state) {},
      builder: (context, state) {
        return BottomAppBar(
            color: Colors.blue,
            shape: const CircularNotchedRectangle(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    onPressed: () {
                      context.read<ExplorerBloc>().add(ExplorerNavigateToHomeEvent(context: context));
                    },
                    icon: const Icon(Icons.home),
                    color: Colors.white),
                IconButton(
                    icon: const Icon(Icons.upload_file),
                    color: Colors.white,
                    onPressed: () async {
                        context.read<UploadBloc>().add(UploadTapEvent());
                    }),
                IconButton(
                  onPressed: () async {
                    context.read<HomeBloc>().add(HomeNavigateToFileExplorerEvent(context: context));
                  },
                  icon: const Icon(Icons.folder),
                  color: Colors.white,
                )
              ],
            ));
      },
    );
  }
}