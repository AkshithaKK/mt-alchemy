import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Signed-in user and their Firestore profile, shared through Provider.
class AppState extends ChangeNotifier {
  User? user;
  Map<String, dynamic>? profile;
  StreamSubscription<User?>? _sub;

  AppState() {
    _sub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? u) async {
    user = u;
    profile = null;
    notifyListeners();
    if (u != null) await refreshProfile();
  }

  Future<void> refreshProfile() async {
    final u = user;
    if (u == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .get();
      profile = doc.data();
    } catch (_) {
      profile = null;
    }
    notifyListeners();
  }

  bool get isLoggedIn => user != null;
  String get uid => user?.uid ?? '';
  String get email => (user?.email ?? '').toLowerCase();
  String get name =>
      (profile?['name'] as String?) ?? user?.displayName ?? user?.email ?? '';

  /// Guest, Individual, Employer, Trainer or Super Admin.
  String get role {
    if (user == null) return 'Guest';
    final r = profile?['role'] as String?;
    const known = ['Individual', 'Employer', 'Trainer', 'Super Admin'];
    return known.contains(r) ? r! : 'Individual';
  }

  bool get isAdmin => role == 'Super Admin';
  bool get isEmployer => role == 'Employer';
  bool get isTrainer => role == 'Trainer';

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
