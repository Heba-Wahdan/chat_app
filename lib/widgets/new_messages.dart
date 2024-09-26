import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NewMessages extends StatefulWidget {
  const NewMessages({super.key});

  @override
  State<NewMessages> createState() {
    return _NewMessagesState();
  }
}

class _NewMessagesState extends State<NewMessages> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void submitMessage() async {
    final enteredMessage = _messageController.text;
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    // this will close the keyboard after sending a message
    _messageController.clear();
    // clearing immediately and unfocusing immediately makes more sense to write the here
    // I do ot need to wait for the the data to be send to the firestore
    final user = FirebaseAuth.instance
        .currentUser!; //FirebaseAuth gives us access to the current logged in user
    final userData = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get(); // this will send http request to Firestore to retrieve the data

    FirebaseFirestore.instance.collection("chat").add({
      "text": enteredMessage,
      "createdAt": Timestamp.now(),
      "userID": user.uid,
      "username": userData.data()!["username"],
      "userImage": userData.data()!["image_url"]
    }); // instead of doc, I wrote add, it will generate an automatic name/ID that will be crated by flutter
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        children: [
          // ignore: prefer_const_constructors
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              decoration: InputDecoration(
                label: Text(
                  "Send a message...",
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: submitMessage,
            icon: const Icon(
              Icons.send,
            ),
          )
        ],
      ),
    );
  }
}
