import "package:chat_app/services/auth.dart";
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/home.dart';
import "package:chat_app/views/signin.dart";
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";

class UserProfile extends StatefulWidget {
  final String myUserName;
  UserProfile(this.myUserName);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String? myName, myProfilePic, myEmail, myUserNameText, myRating;

  getThisUserInfo() async {
    QuerySnapshot querySnapshot =
        await DatabaseMethods().getUserInfo(widget.myUserName);
    myUserNameText = "${querySnapshot.docs[0]['username']}";
    myName = "${querySnapshot.docs[0]['name']}";
    myProfilePic = "${querySnapshot.docs[0]['imgUrl']}";
    myEmail = "${querySnapshot.docs[0]['email']}";
    myRating = "${querySnapshot.docs[0]['rating']}";
    setState(() {});
  }

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //add home button
        leading: InkWell(
          onTap: () {
            //Methods to generate home page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.home),
          ),
        ),
        title: Text("$myName's Profile"),
        actions: [
          InkWell(
            onTap: () {
              AuthMethods().signOut().then((s) {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => SignIn()));
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: (Icon(Icons.exit_to_app)),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: myProfilePic!.isNotEmpty
                  ? Image.network(
                      myProfilePic!,
                      height: 100,
                      width: 100,
                    )
                  : Center(
                      child: const CircularProgressIndicator(),
                    ),
            ),
            Text("Name: $myName"),
            Text("Username: $myUserNameText"),
            Text("Email: $myEmail"),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Avg. User Rating: 4.8"),
                Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
