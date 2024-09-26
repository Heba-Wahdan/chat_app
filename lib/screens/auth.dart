// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AuthScreen();
  }
}

class _AuthScreen extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var isLogin = true;
  var isAuthenticating = false;
  var _enteredEmail = "";
  var _enteredPassword = "";
  var _enteredUsername = "";
  File? selectedImage;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || !isLogin && selectedImage == null) {
      //show error message
      return;
    }

    _form.currentState!.save();

    try {
      setState(() {
        isAuthenticating = true;
      });
      if (isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            //behind the scenes this method will send an http request to firebase
            email: _enteredEmail,
            password: _enteredPassword);

        final storageRef = FirebaseStorage.instance
            .ref()
            .child("user_images")
            .child("${userCredentials.user!.uid}.jpg");
        //ref gives me a reference of the firebase cloud storage so it gives me access to it
        //on this object (ref gave me) I can call child which creates a new path in that storage folder ("user_images")
        //I will call child again on the ("user_images") folder, but I won't create a subfolder instead I wanna create a file (.jpg)
        // an the name of the file will be dynamic

        await storageRef.putFile(selectedImage!);
        // I called putFile method to upload a file to that path and we wait for that upload to finish

        final imageURL = await storageRef.getDownloadURL();
        // gives me a URL that can be used later to display that image that is stored in firebase

        FirebaseFirestore.instance
            .collection("users")
            .doc(userCredentials.user!.uid) // created a doc with name
            .set({
          "username": _enteredUsername,
          "email": _enteredEmail,
          "image_url": imageURL
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == "email-already-in-use") {}
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? "Authentication failed"),
        ),
      );
      setState(() {
        isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              width: 200,
              child: Image.asset(
                "assets/images/1180287.png",
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: const Color.fromARGB(255, 243, 240, 240),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Form(
                      key: _form,
                      child: Column(
                        children: [
                          if (!isLogin)
                            UserImagePicker(
                              onPickedImage: (pickedImage) {
                                selectedImage = pickedImage;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Email Address",
                            ),
                            autocorrect: false,
                            keyboardType: TextInputType.emailAddress,
                            textCapitalization: TextCapitalization.none,
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains("@")) {
                                return "Enter a valid Email address";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          if (!isLogin)
                            TextFormField(
                              decoration: InputDecoration(
                                label: Text(
                                  "Username",
                                ),
                              ),
                              onSaved: (value) {
                                _enteredUsername = value!;
                              },
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value.length < 4) {
                                  return "Username must be at least 4 Charachters";
                                }
                              },
                            ),

                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: "Password",
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          // ignore: prefer_const_constructors
                          if (isAuthenticating) CircularProgressIndicator(),
                          if (!isAuthenticating)
                            ElevatedButton(
                                onPressed: _submit,
                                child: Text(isLogin ? "Log in" : "Sign up")),
                          if (!isAuthenticating)
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    isLogin = !isLogin;
                                  });
                                },
                                child: Text(isLogin
                                    ? "Create an account"
                                    : "I have already an account"))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
