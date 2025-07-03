import 'package:news_app/services/auth/auth_user.dart';

abstract class AuthProvider {
  Future<void> initialize();
  Future<AuthUser> createUser({
    required String email,
    required String password,
  });
  Future<AuthUser> login({required String email, required String password});
  Future<void> sendEmailVerification();
  Future<void> sendPasswordChange({required String email});
  AuthUser? get currentUser;
  Future<void> logOut(); 
}
