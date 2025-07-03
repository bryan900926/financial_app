import 'package:news_app/services/auth/auth_provider.dart';
import 'package:news_app/services/auth/auth_user.dart';
import 'package:news_app/services/auth/firebase_auth_service.dart';

class AuthService implements AuthProvider {
  AuthProvider provider;
  AuthService({required this.provider});
  factory AuthService.firebase() =>
      AuthService(provider: FirebaseAuthProvider());
  @override
  Future<void> initialize() => provider.initialize();
  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) {
    return provider.createUser(email: email, password: password);
  }

  @override
  AuthUser? get currentUser => provider.currentUser;
  @override
  Future<void> logOut() => provider.logOut();
  @override
  Future<AuthUser> login({required String email, required String password}) {
    return provider.login(email: email, password: password);
  }
  @override
  Future<void> sendEmailVerification() => provider.sendEmailVerification();
  @override
  Future<void> sendPasswordChange({required String email}) {
    return provider.sendEmailVerification();
  }
}
