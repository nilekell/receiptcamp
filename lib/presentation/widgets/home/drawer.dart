import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/auth/authentication_bloc.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        /*
        if (state is AuthenticationLogoutSuccessState) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        */
      },
      builder: (context, state) {
        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              const SizedBox(height: 100),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () => {Navigator.of(context).pop()},
              ),
              ListTile(
                leading: const Icon(Icons.border_color),
                title: const Text('Feedback'),
                onTap: () => {Navigator.of(context).pop()},
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<AuthenticationBloc>().add(AuthenticationLogoutButtonClickedEvent());
                },
              ),
              // temporary buttons for debugging
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete all receipts'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Print all receipts'),
                onTap: () {},
              )
            ],
          ),
        );
      },
    );
  }
}
