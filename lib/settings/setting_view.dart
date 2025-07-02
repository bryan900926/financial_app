import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:news_app/auth_service/firebase.dart';
import 'package:news_app/dialogs/error_dialogs.dart';
import 'package:news_app/view/login_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuthService authService = FirebaseAuthService();
    final User? user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Account'),
            subtitle: Text(user?.email ?? 'Not signed in'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Password'),
            subtitle: const Text('Send a password reset email'),
            onTap: () async {
              if (user?.email != null) {
                try {
                  await authService.sendPasswordResetEmail(user!.email!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send email: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.contact_mail),
            title: Text('About us'),
            onTap: () async {
              showGenericDialog(
                context: context,
                title: "Contact us",
                message:
                    "Hi, I'm creator called Yong Yao. Here's my email: bryan900926@gmail.com. Contact me if you have any question!",
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: Text('Logout', style: TextStyle(color: Colors.red.shade400)),
            onTap: () async {
              await authService.signOut();
              // Navigate back to the login screen and remove all previous routes
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginView()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
