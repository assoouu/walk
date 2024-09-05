import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:localization/localization.dart';

import 'constant/app_constants.dart';
import 'constant/localizationConfig_constants.dart';
import 'providers/kakao_auth_provider.dart';
import 'providers/google_auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/home_provider.dart';
import 'providers/naver_auth_provider.dart';
import 'providers/setting_provider.dart';
import 'providers/theme_provider.dart';
import 'page/splash/splash_page.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // Kakao SDK 초기화
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!,
    javaScriptAppKey: dotenv.env['KAKAO_JAVASCRIPT_APP_KEY']!,
  );

  // Firebase 초기화
  await Firebase.initializeApp();

  // SharedPreferences 초기화
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // DateFormatting 초기화
  await initializeDateFormatting('ko_KR', null);

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  MyApp({required this.prefs});

  final _firebaseFirestore = FirebaseFirestore.instance;
  final _firebaseStorage = FirebaseStorage.instance;

  @override
  Widget build(BuildContext context) {
    LocalJsonLocalization.delegate.directories = ['lib/i18n'];

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UiProvider>(
          create: (_) => UiProvider()..init(),
        ),
        ChangeNotifierProvider<AuthProviderGoogle>(
          create: (_) => AuthProviderGoogle(
            firebaseAuth: FirebaseAuth.instance,
            googleSignIn: GoogleSignIn(),
            prefs: this.prefs,
            firebaseFirestore: this._firebaseFirestore,
          ),
        ),
        ChangeNotifierProvider<AuthProviderNaver>(
          create: (_) => AuthProviderNaver(
            firebaseAuth: FirebaseAuth.instance,
            prefs: this.prefs,
            firebaseFirestore: this._firebaseFirestore,
          ),
        ),
        ChangeNotifierProvider<AuthProviderKakao>(
          create: (_) => AuthProviderKakao(
            firebaseAuth: FirebaseAuth.instance,
            prefs: this.prefs,
            firebaseFirestore: this._firebaseFirestore,
          ),
        ),
        Provider<SettingProvider>(
          create: (_) => SettingProvider(
            prefs: this.prefs,
            firebaseFirestore: this._firebaseFirestore,
            firebaseStorage: this._firebaseStorage,
          ),
        ),
        Provider<HomeProvider>(
          create: (_) => HomeProvider(
            firebaseFirestore: this._firebaseFirestore,
          ),
        ),
        Provider<ChatProvider>(
          create: (_) => ChatProvider(
            prefs: this.prefs,
            firebaseFirestore: this._firebaseFirestore,
            firebaseStorage: this._firebaseStorage,
          ),
        ),
      ],
      child: Consumer<UiProvider>(
        builder: (context, UiProvider notifier, child) {
          return MaterialApp(
            localizationsDelegates: [
              // flutter_localization의 delegate
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,

              // localization 패키지의 delegate
              // JSON 파일 사용
              LocalJsonLocalization.delegate,
              // 또는 Map 사용
            ],
            supportedLocales: LocalizationConfig.localeMapping.values.toList(),
            locale: getLocale(), // 사용자 로케일 설정
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode &&
                      supportedLocale.countryCode == locale.countryCode) {
                    return supportedLocale;
                  }
                }
              }
              return supportedLocales.first;
            },
            title: AppConstants.appTitle,
            themeMode: notifier.isDark ? ThemeMode.dark : ThemeMode.light,
            darkTheme: notifier.isDark ? notifier.darkTheme : notifier.lightTheme,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: SplashPage(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  Locale getLocale() {
    // SharedPreferences에서 저장된 언어를 가져옴
    Locale systemLocale = window.locale;
    if (LocalizationConfig.localeMapping.containsKey(systemLocale.languageCode)) {
      return LocalizationConfig.localeMapping[systemLocale.languageCode]!;
    }
    // 기본 로케일 설정
    return Locale('en', 'US');
  }
}
