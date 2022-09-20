import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "./appwrite_provider.dart";

class Message extends StatefulWidget {
  final String text;
  final String id;
  final String name;
  final String avatar;
  bool isPrevious;

  Message(
      {super.key,
      required this.text,
      required this.id,
      required this.name,
      required this.avatar,
      this.isPrevious = false});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  late Future<Uint8List> futureBytes;
  late Uint8List avatar;

  @override
  void initState() {
    var appwrite = Provider.of<AppwriteProvider>(context, listen: false);

    Storage storage = Storage(appwrite.client);

    futureBytes = storage.getFileView(
        bucketId: "632724ad7a044e3c080a", fileId: widget.avatar);

    futureBytes.then((bytes) => avatar = bytes);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
        future: futureBytes,
        builder: ((context, snapshot) {
          var textStyle = Theme.of(context).textTheme.bodyText2;
          if (snapshot.hasData) {
            if (widget.isPrevious) {
              return Wrap(
                spacing: 15,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  const SizedBox(width: 45),
                  Text(
                    widget.text,
                    style: textStyle,
                  )
                ],
              );
            } else {
              return ListTile(
                minVerticalPadding: 0,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                dense: true,
                contentPadding: const EdgeInsets.only(left: 5),
                leading: CircleAvatar(
                  radius: 20.0,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.memory(avatar),
                  ),
                ),
                title: Text(widget.name,
                    style: Theme.of(context).textTheme.bodyText1),
                subtitle: Text(
                  widget.text,
                  style: textStyle,
                ),
              );
            }
          } else {
            return const Text("Message will be loaded");
          }
        }));
  }
}
