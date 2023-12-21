import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SignUpScreen.dart';
import 'main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class SignInScreen extends StatelessWidget {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> _handleSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential authResult =
          await _auth.signInWithCredential(credential);
      final User? user = authResult.user;
      return user;
    } catch (error) {
      print("Error signing in with Google: $error");
      return null;
    }
  }

  String? name;
  String? imageUrl;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  SizedBox(height: 30),
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
                      final credential = await FirebaseAuth.instance
                          .signInWithEmailAndPassword(
                              email: emailAddress, password: password);
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'user-not-found') {
                        print('No user found for that email.');
                      } else if (e.code == 'wrong-password') {
                        print('Wrong password provided for that user.');
                      } else {
                        print('INVAILD');
                      }
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
                    'Login',
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
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: GoogleFonts.indieFlower(
                      fontSize: 15,
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
                  ElevatedButton(
                onPressed: (){
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>  SignUpScreen(),
                  ),
                );
              }, 
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.transparent),
                elevation: MaterialStateProperty.all(0),
                overlayColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed)) {
                      return Colors.cyan.withOpacity(0.1);
                    }
                    return null;
                  },
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              child: Text(
                "Sign-Up",
                style: GoogleFonts.indieFlower(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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
              TextButton(
                onPressed: () async {
                  final user = await _handleSignIn();
                  String? email = getCurrentUserEmail();

                  if (user != null) {
                    fetchDataAndSubmitData(email.toString());
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>  LoginPage(),
                      ),
                    );
                    // User signed in successfully.
                  } else {
                    // Failed to sign in.
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.center,
                ),
                child: Ink.image(
                  image: AssetImage('assets/GoogleSignin.png'),
                  height: 70,
                  fit: BoxFit.fitWidth,
                ),
              ),
            ]),
          ),
        )
      )
    );
  }
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

String? getCurrentUserEmail() {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return user.email;
  } else {
    return null; // Return null if no user is logged in
  }
}




Future<bool> fetchData() async {
  String? email = getCurrentUserEmail();
  final response = await http.get(Uri.parse('https://us-central1-silver-nova-403820.cloudfunctions.net/quickstart-function/userdata'));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    for(var item in data){
      if(item is Map && item.containsKey('username')){
        final username = item['username'];
        if(username == email.toString()){
          return true;
        }
      }
    }
    // Data is successfully retrieved
    print('Response data: ${response.body}');
  } else {
    // Handle error
    print('Failed to load data: ${response.statusCode}');
  }
  return false;
}

Future<void> fetchDataAndSubmitData(String email) async {
  bool result = await fetchData();
  if (result == false) {
    submitNewUserData(email, "");
  }
}