import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'order_tracking_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name') ?? '';
      final address = prefs.getString('address') ?? '';
      final activeOrderId = prefs.getString('activeOrderId') ?? '';
      final activeOrderAddress = prefs.getString('activeOrderAddress') ?? '';
      final activeOrderTotal = prefs.getDouble('activeOrderTotal') ?? 0.0;

      if (!mounted) return;

      if (activeOrderId.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(activeOrderId)
            .get();

        if (!mounted) return;

        final status = doc.data()?['status'] ?? '';

        if (status != 'delivered' && status.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingPage(
                cartItems: [],
                total: activeOrderTotal,
                address: activeOrderAddress,
                orderId: activeOrderId,
              ),
            ),
          );
          return;
        } else {
          await prefs.remove('activeOrderId');
          await prefs.remove('activeOrderAddress');
          await prefs.remove('activeOrderTotal');
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => name.isNotEmpty
              ? HomePage(name: name, email: address)
              : LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_grocery_store, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text('ROMANA',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('خضروات وفواكه طازجة',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
