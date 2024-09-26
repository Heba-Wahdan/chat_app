import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chat")
            .orderBy("createdAt", descending: true)
            // order by allows ne to specify a key that must be present in my doc
            // and second parameter where I want sorting descending or ascending
            .snapshots(),
        builder: (ctx, chatSnapshots) {
          if (chatSnapshots.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty)
          // if we have data that is an empty list, if we have no docs in our collection
          // every doc is a message
          //data won't be null bec. the first condition checks if no data
          {
            return const Center(
              child: Text(""),
            );
          }

          if (chatSnapshots.hasError) {
            return const Center(
              child: Text(""),
            );
          }

          final loadedMessages = chatSnapshots.data!.docs;
          return ListView.builder(
              padding: EdgeInsets.fromLTRB(13, 0, 13, 40),
              // item count is based on the documents
              reverse: true,
              itemCount: loadedMessages.length,
              itemBuilder: (ctx, index) {
                final chatMessage =
                    loadedMessages[index].data() as Map<String, dynamic>;

                final messageText =
                    chatMessage["text"] ?? "No message available";

                final nextChatMessage = index + 1 < loadedMessages.length
                    ? loadedMessages[index + 1].data()
                    : null;

                // I used because if 2 users have the same name
                final currentMessageUserID = chatMessage["userID"];
                final nextMessageUserID =
                    nextChatMessage != null ? nextChatMessage["userID"] : null;

                final isNextUserSame =
                    currentMessageUserID == nextMessageUserID;
                //it will output bool and it will be useful for outputting the MessageBubble correctly

                if (isNextUserSame) {
                  return MessageBubble.next(
                      message: messageText,
                      isMe: authenticatedUser.uid == currentMessageUserID);
                  //I use authenticatedUser ID and compare it to the currentMessageUserID
                  // and if they're equal, I know that the currently logged in user is the user who created this message
                  // so isMe should be set to and change some style in MessageBubble widget
                } else {
                  return MessageBubble.first(
                      userImage: chatMessage["userImage"],
                      username: chatMessage["username"],
                      message: messageText,
                      isMe: authenticatedUser.uid == currentMessageUserID);
                }
              });
        });
  }
}
