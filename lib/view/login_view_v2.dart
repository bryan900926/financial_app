import 'package:flutter/material.dart';
import 'package:news_app/consts/routes.dart';
import 'package:news_app/services/auth/auth_exceptions.dart';
import 'package:news_app/services/auth_service.dart';

class LoginViewV2 extends StatefulWidget {
  const LoginViewV2({super.key});

  @override
  State<LoginViewV2> createState() => _LoginViewV2State();
}

class _LoginViewV2State extends State<LoginViewV2> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ValueNotifier<String?> _errorMessage = ValueNotifier(null);
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _errorMessage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.firebase().initialize(),
      builder: (context, asyncSnapshot) {
        switch (asyncSnapshot.connectionState) {
          case ConnectionState.done:
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
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final email = _emailController.text;
                              final password = _passwordController.text;
                              try {
                                await AuthService.firebase().login(
                                  email: email,
                                  password: password,
                                );
                                final user = AuthService.firebase().currentUser;
                                if (user?.isEmailVerified ?? false) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    homeRoute,
                                    (route) => false,
                                  );
                                } else {
                                  _errorMessage.value = "Please verified your email";
                                }
                              } on UserNotFoundAuthException {
                                _errorMessage.value = "User not found";
                              } on WrongPasswordAuthException {
                                _errorMessage.value = "Wrong password";
                              } on InvalidEmailAuthException {
                                _errorMessage.value = "Invalid email";
                              } on GenericAuthException {
                                _errorMessage.value = "Other error occured";
                              } on WrongEmailOrPasswordExcepion {
                                _errorMessage.value = "Email or Password is valid";
                              } 
                              catch (e) {
                                _errorMessage.value = e.toString();
                              }
                            },
                            child: const Text("Login"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final email = _emailController.text;
                              final password = _passwordController.text;
                              try {
                                await AuthService.firebase().createUser(
                                  email: email,
                                  password: password,
                                );
                                await AuthService.firebase()
                                    .sendEmailVerification();
                                _errorMessage.value =
                                    "Please check your email to verify";
                              } on WeakPasswordAuthException {
                                _errorMessage.value =
                                    "Weak password. Please use stronger password";
                              } on EmailAleadyInUsedAuthException {
                                _errorMessage.value = "Email already in use";
                              } on InvalidEmailAuthException {
                                _errorMessage.value = "Invalid email";
                              }
                            },
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: _errorMessage,
                        builder: (context, message, _) {
                          if (message == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              message,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            );
          default:
            return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
