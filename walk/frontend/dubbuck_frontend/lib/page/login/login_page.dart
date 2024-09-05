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
            child: Consumer3<auth.AuthProviderGoogle, auth.AuthProviderNaver, auth.AuthProviderKakao>(
              builder: (context, googleAuthProvider, naverAuthProvider, kakaoAuthProvider, child) {
                return googleAuthProvider.status == GoogleStatus.authenticating ||
                    naverAuthProvider.status == NaverStatus.authenticating ||
                    kakaoAuthProvider.status == KakaoStatus.authenticating
                    ? LoadingView()
                    : SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget getGoogleLoginButton(BuildContext context) {
    return InkWell(
      onTap: () async {
        final googleAuthProvider = Provider.of<auth.AuthProviderGoogle>(context, listen: false);
        googleAuthProvider.handleSignIn().then((isSuccess) {
          if (isSuccess) {
            navigateToMainPage(context);
          } else {
            _showToastMessage(googleAuthProvider.status);
          }
        }).catchError((error, stackTrace) {
          print(error);
          print(stackTrace);
          Fluttertoast.showToast(msg: error.toString());
          googleAuthProvider.handleException();
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
        final naverAuthProvider = Provider.of<auth.AuthProviderNaver>(context, listen: false);
        try {
          await naverAuthProvider.initUniLinks();
          bool isSuccess = await naverAuthProvider.signInWithNaver();
          if (isSuccess) {
            navigateToMainPage(context);
          } else {
            _showToastMessage(naverAuthProvider.status);
          }
        } catch (error, stackTrace) {
          print(error);
          print(stackTrace);
          Fluttertoast.showToast(msg: error.toString());
          naverAuthProvider.handleException();
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
        final kakaoAuthProvider = Provider.of<auth.AuthProviderKakao>(context, listen: false);
        kakaoAuthProvider.handleSignIn().then((isSuccess) {
          if (isSuccess) {
            navigateToMainPage(context);
          } else {
            _showToastMessage(kakaoAuthProvider.status);
          }
        }).catchError((error, stackTrace) {
          print(error);
          print(stackTrace);
          Fluttertoast.showToast(msg: error.toString());
          kakaoAuthProvider.handleException();
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

  void _showToastMessage(dynamic status) {
    String message = "";
    if (status is GoogleStatus) {
      switch (status) {
        case GoogleStatus.authenticateError:
          message = "Google Sign in fail";
          break;
        case GoogleStatus.authenticateCanceled:
          message = "Google Sign in canceled";
          break;
        case GoogleStatus.authenticated:
          message = "Google Sign in success";
          break;
        default:
          break;
      }
    } else if (status is NaverStatus) {
      switch (status) {
        case NaverStatus.authenticateError:
          message = "Naver Sign in fail";
          break;
        case NaverStatus.authenticateCanceled:
          message = "Naver Sign in canceled";
          break;
        case NaverStatus.authenticated:
          message = "Naver Sign in success";
          break;
        default:
          break;
      }
    } else if (status is KakaoStatus) {
      switch (status) {
        case KakaoStatus.authenticateError:
          message = "Kakao Sign in fail";
          break;
        case KakaoStatus.authenticateCanceled:
          message = "Kakao Sign in canceled";
          break;
        case KakaoStatus.authenticated:
          message = "Kakao Sign in success";
          break;
        default:
          break;
      }
    }
    Fluttertoast.showToast(msg: message);
  }

  void navigateToMainPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainPage(),
      ),
    );
  }
}
