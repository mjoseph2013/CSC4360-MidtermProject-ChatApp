import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:chat_app/services/auth.dart";
import "package:chat_app/services/apple_sign_in_available.dart";
import "package:the_apple_sign_in/the_apple_sign_in.dart";
import 'package:flutter_signin_button/flutter_signin_button.dart';

class SignIn extends StatefulWidget {
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  Future<void> _signInWithApple(BuildContext context) async {
    try {
      final authService = Provider.of<AuthMethods>(context, listen: false);
      final user = await authService.signInWithApple(context);
      print('uid: ${user.uid}');
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appleSignInAvailable =
        Provider.of<AppleSignInAvailable>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat App"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignInButton(
              Buttons.GoogleDark,
              text: "Sign in with Google",
              onPressed: () {
                AuthMethods().signInWithGoogle(context);
              },
            ),
            if (appleSignInAvailable.isAvailable)
              SignInButton(
                Buttons.AppleDark,
                text: "Sign in with Apple",
                onPressed: () {
                  _signInWithApple(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
