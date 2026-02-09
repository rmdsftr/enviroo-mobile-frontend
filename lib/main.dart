import 'package:enviroo/screens/splash_screen.dart';
import 'package:flutter/material.dart';

void main() async{
  runApp(const EnvirooApp());
}

class EnvirooApp extends StatelessWidget{
  const EnvirooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}