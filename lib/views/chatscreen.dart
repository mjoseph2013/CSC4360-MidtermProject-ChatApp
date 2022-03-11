import 'package:chat_app/helperfunctions/sharedpref_helper.dart';
import 'package:chat_app/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import "package:chat_app/helperfunctions/sharedpref_helper.dart";
import "package:chat_app/services/rating_star.dart";
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:random_string/random_string.dart';

class ChatScreen extends StatefulWidget {
  final String chatWithUsername, name;

  ChatScreen(this.chatWithUsername, this.name);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late String chatRoomId, messageId = "";
  late Stream? messageStream;
  late String? myName, myProfilePic, myUserName, myEmail;
  TextEditingController messageTextEditingController = TextEditingController();

  getMyInfoFromSharedPreference() async {
    myName = (await SharedPreferenceHelper().getDisplayName());
    myProfilePic = (await SharedPreferenceHelper().getUserProfileUrl());
    myUserName = (await SharedPreferenceHelper().getUserName());
    myEmail = (await SharedPreferenceHelper().getUserEmail());

    chatRoomId =
        getChatRoomIdByUserNames(widget.chatWithUsername, myUserName as String);
  }

  getChatRoomIdByUserNames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  getAndSetMessages() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPreference();
    getAndSetMessages();
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  addMessage(bool sendClicked) {
    if (messageTextEditingController.text != "") {
      String message = messageTextEditingController.text;

      var lastMessageTS = DateTime.now();

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "ts": lastMessageTS,
        "imgUrl": myProfilePic,
      };

      if (messageId == "") {
        messageId = randomAlphaNumeric(12);
      }

      DatabaseMethods()
          .addMessage(chatRoomId, messageId, messageInfoMap)
          .then((value) {
        Map<String, dynamic> lastMessageInfoMap = {
          "lastMessage": message,
          "lastMessageSendTs": lastMessageTS,
          "lastMessageSendBy": myUserName,
        };

        DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);

        if (sendClicked) {
          //remove text in input field
          messageTextEditingController.text = "";
          //regenerate messageId for next message
          messageId = "";
        }
      });
    }
  }

  Widget chatMessageTile(String message, bool sendByMe) {
    return Row(
      mainAxisAlignment:
          sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomRight: sendByMe ? Radius.circular(0) : Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: sendByMe ? Radius.circular(24) : Radius.circular(0),
            ),
            color: sendByMe ? Colors.lightBlue : Colors.lightGreen,
          ),
          padding: EdgeInsets.all(16),
          child: Text(
            message,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget chatMessages() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.only(bottom: 90, top: 16),
                itemCount: snapshot.data!.docs.length,
                reverse: true,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data!.docs[index];
                  return chatMessageTile(
                      ds["message"], myUserName == ds["sendBy"]);
                },
              )
            : Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Chat w/ " + widget.name),
          bottom: const TabBar(
            tabs: <Widget>[
              RateStar(),
            ],
          ),
        ),
        body: Container(
          child: Stack(
            children: [
              chatMessages(),
              Container(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
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
                          controller: messageTextEditingController,
                          onChanged: (value) {
                            addMessage(false);
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Start your message here...",
                          ),
                        ),
                      ),
                      GestureDetector(
                          onTap: () {
                            addMessage(true);
                          },
                          child: Icon(Icons.send)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
