import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uni_links2/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:math';

import '../constant/firestore_constants.dart';
import '../model/user_information.dart';

enum NaverStatus {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateException,
  authenticateCanceled,
}

class AuthProviderNaver extends ChangeNotifier {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  AuthProviderNaver({
    required this.firebaseAuth,
    required this.firebaseFirestore,
    required this.prefs,
  });

  NaverStatus _status = NaverStatus.uninitialized;

  NaverStatus get status => _status;

  String? get userFirebaseId => prefs.getString(FirestoreConstants.id);

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = firebaseAuth.currentUser != null;
    if (isLoggedIn && prefs.getString(FirestoreConstants.id)?.isNotEmpty == true) {
      _status = NaverStatus.authenticated;
      notifyListeners();
      return true;
    } else {
      _status = NaverStatus.uninitialized;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithNaver() async {
    try {
      String clientId = dotenv.env['CLIENT_ID']!;
      String redirectUri = dotenv.env['REDIRECT_URI']!;
      String state = base64Url.encode(List<int>.generate(16, (_) => Random().nextInt(255)));
      Uri url = Uri.parse('https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&state=$state');
      await launchUrl(url);

      _status = NaverStatus.authenticating;
      notifyListeners();

      return true;
    } catch (e) {
      print("Naver Sign-In Error: $e");
      _status = NaverStatus.authenticateError;
      notifyListeners();
      return false;
    }
  }

  Future<void> initUniLinks() async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) _handleDeepLink(initialLink);

      linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(link);
        }
      }, onError: (err, stacktrace) {
        print("deep link error $err\n$stacktrace");
        _status = NaverStatus.authenticateError;
        notifyListeners();
      });
    } catch (e) {
      print("UniLinks Initialization Error: $e");
      _status = NaverStatus.authenticateError;
      notifyListeners();
    }
  }

  Future<void> _handleDeepLink(String link) async {
    try {
      print("deep link open $link");
      final Uri uri = Uri.parse(link);

      if (uri.authority == 'login-callback') {
        String? firebaseToken = uri.queryParameters['firebaseToken'];
        String? name = uri.queryParameters['name'];
        String? profileImage = uri.queryParameters['profileImage'];

        if (firebaseToken == null) {
          _status = NaverStatus.authenticateError;
          notifyListeners();
          return;
        }

        await firebaseAuth.signInWithCustomToken(firebaseToken).then((value) async {
          final firebaseUser = value.user;
          if (firebaseUser == null) {
            _status = NaverStatus.authenticateError;
            notifyListeners();
            return;
          }

          print("Firebase User: ${firebaseUser.uid}");

          final result = await firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .doc(firebaseUser.uid)
              .get();

          print("Firestore result: ${result}");

          if (!result.exists) {
            await firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(firebaseUser.uid).set({
              FirestoreConstants.nickname: name,
              FirestoreConstants.photoUrl: profileImage,
              FirestoreConstants.id: firebaseUser.uid,
              FirestoreConstants.createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
              FirestoreConstants.chattingWith: null
            });

            User? currentUser = firebaseUser;
            await prefs.setString(FirestoreConstants.id, currentUser.uid);
            await prefs.setString(FirestoreConstants.nickname, name ?? "");
            await prefs.setString(FirestoreConstants.photoUrl, profileImage ?? "");
          } else {
            final userChat = UserInformation.fromDocument(result);
            await prefs.setString(FirestoreConstants.id, userChat.id);
            await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
            await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
            await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
          }
          _status = NaverStatus.authenticated;
          notifyListeners();
        }).onError((error, stackTrace) {
          print("Firestore error: $error");
          _status = NaverStatus.authenticateError;
          notifyListeners();
        });
      }
    } catch (e) {
      print("Deep Link Handling Error: $e");
      _status = NaverStatus.authenticateError;
      notifyListeners();
    }
  }

  void handleException() {
    _status = NaverStatus.authenticateException;
    notifyListeners();
  }

  Future<void> handleSignOut() async {
    try {
      await firebaseAuth.signOut();
      await FlutterNaverLogin.logOut();

      await prefs.remove(FirestoreConstants.id);
      await prefs.remove(FirestoreConstants.nickname);
      await prefs.remove(FirestoreConstants.photoUrl);
      await prefs.remove(FirestoreConstants.aboutMe);

      _status = NaverStatus.uninitialized;
      notifyListeners();
    } catch (e) {
      print("Naver Sign-Out Error: $e");
      handleException();
    }
  }
}
