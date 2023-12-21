import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Components/navbar.dart';

class SettingsPage extends StatefulWidget {
  static const routeName = '/settings';

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            height: 70,
            child: Center(
              child: Text(
                'Settings Page',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'User is signed in with email: ${currentUser?.email ?? 'N/A'}',
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await signOut();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  },
                  child: Text('Sign Out'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Navbar(
        currentIndex: 3,
        onTap: (index) {},
        routes: [
          '/',
          '/room',
          '/all-tasks',
          '/settings',
        ],
      ),
    );
  }

  User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
