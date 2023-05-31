import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:receiptcamp/logic/blocs/auth/authentication_bloc.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {

  @override
  void initState() {
    // starting email verification timer
    context.read<AuthenticationBloc>().add(AuthenticationInitialEmailVerificationEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is AuthenticationSuccessState) {
          Navigator.of(context).pushNamed("/");
        } 
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.blue,
            title: const Text('Verify'),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please check your email'),
              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: () {},
                  child: const Text('Resend verification email')),
              const SizedBox(height: 24),
              const Text(
                  'You have 300 seconds to click on the verified link in your email address'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthenticationBloc>().add(AuthenticationRegistrationCancelledEvent());
                }, 
                child: const Text('Cancel registration')),
            ],
          ),
        );
      },
    );
  }
}
