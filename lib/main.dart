import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:news_app/consts/routes.dart';
import 'package:news_app/firebase_options.dart';
import 'package:news_app/view/home_view.dart';
import 'package:news_app/view/login_view_v2.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yao News App',
      theme: ThemeData(
        primarySwatch: Colors.indigo, 
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginViewV2(),
      routes: {
        loginRoute: (context) => const LoginViewV2(),
        homeRoute: (context) => const HomeView()
      },
    );
  }
}
