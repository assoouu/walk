import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constant/color_constants.dart';
import '../../../providers/google_auth_provider.dart';
import '../../../providers/kakao_auth_provider.dart';
import '../../../providers/naver_auth_provider.dart';
import '../login/login_page.dart';
import '../main/main_page.dart';

class SplashPage extends StatefulWidget {
  SplashPage({super.key});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      _checkSignedIn();
    });
  }

  void _checkSignedIn() async {
    final authProviderGoogle = context.read<AuthProviderGoogle>();
    final authProviderNaver = context.read<AuthProviderNaver>();
    final authProviderKakao = context.read<AuthProviderKakao>();

    bool isGoogleLoggedIn = await authProviderGoogle.isLoggedIn();
    bool isNaverLoggedIn = await authProviderNaver.isLoggedIn();
    bool isKakaoLoggedIn = await authProviderKakao.isLoggedIn();

    if (isGoogleLoggedIn || isNaverLoggedIn || isKakaoLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "assets/splash/broccoli.gif",
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            Container(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: ColorConstants.themeColor),
            ),
          ],
        ),
      ),
    );
  }
}
