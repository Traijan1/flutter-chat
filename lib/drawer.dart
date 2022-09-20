import 'package:chat/room.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'appwrite_provider.dart';

class CustomDrawer extends StatelessWidget {
  final List<Room> rooms;

  const CustomDrawer({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView.builder(
        itemCount: rooms.length,
        itemBuilder: ((context, index) {
          return InkWell(
            child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 1),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Text("# ", style: Theme.of(context).textTheme.headline6),
                    Text(rooms[index].name,
                        style: Theme.of(context).textTheme.bodyText1)
                  ],
                )),
            onTap: () {
              Provider.of<AppwriteProvider>(context, listen: false)
                  .setRoomId(rooms[index]);
              Scaffold.of(context).closeDrawer();
            },
          );
        }),
      ),
    );
  }
}
