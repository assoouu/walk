import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../constant/firestore_constants.dart';
import '../model/user_information.dart';

enum KakaoStatus {
  uninitialized,
  authenticated,
  authenticating,
  authenticateError,
  authenticateException,
  authenticateCanceled,
}

class AuthProviderKakao extends ChangeNotifier {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final SharedPreferences prefs;

  AuthProviderKakao({
    required this.firebaseAuth,
    required this.prefs,
    required this.firebaseFirestore,
  });

  KakaoStatus _status = KakaoStatus.uninitialized;

  KakaoStatus get status => _status;

  String? get userFirebaseId => prefs.getString(FirestoreConstants.id);

  Future<bool> isLoggedIn() async {
    bool isLoggedIn = firebaseAuth.currentUser != null;
    if (isLoggedIn && prefs.getString(FirestoreConstants.id)?.isNotEmpty == true) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> handleSignIn() async {
    _status = KakaoStatus.authenticating;
    notifyListeners();

    try {
      // 카카오톡 설치 여부 확인
      if (await isKakaoTalkInstalled()) {
        // 카카오톡으로 로그인 시도
        try {
          await UserApi.instance.loginWithKakaoTalk();
          print('카카오톡으로 로그인 성공');
        } catch (error) {
          print('카카오톡으로 로그인 실패: $error');
        }
      }

      // 카카오 계정으로 로그인 시도
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      print('카카오 계정으로 로그인 성공: ${token.accessToken}');

      var provider = OAuthProvider("oidc.dubbuck");
      var credential = provider.credential(
        idToken: token.idToken,
        accessToken: token.accessToken,
      );

      final firebaseUser = (await firebaseAuth.signInWithCredential(credential)).user;
      if (firebaseUser == null) {
        print('Firebase 사용자 정보 가져오기 실패');
        _status = KakaoStatus.authenticateError;
        notifyListeners();
        return false;
      }

      print('Firebase 사용자 정보 가져오기 성공: ${firebaseUser.uid}');

      final result = await firebaseFirestore
          .collection(FirestoreConstants.pathUserCollection)
          .where(FirestoreConstants.id, isEqualTo: firebaseUser.uid)
          .get();
      final documents = result.docs;
      if (documents.isEmpty) {
        // Writing data to server because here is a new user
        firebaseFirestore.collection(FirestoreConstants.pathUserCollection).doc(firebaseUser.uid).set({
          FirestoreConstants.nickname: firebaseUser.displayName,
          FirestoreConstants.photoUrl: firebaseUser.photoURL,
          FirestoreConstants.id: firebaseUser.uid,
          FirestoreConstants.createdAt: DateTime.now().millisecondsSinceEpoch.toString(),
          FirestoreConstants.chattingWith: null
        });

        // Write data to local storage
        await prefs.setString(FirestoreConstants.id, firebaseUser.uid);
        await prefs.setString(FirestoreConstants.nickname, firebaseUser.displayName ?? "");
        await prefs.setString(FirestoreConstants.photoUrl, firebaseUser.photoURL ?? "");
      } else {
        // Already sign up, just get data from firestore
        final documentSnapshot = documents.first;
        final userChat = UserInformation.fromDocument(documentSnapshot);
        // Write data to local
        await prefs.setString(FirestoreConstants.id, userChat.id);
        await prefs.setString(FirestoreConstants.nickname, userChat.nickname);
        await prefs.setString(FirestoreConstants.photoUrl, userChat.photoUrl);
        await prefs.setString(FirestoreConstants.aboutMe, userChat.aboutMe);
      }

      _status = KakaoStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      print("Error during Kakao sign in: $e");
      _status = KakaoStatus.authenticateException;
      notifyListeners();
      return false;
    }
  }

  void handleException() {
    _status = KakaoStatus.authenticateException;
    notifyListeners();
  }

  Future<void> handleSignOut() async {
    _status = KakaoStatus.uninitialized;
    await firebaseAuth.signOut();
    await UserApi.instance.logout();
  }
}
