import 'package:dubbuck_front/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../constant/app_constants.dart';
import '../../constant/color_constants.dart';
import '../../providers/google_auth_provider.dart' as auth;
import '../../providers/kakao_auth_provider.dart' as auth;
import '../../providers/kakao_auth_provider.dart';
import '../../providers/naver_auth_provider.dart' as auth;
import '../../providers/naver_auth_provider.dart';
import '../../widgets/loading_view.dart';
import '../main/main_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final googleAuthProvider = Provider.of<auth.AuthProviderGoogle>(context);
    final naverAuthProvider = Provider.of<auth.AuthProviderNaver>(context);
    final kakaoAuthProvider = Provider.of<auth.AuthProviderKakao>(context);

    switch (googleAuthProvider.status) {
      case GoogleStatus.authenticateError:
        Fluttertoast.showToast(msg: "Google Sign in fail");
        break;
      case GoogleStatus.authenticateCanceled:
        Fluttertoast.showToast(msg: "Google Sign in canceled");
        break;
      case GoogleStatus.authenticated:
        Fluttertoast.showToast(msg: "Google Sign in success");
        break;
      default:
        break;
    }

    switch (naverAuthProvider.status) {
      case NaverStatus.authenticateError:
        Fluttertoast.showToast(msg: "Naver Sign in fail");
        break;
      case NaverStatus.authenticateCanceled:
        Fluttertoast.showToast(msg: "Naver Sign in canceled");
        break;
      case NaverStatus.authenticated:
        Fluttertoast.showToast(msg: "Naver Sign in success");
        break;
      default:
        break;
    }

    switch (kakaoAuthProvider.status) {
      case KakaoStatus.authenticateError:
        Fluttertoast.showToast(msg: "Kakako Sign in fail");
        break;
      case KakaoStatus.authenticateCanceled:
        Fluttertoast.showToast(msg: "Kakako Sign in canceled");
        break;
      case KakaoStatus.authenticated:
        Fluttertoast.showToast(msg: "Kakako Sign in success");
        break;
      default:
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.loginTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getGoogleLoginButton(context),
                SizedBox(height: 20),
                getNaverLoginButton(context),
                SizedBox(height: 20),
                getKakaoLoginButton(context),
              ],
            ),
          ),
          // Loading
          Positioned(
            child: googleAuthProvider.status == GoogleStatus.authenticating ||
                naverAuthProvider.status == NaverStatus.authenticating ||
                kakaoAuthProvider.status == KakaoStatus.authenticating
                ? LoadingView()
                : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

Widget getGoogleLoginButton(BuildContext context) {
  return InkWell(
    onTap: () async {
      final authProviderGoogle = Provider.of<auth.AuthProviderGoogle>(context, listen: false);
      authProviderGoogle.handleSignIn().then((isSuccess) {
        if (isSuccess) {
          navigateToMainPage(context);
        }
      }).catchError((error, stackTrace) {
        print(error);
        print(stackTrace);

        Fluttertoast.showToast(msg: error.toString());
        authProviderGoogle.handleException();
      });
    },
    child: Card(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      elevation: 2,
      child: Ink.image(
        image: const AssetImage('assets/login/google.png'),
        fit: BoxFit.cover,
        height: 50,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: Colors.transparent,
          ),
          child: null,
        ),
      ),
    ),
  );
}

Widget getNaverLoginButton(BuildContext context) {
  return InkWell(
    onTap: () async {
      final authProviderNaver = Provider.of<auth.AuthProviderNaver>(context, listen: false);
      try {
        await authProviderNaver.initUniLinks(context);
        await authProviderNaver.signInWithNaver(context);
        navigateToMainPage(context);
      } catch (error, stackTrace) {
        print(error);
        print(stackTrace);
        Fluttertoast.showToast(msg: error.toString());
        authProviderNaver.handleException();
      }
    },
    child: Card(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      elevation: 2,
      child: Ink.image(
        image: const AssetImage('assets/login/naver.png'),
        fit: BoxFit.cover,
        height: 50,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: Colors.transparent,
          ),
          child: null,
        ),
      ),
    ),
  );
}

Widget getKakaoLoginButton(BuildContext context) {
  return InkWell(
    onTap: () async {
      final authProviderKakao = Provider.of<auth.AuthProviderKakao>(context, listen: false);
      authProviderKakao.handleSignIn().then((isSuccess) {
        if (isSuccess) {
          navigateToMainPage(context);
        }
      }).catchError((error, stackTrace) {
        print(error);
        print(stackTrace);

        Fluttertoast.showToast(msg: error.toString());
        authProviderKakao.handleException();
      });
    },
    child: Card(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      elevation: 2,
      child: Ink.image(
        image: const AssetImage('assets/login/kakao.png'),
        fit: BoxFit.cover,
        height: 50,
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: Colors.transparent,
          ),
          child: null,
        ),
      ),
    ),
  );
}
void navigateToMainPage(BuildContext context) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MainPage(),
    ),
  );
}
