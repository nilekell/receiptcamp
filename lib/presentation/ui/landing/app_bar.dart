import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/search/search_bloc.dart';
import 'package:receiptcamp/presentation/screens/search.dart';
import 'package:receiptcamp/presentation/ui/ui_constants.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget{
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      title: const Text(appName,
      style: TextStyle(fontSize: 27),),
      actions: [
        IconButton(
          onPressed: () {
            showSearch(
              context: context, 
              delegate: CustomSearchDelegate(searchBloc: context.read<SearchBloc>()));
          },
          icon: const Icon(Icons.search),
        )
      ],
    );
  }
}
