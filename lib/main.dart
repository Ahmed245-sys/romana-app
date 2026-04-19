import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyCqwSqhvuiyoZ3ZV8BvX0uK4uffMdGOAC4",
      authDomain: "romana-project.firebaseapp.com",
      projectId: "romana-project",
      storageBucket: "romana-project.firebasestorage.app",
      messagingSenderId: "771775359247",
      appId: "1:771775359247:web:fafa3014bdc4d15842367a",
    ),
  );

  final now = DateTime.now();
  final hour = now.hour;
  final isOpen = hour >= 8 && hour < 24;

  runApp(MyApp(isOpen: isOpen));
}

class MyApp extends StatelessWidget {
  final bool isOpen;
  MyApp({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ROMANA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.red,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: isOpen ? SplashScreen() : ClosedPage(),
    );
  }
}

class ClosedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 80, color: Colors.white),
              SizedBox(height: 20),
              Text('ROMANA',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('خضروات وفواكه طازجة',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              SizedBox(height: 32),
              Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('التطبيق غير متاح الآن',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 12),
                    Text('متاح من الساعة 8:00 صباحاً',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text('حتى الساعة 12:00 منتصف الليل',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
