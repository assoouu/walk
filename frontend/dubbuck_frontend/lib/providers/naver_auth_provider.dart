import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  Future<void> signInWithNaver(BuildContext context) async {
    try {
      String clientId = dotenv.env['CLIENT_ID']!;
      String redirectUri = dotenv.env['REDIRECT_URI']!;
      String state = base64Url.encode(List<int>.generate(16, (_) => Random().nextInt(255)));
      Uri url = Uri.parse('https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=$clientId&redirect_uri=$redirectUri&state=$state');
      await launchUrl(url);

      _status = NaverStatus.authenticated;
    } catch (e) {
      print("Naver Sign-In Error: $e");
      _status = NaverStatus.authenticateError;
      notifyListeners(); // 에러 발생 시 상태를 변경하고 화면 업데이트
    }
  }

  Future<void> initUniLinks(BuildContext context) async {
    try {
      final initialLink = await getInitialLink();
      if (initialLink != null) _handleDeepLink(context, initialLink);

      linkStream.listen((String? link) {
        if (link != null) {
          _handleDeepLink(context, link);
        }
      }, onError: (err, stacktrace) {
        print("deep link error $err\n$stacktrace");
        _status = NaverStatus.authenticateError;
        notifyListeners(); // 에러 발생 시 상태를 변경하고 화면 업데이트
      });
    } catch (e) {
      print("UniLinks Initialization Error: $e");
      _status = NaverStatus.authenticateError;
      notifyListeners(); // 에러 발생 시 상태를 변경하고 화면 업데이트
    }
  }

  Future<void> _handleDeepLink(BuildContext context, String link) async {
    try {
      print("deep link open $link");
      final Uri uri = Uri.parse(link);

      if (uri.authority == 'login-callback') {
        String? firebaseToken = uri.queryParameters['firebaseToken'];
        String? name = uri.queryParameters['name'];
        String? profileImage = uri.queryParameters['profileImage'];

        await firebaseAuth.signInWithCustomToken(firebaseToken!).then((value) async {
          final firebaseUser = value.user;
          if (firebaseUser == null) {
            _status = NaverStatus.authenticateError;
            notifyListeners();
            return;
          }

          final result = await firebaseFirestore
              .collection(FirestoreConstants.pathUserCollection)
              .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
              .get();
          final documents = result.docs;
          if (documents.isEmpty) {
            // Writing data to server because here is a new user
            await firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(firebaseUser.uid).set({
              FirestoreConstants.nickname: name,
              FirestoreConstants.photoUrl: profileImage,
              FirestoreConstants.id: firebaseUser.uid,
              FirestoreConstants.createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
              FirestoreConstants.chattingWith: null
            });

            // Write data to local storage
            await prefs.setString(FirestoreConstants.id, firebaseUser.uid);
            await prefs.setString(FirestoreConstants.nickname, name ?? "");
            await prefs.setString(FirestoreConstants.photoUrl, profileImage ?? "");
          } else {
            // Already signed up, just get data from firestore
            final documentSnapshot = documents.first;
            final userChat = UserInformation.fromDocument(documentSnapshot);
            // Write data to local
            await prefs.setString(FirestoreConstants.id, userChat.id);
            await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
            await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
            await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
          }

        }).onError((error, stackTrace) {
          print("error $error");
          _status = NaverStatus.authenticateError;
          notifyListeners();
        });
      }
    } catch (e) {
      print("Deep Link Handling Error: $e");
    }
  }

  void handleException() {
    _status = NaverStatus.authenticateException;
    notifyListeners();
  }

  Future<void> handleSignOut() async {
    _status = NaverStatus.uninitialized;
  }
}
