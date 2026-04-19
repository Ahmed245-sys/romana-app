import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // بحث بالرقم في customers
        final existing = await FirebaseFirestore.instance
            .collection('customers')
            .where('رقم الجوال', isEqualTo: _phoneController.text)
            .get();

        // لو مش موجود جرب بالإنجليزي
        final existingEn = existing.docs.isEmpty
            ? await FirebaseFirestore.instance
                .collection('customers')
                .where('phone', isEqualTo: _phoneController.text)
                .get()
            : null;

        final allDocs =
            existing.docs.isNotEmpty ? existing.docs : (existingEn?.docs ?? []);

        String customerId = '';
        String name = '';
        String address = '';

        if (allDocs.isNotEmpty) {
          // موجود → جيب بياناته وحدث آخر دخول
          customerId = allDocs.first.id;
          final data = allDocs.first.data() as Map<String, dynamic>;
          name = data['اسم'] ?? data['name'] ?? _nameController.text;
          address = data['عنوان'] ?? data['address'] ?? _addressController.text;

          await FirebaseFirestore.instance
              .collection('customers')
              .doc(customerId)
              .update({'آخر دخول': DateTime.now().toString()});
        } else {
          // جديد → سجله بالعربي بس
          final docRef =
              await FirebaseFirestore.instance.collection('customers').add({
            'اسم': _nameController.text,
            'عنوان': _addressController.text,
            'رقم الجوال': _phoneController.text,
            'محفظة': '0',
            'آخر طلب': '',
            'تاريخ التسجيل': DateTime.now().toString(),
            'آخر دخول': DateTime.now().toString(),
          });

          customerId = docRef.id;
          name = _nameController.text;
          address = _addressController.text;
        }

        // حفظ محلياً
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customerId', customerId);
        await prefs.setString('name', name);
        await prefs.setString('address', address);
        await prefs.setString('phone', _phoneController.text);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              name: name,
              email: address,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حصل خطأ! حاول تاني'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 60),
              Icon(Icons.shopping_cart, size: 80, color: Colors.red),
              SizedBox(height: 10),
              Text('ROMANA',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red)),
              Text('خضروات وفواكه طازجة',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 40),

              // الاسم
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.person, color: Colors.red),
                  filled: true,
                  fillColor: Colors.red.shade50,
                ),
                validator: (v) => v!.isEmpty ? 'أدخل اسمك' : null,
              ),
              SizedBox(height: 16),

              // العنوان
              TextFormField(
                controller: _addressController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'العنوان',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.location_on, color: Colors.red),
                  filled: true,
                  fillColor: Colors.red.shade50,
                ),
                validator: (v) => v!.isEmpty ? 'أدخل عنوانك' : null,
              ),
              SizedBox(height: 16),

              // رقم الجوال
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'رقم الجوال',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.phone, color: Colors.red),
                  filled: true,
                  fillColor: Colors.red.shade50,
                ),
                validator: (v) => v!.length < 9 ? 'أدخل رقم جوال صحيح' : null,
              ),
              SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('دخول',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
