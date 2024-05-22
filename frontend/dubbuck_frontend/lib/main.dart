import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubbuck_front/page/splash/splash_page.dart';
import 'package:dubbuck_front/providers/google_auth_provider.dart';
import 'package:dubbuck_front/providers/chat_provider.dart';
import 'package:dubbuck_front/providers/home_provider.dart';
import 'package:dubbuck_front/providers/naver_auth_provider.dart';
import 'package:dubbuck_front/providers/setting_provider.dart';
import 'package:dubbuck_front/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constant/app_constants.dart';
import 'constant/localizationConfig_constants.dart';
import 'providers/kakao_auth_provider.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY']!,
    javaScriptAppKey: dotenv.env['KAKAO_JAVASCRIPT_APP_KEY']!,
  );

  // print(await KakaoSdk.origin); //
  await Firebase.initializeApp();

  SharedPreferences prefs = await SharedPreferences.getInstance();
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
              // delegate from flutter_localization
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,

              // delegate from localization package.
              //json-file
              LocalJsonLocalization.delegate,
              //or map
              MapLocalization.delegate,
            ],

            localeResolutionCallback: (locale, supportedLocales) {
              if (supportedLocales.contains(locale)) {
                return locale;
              }

              Locale? mappedLocale = LocalizationConfig.localeMapping[locale?.languageCode ?? ''];
              if (mappedLocale != null) {
                initializeDateFormatting(mappedLocale.toLanguageTag(), null);
                return mappedLocale;
              }

              initializeDateFormatting('en_US', null);
              return Locale('en', 'US');
            },

            title: AppConstants.appTitle,
            themeMode: notifier.isDark? ThemeMode.dark : ThemeMode.light,
            darkTheme: notifier.isDark? notifier.darkTheme : notifier.lightTheme,
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
}

