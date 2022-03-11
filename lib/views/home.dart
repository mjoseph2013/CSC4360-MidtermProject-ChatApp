import "package:chat_app/services/auth.dart";
import 'package:chat_app/views/chatscreen.dart';
import 'package:chat_app/views/profile.dart';
import "package:chat_app/views/signin.dart";
import "package:chat_app/services/database.dart";
import 'package:chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isSearching = false;
  String? myName, myProfilePic, myUserName, myEmail;
  Stream? usersStream, chatRoomsStream;

  TextEditingController searchUserNameEditingController =
      TextEditingController();

  getMyInfoFromSharedPreference() async {
    myName = (await SharedPreferenceHelper().getDisplayName());
    myProfilePic = (await SharedPreferenceHelper().getUserProfileUrl());
    myUserName = (await SharedPreferenceHelper().getUserName());
    myEmail = (await SharedPreferenceHelper().getUserEmail());
  }

  getChatRoomIdByUserNames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  onSearchButtonClick() async {
    isSearching = true;
    setState(() {});
    usersStream = await DatabaseMethods()
        .getUserByUserName(searchUserNameEditingController.text);
    setState(() {});
  }

  getChatRooms() async {
    chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  onScreenLoaded() async {
    await getMyInfoFromSharedPreference();
    getChatRooms();
  }

  @override
  void initState() {
    onScreenLoaded();
    super.initState();
  }

  Widget chatRoomsList() {
    return StreamBuilder(
      stream: chatRoomsStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data.docs.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return ChatRoomListTile(
                    ds["lastMessage"],
                    ds.id,
                    myUserName as String,
                  );
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }

  Widget searchListUserTile(
      {required String profileUrl, name, email, username}) {
    return GestureDetector(
      onTap: () {
        var chatRoomId = getChatRoomIdByUserNames(
            myUserName as String, username); //cast error here
        Map<String, dynamic> chatRoomInfoMap = {
          "users": [myUserName, username],
        };

        DatabaseMethods().createChatRoom(chatRoomId, chatRoomInfoMap);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(username, name),
          ),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: profileUrl.isNotEmpty
                ? Image.network(
                    profileUrl,
                    height: 30,
                    width: 30,
                  )
                : null,
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(email),
            ],
          ),
        ],
      ),
    );
  }

  Widget searchUsersList() {
    return StreamBuilder(
      stream: usersStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                itemCount: snapshot.data!.docs.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data!.docs[index];
                  return searchListUserTile(
                    profileUrl: ds["imgUrl"],
                    name: ds["name"],
                    email: ds["email"],
                    username: ds["username"],
                  );
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //add user profile button that takes you to profile page
        leading: InkWell(
          onTap: () {
            //Methods to generate profile page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserProfile(myUserName!)),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.account_box_rounded),
          ),
        ),
        title: const Text("Chat App"),
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
      body: Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                isSearching
                    ? GestureDetector(
                        onTap: () {
                          isSearching = false;
                          searchUserNameEditingController.text = "";
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.arrow_back),
                        ),
                      )
                    : Container(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchUserNameEditingController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Search Users, Tap Icon for Enter",
                            ),
                          ),
                        ),
                        GestureDetector(
                            onTap: () {
                              if (searchUserNameEditingController.text != "") {
                                onSearchButtonClick();
                              }
                            },
                            child: const Icon(Icons.search)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            isSearching ? searchUsersList() : chatRoomsList()
          ],
        ),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  final String lastMessage, chatRoomId, myUserName;
  ChatRoomListTile(this.lastMessage, this.chatRoomId, this.myUserName);

  @override
  State<ChatRoomListTile> createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  late String profilePicUrl = "", username = "", name = "";

  getThisUserInfo() async {
    username =
        widget.chatRoomId.replaceAll(widget.myUserName, "").replaceAll("_", "");
    QuerySnapshot querySnapshot = await DatabaseMethods().getUserInfo(username);
    name = "${querySnapshot.docs[0]['name']}";
    profilePicUrl = "${querySnapshot.docs[0]['imgUrl']}";
    setState(() {});
  }

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(username, name),
          ),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: profilePicUrl.isNotEmpty
                ? Image.network(
                    profilePicUrl,
                    height: 30,
                    width: 30,
                  )
                : null,
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 3),
              Text(widget.lastMessage),
            ],
          ),
        ],
      ),
    );
  }
}
