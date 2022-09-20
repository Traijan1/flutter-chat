// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:chat/appwrite_provider.dart';
import 'package:chat/chat.dart';
import 'package:chat/drawer.dart';
import 'package:chat/room.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import "package:appwrite/appwrite.dart";
import "package:dynamic_color/dynamic_color.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "package:appwrite/models.dart" as Models;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  Client client = Client();
  Account acc = Account(client);

  client.setEndpoint(dotenv.env["URL"]!);
  client.setProject("632224e4e3edf65c23b2");

  Models.Account? user;

  try {
    user = await acc.get();
  } catch (e) {}

  Databases database = Databases(client);
  var documents = await database.listDocuments(
      databaseId: "632373f9558081f658f3", collectionId: "6323746d1995c9416bc5");

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<AppwriteProvider>(
        create: (context) => AppwriteProvider(
            client: client,
            account: acc,
            user: user,
            rooms: getRooms(documents)),
      )
    ],
    child: const MyApp(),
  ));
}

List<Room> getRooms(documentList) {
  List<Room> rooms = List.empty(growable: true);

  for (var document in documentList.documents) {
    rooms.add(Room(id: document.data["\$id"], name: document.data["name"]));
  }

  return rooms;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: ((lightDynamic, darkDynamic) {
      return MaterialApp(
        theme: ThemeData(
          hintColor: Colors.lightBlue[50],
          useMaterial3: true,
          brightness: Brightness.light,
          appBarTheme: AppBarTheme(
              backgroundColor:
                  lightDynamic?.background ?? Colors.lightBlue[100],
              foregroundColor: lightDynamic?.primary ?? Colors.black),
          cardColor: lightDynamic?.primary ?? Colors.lightBlue[100],
          primaryColor: lightDynamic?.primary ?? Colors.lightBlue[200],
          scaffoldBackgroundColor: lightDynamic?.background,
          backgroundColor: lightDynamic?.background ?? Colors.white,
          textTheme: TextTheme(
            bodyText1: TextStyle(
              color: lightDynamic?.primary ?? Colors.blue[700],
            ),
            bodyText2: TextStyle(color: Colors.black, fontSize: 16),
            headline6: TextStyle(
              color: lightDynamic?.secondary ?? Colors.blue[200],
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          appBarTheme: AppBarTheme(
              backgroundColor:
                  darkDynamic?.secondaryContainer ?? Colors.black38,
              foregroundColor: darkDynamic?.primary ?? Colors.white),
          primaryColor: darkDynamic?.primary ?? Colors.white,
          cardColor: darkDynamic?.secondaryContainer ?? Colors.blueGrey[70],
          scaffoldBackgroundColor: darkDynamic?.background,
          textTheme: TextTheme(
            bodyText1: TextStyle(
              color: darkDynamic?.primary ?? Colors.white,
            ),
            bodyText2: TextStyle(color: Colors.white, fontSize: 16),
            headline6: TextStyle(
              color: darkDynamic?.secondary ?? Colors.white54,
            ),
          ),
        ),
        title: 'FlutterChat',
        home: HomePage(),
      );
    }));
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appwrite = Provider.of<AppwriteProvider>(context);

    if (appwrite.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginPage()));
      });
    }

    return Scaffold(
      drawer: CustomDrawer(
        rooms: appwrite.rooms,
      ),
      appBar: AppBar(
        title: Text(
          appwrite.currentRoom == null
              ? "FlutterChat"
              : appwrite.currentRoom!.name,
        ),
        actions: [
          if (appwrite.avatar != null)
            CircleAvatar(
              radius: 20.0,
              backgroundColor: Colors.transparent,
              child: ClipOval(
                child: Image.memory(appwrite.avatar!),
              ),
            ),
          SizedBox(width: 10)
        ],
      ),
      body: Selector<AppwriteProvider, Room?>(
          builder: ((context, value, child) {
            return appwrite.currentRoom != null
                ? Chat()
                : Center(child: Text("Home Screen"));
          }),
          selector: (_, notifier) => notifier.currentRoom),
    );
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 30),
            TextField(
              controller: email,
              decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(8), hintText: "E-Mail"),
            ),
            SizedBox(height: 20),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(8), hintText: "Password"),
            ),
            SizedBox(height: 30),
            MaterialButton(
              color: Theme.of(context).cardColor,
              child: Text("Login"),
              onPressed: () {
                var appwrite =
                    Provider.of<AppwriteProvider>(context, listen: false);
                appwrite.account
                    .createEmailSession(
                        email: email.text, password: password.text)
                    .then((_) {
                  appwrite.account.get().then((value) {
                    appwrite.user = value;
                    Navigator.pop(context);

                    appwrite.fetchAvatar();
                  });
                });
              },
            )
          ],
        ),
      ),
    );
  }
}
