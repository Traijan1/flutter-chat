import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:chat/message.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'appwrite_provider.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => ChatState();
}

class ChatState extends State<Chat> {
  final fieldText = TextEditingController();
  late Future<List<Message>?> messages;
  late String currentRoomId;

  @override
  void initState() {
    currentRoomId =
        Provider.of<AppwriteProvider>(context, listen: false).currentRoom!.id;
    messages = loadMessages();
    super.initState();
  }

  List<dynamic> getUserIds(List<Document> messages) {
    List<dynamic> userIds = List<dynamic>.empty(growable: true);

    for (var message in messages) {
      if (!userIds.contains(message.data["userId"])) {
        userIds.add(message.data["userId"]);
      }
    }

    return userIds;
  }

  Future<List<Message>?> loadMessages() async {
    Databases database =
        Databases(Provider.of<AppwriteProvider>(context, listen: false).client);

    var messageList = await database.listDocuments(
        databaseId: "632373f9558081f658f3",
        collectionId: "6323740a7bdff2de8ef5",
        queries: [
          Query.equal("roomId", currentRoomId),
          Query.limit(50),
          Query.orderDesc("\$createdAt")
        ]);

    DocumentList? users;

    if (messageList.documents.isNotEmpty) {
      users = await database.listDocuments(
          databaseId: "632373f9558081f658f3",
          collectionId: "6324aa721d69d51a3b32",
          queries: [
            Query.equal("userId", getUserIds(messageList.documents)),
            Query.limit(100),
          ]);
    }

    List<Message>? cacheList = List<Message>.empty(growable: true);

    if (users != null) {
      for (var message in messageList.documents) {
        cacheList.add(Message(
          text: message.data["content"],
          id: message.data["userId"],
          name:
              getAttributeById(users.documents, message.data["userId"], "name"),
          avatar: getAttributeById(
              users.documents, message.data["userId"], "avatar"),
        ));
      }
    }

    return cacheList.reversed.toList(growable: true);
  }

  String getAttributeById(List<Document> users, String id, String attribute) {
    for (var user in users) {
      if (user.data["userId"] as String == id) {
        return user.data[attribute];
      }
    }

    return "!";
  }

  newMessage(String value) async {
    var appwrite = Provider.of<AppwriteProvider>(context, listen: false);
    Databases database = Databases(appwrite.client);

    await database.createDocument(
        databaseId: "632373f9558081f658f3",
        collectionId: "6323740a7bdff2de8ef5",
        documentId: "unique()",
        data: {
          "userId": appwrite.user!.$id,
          "content": value,
          "roomId": appwrite.currentRoom!.id
        });

    fieldText.clear();
  }

  @override
  void dispose() {
    super.dispose();
    var appwrite = Provider.of<AppwriteProvider>(context, listen: false);

    if (appwrite.subscription == null) {
      appwrite.subscription!.close();
      appwrite.subscription = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var appwrite = Provider.of<AppwriteProvider>(context, listen: false);

    if (appwrite.subscription == null) {
      const eventString =
          "databases.632373f9558081f658f3.collections.6323740a7bdff2de8ef5.documents";

      appwrite.subscription = appwrite.realtime.subscribe([eventString]);
      appwrite.subscription!.stream.listen(((event) async {
        if (event.events[0].contains(eventString) &&
            event.events[0].endsWith("create")) {
          if (event.payload["roomId"] as String == appwrite.currentRoom?.id) {
            Databases database = Databases(appwrite.client);

            database.listDocuments(
                databaseId: "632373f9558081f658f3",
                collectionId: "6324aa721d69d51a3b32",
                queries: [
                  Query.equal("userId", event.payload["userId"])
                ]).then((value) async {
              var user = value.documents[0];

              List<Message>? mes = await messages;
              setState(() {
                mes!.add(Message(
                  text: event.payload["content"],
                  id: event.payload["userId"],
                  name: user.data["name"],
                  avatar: appwrite.user!.prefs.data["avatar"],
                ));
              });
            });
          }
        }
      }));
    }

    if (currentRoomId != appwrite.currentRoom!.id) {
      currentRoomId = appwrite.currentRoom!.id;

      setState(() {
        messages = loadMessages();
      });
    }

    return FutureBuilder<List<Message?>?>(
      future: messages,
      builder: ((context, snapshot) {
        if (snapshot.hasData) {
          var message = snapshot.data!;
          return SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  Expanded(
                      child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: message.length,
                    itemBuilder: ((context, index) {
                      var currentMessage = message[index]!;

                      if (index != 0) {
                        if (message[index - 1]!.id == currentMessage.id) {
                          currentMessage.isPrevious = true;
                        }
                      }

                      return InkWell(
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 8.0, top: 1, bottom: 1),
                          margin: currentMessage.isPrevious
                              ? const EdgeInsets.only(top: 0)
                              : const EdgeInsets.only(top: 20.0),
                          child: currentMessage,
                        ),
                      );
                    }),
                  )),
                  const SizedBox(height: 20),
                  Container(
                    color: Theme.of(context).cardColor,
                    child: TextField(
                      decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(12),
                          hintText: "Enter message.."),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (text) => newMessage(text),
                      controller: fieldText,
                    ),
                  ),
                ],
              ));
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return const Text("Messages will be loaded");
        }
      }),
    );
  }
}
