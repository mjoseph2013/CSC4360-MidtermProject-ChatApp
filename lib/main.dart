import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:provider/provider.dart";

import "package:chat_app/views/signin.dart";
import "package:chat_app/services/auth.dart";
import "package:chat_app/views/home.dart";
import "package:chat_app/services/apple_sign_in_available.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final appleSignInAvailable = await AppleSignInAvailable.check();
  runApp(
    Provider<AppleSignInAvailable>.value(
      value: appleSignInAvailable,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider<AuthMethods>(
      create: (_) => AuthMethods(),
      child: MaterialApp(
        title: "Chat App",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.lightBlue,
        ),
        home: FutureBuilder(
          future: AuthMethods().getCurrentUser(),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              return Home();
            } else {
              return SignIn();
            }
          },
        ),
      ),
    );
  }
}
