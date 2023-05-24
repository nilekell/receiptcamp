import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/auth/authentication_bloc.dart';
import 'package:receiptcamp/presentation/widgets/auth/input_decor.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {

  final _formKey = GlobalKey<FormState>();

  // TextFormField state
  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    final authenticationBloc = BlocProvider.of<AuthenticationBloc>(context);
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationFormErrorState) {
          print('state is AuthenticationFormErrorState');
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(
                content: Text('Please check your email and/or password'),
                duration: Duration(milliseconds: 300),));
        } else if (state is AuthenticationSuccessState) {
          Navigator.of(context).pushNamed('/');
        } else if (state is AuthenticationFailureState) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(
                content: Text('Failed to login'),
                duration: Duration(milliseconds: 300),));
        } else if (state is AuthenticationSwitchScreenState) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.blue,
            title: const Text('Register'),
          ),
          body: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 100),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: TextFormField(
                        decoration:
                            textInputDecoration.copyWith(hintText: 'email'),
                        // value represents whatever is being typed into the form field
                        onChanged: (value) {
                          setState(() {
                            email = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 250,
                      child: TextFormField(
                        decoration:
                            textInputDecoration.copyWith(hintText: 'password'),
                        obscureText: true,
                        onChanged: (value) {
                          setState(() {
                            password = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () {
                          authenticationBloc.add(
                              AuthenticationRegisterButtonClickedEvent(
                                  email: email, password: password));
                        },
                        child: const Text('Register')),
                    const SizedBox(height: 20),
                    Text(error,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14)),
                    ElevatedButton(
                        child: const Text('Login instead'),
                        onPressed: () {
                          authenticationBloc.add(AuthenticationSwitchScreenButtonClickedEvent());
                        }),
                  ],
                )),
          ),
        );
      },
    );
  }
}
