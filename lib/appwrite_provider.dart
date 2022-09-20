import 'package:appwrite/appwrite.dart';
import 'package:chat/room.dart';
import "package:appwrite/models.dart" as Models;
import 'package:flutter/foundation.dart';

class AppwriteProvider extends ChangeNotifier {
  Client client;
  Account account;
  Room? currentRoom;
  late List<Room> rooms;
  Models.Account? user;
  Uint8List? avatar;
  RealtimeSubscription? subscription;
  late Realtime realtime;

  AppwriteProvider(
      {required this.client,
      required this.account,
      required this.rooms,
      this.user}) {
    currentRoom = null;
    realtime = Realtime(client);

    if (user != null) {
      fetchAvatar();
    }
  }

  setRoomId(Room value) {
    currentRoom = value;
    notifyListeners();
  }

  fetchAvatar() {
    Storage storage = Storage(client);

    // Load the Profile Picture in Background while User uses the App
    var futureBytes = storage.getFileView(
        bucketId: "632724ad7a044e3c080a", fileId: user!.prefs.data["avatar"]);

    futureBytes.then((bytes) {
      avatar = bytes;
      notifyListeners();
    });
  }
}
