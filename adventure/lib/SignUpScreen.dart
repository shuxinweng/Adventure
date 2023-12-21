import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class SignUpScreen extends StatelessWidget {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Template.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Adventure',
                  style: GoogleFonts.indieFlower(
                    fontSize: 36,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 4),
                        blurRadius: 4.0,
                        color: Colors.black.withOpacity(0.25),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Color(0xFFEDE8E8),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      )
                    ]
                  ),
                  child: Image.asset(
                    'assets/Poop.png',
                    width: 120,
                  ),
                ),
                SizedBox(height: 50),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter Your Email',
                    labelStyle: GoogleFonts.indieFlower(),
                    hintStyle: GoogleFonts.indieFlower(),
                  ),
                ),
                SizedBox(height: 30),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter Your Password',
                    labelStyle: GoogleFonts.indieFlower(),
                    hintStyle: GoogleFonts.indieFlower(),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    final emailAddress = emailController.text;
                    final password = passwordController.text;
                    try {
                      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailAddress,
                        password: password,
                      );
                      submitNewUserData(emailAddress,password);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginPage(),
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'weak-password') {
                        print('The password provided is too weak.');
                      } else if (e.code == 'email-already-in-use') {
                        print('The account already exists for that email.');
                      }
                    } catch (e) {
                      print(e);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                  ),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.indieFlower(
                      fontSize: 24,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 4.0,
                          color: Colors.black.withOpacity(0.25),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
Future<http.Response> addUser(String username, String password,) async {
  final response = await http.post(
    Uri.parse(
        'https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/userdata'), // Replace with the correct endpoint for adding a user
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'username': username,
      'password': password, // Make sure to hash the password before sendin // Encode the tasks as a JSON string
    }),
  );

  return response;
}

void submitNewUserData(String email,String curpassword) {
  String username = email ;
  String password = curpassword; // Hash this password
  addUser(username, password,).then((response) {
    if (response.statusCode == 200) {
      // Handle the response
      print('New user added: ${response.body}');
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception(
          'Failed to add new user. Status code: ${response.statusCode}');
    }
  }).catchError((error) {
    // Handle any errors here
    print('Error adding new user: $error');
  });
}

