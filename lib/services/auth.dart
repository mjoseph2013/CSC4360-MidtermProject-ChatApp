import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import "package:firebase_auth/firebase_auth.dart";
import "package:google_sign_in/google_sign_in.dart";
import 'package:the_apple_sign_in/the_apple_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import "package:chat_app/helperfunctions/sharedpref_helper.dart";
import "package:chat_app/services/database.dart";
import "package:chat_app/views/home.dart";

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return await auth.currentUser;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
        await _googleSignIn.signIn();

    final GoogleSignInAuthentication? googleSignInAuthentication =
        await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication?.idToken,
        accessToken: googleSignInAuthentication?.accessToken);

    UserCredential result =
        await _firebaseAuth.signInWithCredential(credential);

    User? userDetails = result.user;

    if (result == null) {
    } else {
      SharedPreferenceHelper().saveUserEmail(userDetails?.email as String);
      SharedPreferenceHelper().saveUserName(
          userDetails?.email?.replaceAll("@gmail.com", "") as String);
      SharedPreferenceHelper().saveUserId(userDetails?.uid as String);
      SharedPreferenceHelper()
          .saveDisplayName(userDetails?.displayName as String);
      SharedPreferenceHelper()
          .saveUserProfileUrl(userDetails?.photoURL as String);

      Map<String, dynamic> userInfoMap = {
        "email": userDetails?.email as String,
        "username": (userDetails?.email as String).replaceAll("@gmail.com", ""),
        "name": userDetails?.displayName as String,
        "imgUrl": userDetails?.photoURL as String,
      };

      DatabaseMethods()
          .addUserInfoToDB(userDetails?.uid as String, userInfoMap)
          .then(
        (value) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Home(),
            ),
          );
        },
      );
    }
  }

  signInWithApple(BuildContext context) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    // 1. perform the sign-in request
    final appleAccount = await TheAppleSignIn.performRequests([
      const AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);
    // 2. check the result
    switch (appleAccount.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = appleAccount.credential!;
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          accessToken:
              String.fromCharCodes(appleIdCredential.authorizationCode!),
        );
        UserCredential result =
            await _firebaseAuth.signInWithCredential(credential);
        User userDetails = result.user!;
        if (Scope.fullName != null) {
          final fullName = appleIdCredential.fullName;
          if (fullName != null &&
              fullName.givenName != null &&
              fullName.familyName != null) {
            final displayName = '${fullName.givenName} ${fullName.familyName}';
            await userDetails.updateDisplayName(displayName);
          }
        }
        if (result == null) {
        } else {
          SharedPreferenceHelper().saveUserEmail(userDetails.email as String);
          SharedPreferenceHelper().saveUserName(
              userDetails.email?.replaceAll("@gmail.com", "") as String);
          SharedPreferenceHelper().saveUserId(userDetails.uid as String);
          SharedPreferenceHelper()
              .saveDisplayName(userDetails.displayName as String);
          SharedPreferenceHelper()
              .saveUserProfileUrl(userDetails.photoURL as String);

          Map<String, dynamic> userInfoMap = {
            "email": userDetails.email as String,
            "username":
                (userDetails.email as String).replaceAll("@gmail.com", ""),
            "name": userDetails.displayName as String,
            "imgUrl": userDetails.photoURL as String,
          };

          DatabaseMethods()
              .addUserInfoToDB(userDetails.uid as String, userInfoMap)
              .then(
            (value) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => Home(),
                ),
              );
            },
          );
        }
        break;
      case AuthorizationStatus.error:
        throw PlatformException(
          code: 'ERROR_AUTHORIZATION_DENIED',
          message: appleAccount.error.toString(),
        );

      case AuthorizationStatus.cancelled:
        throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
      default:
        throw UnimplementedError();
    }
  }

  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await auth.signOut();
  }
}
