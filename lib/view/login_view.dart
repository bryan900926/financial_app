import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:news_app/auth_service/firebase.dart';
import 'package:news_app/view/home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Future<void> _showResendVerificationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Not Verified'),
          content: const Text(
            'Your email has not been verified. Please check your inbox or resend the verification email.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Resend'),
              onPressed: () async {
                try {
                  // Use the currentUser getter to access the user and send the email
                  await _auth.currentUser?.sendEmailVerification();
                  Navigator.of(context).pop();
                  setState(() {
                    _errorMessage = 'Verification email sent!';
                  });
                } catch (e) {
                  Navigator.of(context).pop();
                  setState(() {
                    _errorMessage = 'Failed to send verification email.';
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // MODIFIED: This function now catches specific Firebase exceptions for better error messages.
  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (user != null) {
        if (user.emailVerified) {
          // Manually navigate to the MainPage on successful login.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeView()),
          );
        } else {
          // If email is not verified, show a message.
          _showResendVerificationDialog();
          setState(() {
            _errorMessage = 'Please verify your email before logging in.';
          });
        }
      }
      // On success, the AuthWrapper will handle navigation automatically.
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        case 'invalid-credential':
          message =
              'Invalid credentials, please check your email and password.';
          break;
        default:
          message = 'An unknown error occurred. Please try again.';
      }
      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // MODIFIED: This function now catches specific Firebase exceptions for better error messages.
  void _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _auth.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      await user?.sendEmailVerification();
      setState(() {
        _errorMessage = "Please check your email to verify";
      });
      // On success, the AuthWrapper will handle navigation automatically.
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is badly formatted.';
          break;
        default:
          message = 'An unknown error occurred. Please try again.';
      }
      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login or Register')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Login'),
                    ),
                    ElevatedButton(
                      onPressed: _handleRegister,
                      child: const Text('Register'),
                    ),
                  ],
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
