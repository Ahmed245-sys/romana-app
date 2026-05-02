import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  LatLng? selectedLocation;
  String selectedAddress = '';
  GoogleMapController? mapController;

  bool isInAseer(LatLng location) {
    return location.latitude >= 17.5 &&
        location.latitude <= 20.5 &&
        location.longitude >= 41.5 &&
        location.longitude <= 44.5;
  }

  String getAddressFromLatLng(LatLng latLng) {
    final lat = latLng.latitude.toStringAsFixed(5);
    final lng = latLng.longitude.toStringAsFixed(5);
    return 'https://maps.google.com/?q=$lat,$lng';
  }

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;

      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      if (isInAseer(latLng)) {
        final address = getAddressFromLatLng(latLng);
        setState(() {
          selectedLocation = latLng;
          selectedAddress = address;
        });
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('هذه الخدمة لا تتوفر في هذه المنطقة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحديد موقعك!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      if (selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('اختار موقعك على الخريطة أولاً!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final existing = await FirebaseFirestore.instance
            .collection('customers')
            .where('رقم الجوال', isEqualTo: _phoneController.text)
            .get();

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

        if (allDocs.isNotEmpty) {
          customerId = allDocs.first.id;
          final data = allDocs.first.data() as Map<String, dynamic>;
          name = data['اسم'] ?? data['name'] ?? _nameController.text;

          await FirebaseFirestore.instance
              .collection('customers')
              .doc(customerId)
              .update({
            'آخر دخول': DateTime.now().toString(),
            'موقع': {
              'lat': selectedLocation!.latitude,
              'lng': selectedLocation!.longitude,
            },
            'عنوان': selectedAddress,
          });

          // تحديث العنوان في addresses
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(customerId)
              .collection('addresses')
              .add({
            'اسم': 'المنزل',
            'عنوان': selectedAddress,
            'lat': selectedLocation!.latitude,
            'lng': selectedLocation!.longitude,
            'createdAt': DateTime.now().toString(),
          });
        } else {
          final docRef =
              await FirebaseFirestore.instance.collection('customers').add({
            'اسم': _nameController.text,
            'عنوان': selectedAddress,
            'رقم الجوال': _phoneController.text,
            'محفظة': '0',
            'موقع': {
              'lat': selectedLocation!.latitude,
              'lng': selectedLocation!.longitude,
            },
            'آخر طلب': '',
            'تاريخ التسجيل': DateTime.now().toString(),
            'آخر دخول': DateTime.now().toString(),
          });

          customerId = docRef.id;
          name = _nameController.text;

          // حفظ العنوان في addresses للعميل الجديد
          await FirebaseFirestore.instance
              .collection('customers')
              .doc(customerId)
              .collection('addresses')
              .add({
            'اسم': 'المنزل',
            'عنوان': selectedAddress,
            'lat': selectedLocation!.latitude,
            'lng': selectedLocation!.longitude,
            'createdAt': DateTime.now().toString(),
          });
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customerId', customerId);
        await prefs.setString('name', name);
        await prefs.setString('address', selectedAddress);
        await prefs.setString('phone', _phoneController.text);
        await prefs.setDouble('lat', selectedLocation!.latitude);
        await prefs.setDouble('lng', selectedLocation!.longitude);
        await prefs.setString('lastLoginDate', DateTime.now().toString());

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              name: name,
              email: selectedAddress,
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                SizedBox(height: 16),

                // الخريطة
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: getCurrentLocation,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              topLeft: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.my_location, color: Colors.red),
                              SizedBox(width: 8),
                              Text('اختر موقعك الحالي',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                        child: SizedBox(
                          height: 250,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(18.2164, 42.5053),
                              zoom: 10,
                            ),
                            onMapCreated: (controller) {
                              mapController = controller;
                            },
                            onTap: (latLng) {
                              if (isInAseer(latLng)) {
                                final address = getAddressFromLatLng(latLng);
                                setState(() {
                                  selectedLocation = latLng;
                                  selectedAddress = address;
                                });
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'هذه الخدمة لا تتوفر في هذه المنطقة'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            markers: selectedLocation != null
                                ? {
                                    Marker(
                                      markerId: MarkerId('selected'),
                                      position: selectedLocation!,
                                    )
                                  }
                                : {},
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (selectedLocation != null)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('تم تحديد الموقع ✅',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
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
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
