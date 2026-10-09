import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../models/app_user.dart';
import 'auth_service.dart';
import 'db.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

enum SessionStatus { loading, signedOut, needsRole, ready }

/// Tracks the signed-in Firebase user and their `users` document, and decides
/// which interface (Client, Tutor, Admin) the app shows.
class Session extends ChangeNotifier {
  Session() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;

  SessionStatus status = SessionStatus.loading;
  User? firebaseUser;
  AppUser? user;

  /// A message for the login screen (e.g. "account suspended").
  String? notice;

  bool _creatingAccount = false;

  AppUser get currentUser => user!;

  void _set(SessionStatus s) {
    status = s;
    notifyListeners();
  }

  void _onAuthChanged(User? fbUser) {
    _userSub?.cancel();
    firebaseUser = fbUser;
    if (fbUser == null) {
      user = null;
      rootNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      _set(SessionStatus.signedOut);
      return;
    }
    _set(SessionStatus.loading);
    _userSub = Db.instance.streamUser(fbUser.uid).listen(
          (appUser) => _onUserDoc(fbUser, appUser),
          onError: (Object e) => _fail('Could not load your account: ${AuthService.describeError(e)}'),
        );
  }

  Future<void> _onUserDoc(User fbUser, AppUser? appUser) async {
    final isAdminEmail = AppConfig.isAdminEmail(fbUser.email);
    if (appUser == null) {
      if (_creatingAccount) return; // registration is writing the document
      if (isAdminEmail) {
        await _guardedWrite(() => Db.instance.createUserDoc(
              uid: fbUser.uid,
              name: fbUser.displayName ?? 'Admin',
              email: fbUser.email!,
              role: UserRole.admin,
              photoUrl: fbUser.photoURL ?? '',
            ));
        return; // the stream emits again with the new document
      }
      user = null;
      _set(SessionStatus.needsRole);
      return;
    }
    if (isAdminEmail && !appUser.isAdmin) {
      await _guardedWrite(() => Db.instance.promoteToAdmin(fbUser.uid));
      return;
    }
    if (!appUser.isActive) {
      await _fail(appUser.status == AccountStatus.deleted
          ? 'This account has been removed by an administrator.'
          : 'This account is suspended. Contact the LearnHub admin for help.');
      return;
    }
    user = appUser;
    _set(SessionStatus.ready);
  }

  Future<void> _guardedWrite(Future<void> Function() write) async {
    try {
      await write();
    } catch (e) {
      await _fail(AppConfig.isAdminEmail(firebaseUser?.email)
          ? 'Admin setup failed. Sign in with Google using the admin Gmail '
              '(email/password admin logins need a verified email).'
          : AuthService.describeError(e));
    }
  }

  Future<void> _fail(String message) async {
    notice = message;
    await AuthService.signOut();
  }

  void clearNotice() => notice = null;

  /// Email/password registration for the Client and Tutor sign-up pages.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _creatingAccount = true;
    try {
      final fbUser = await AuthService.createAccount(name, email, password);
      await Db.instance.createUserDoc(
        uid: fbUser.uid,
        name: name,
        email: email.trim(),
        role: AppConfig.isAdminEmail(email) ? UserRole.admin : role,
      );
    } finally {
      _creatingAccount = false;
    }
  }

  /// Called from the role chooser after a first-time Google sign-in.
  Future<void> completeRegistration(String role) async {
    final fbUser = firebaseUser!;
    await Db.instance.createUserDoc(
      uid: fbUser.uid,
      name: fbUser.displayName ?? fbUser.email!.split('@').first,
      email: fbUser.email!,
      role: role,
      photoUrl: fbUser.photoURL ?? '',
    );
  }

  Future<void> signOut() => AuthService.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
