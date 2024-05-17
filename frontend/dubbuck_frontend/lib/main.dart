import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubbuck_front/page/splash/splash_page.dart';
import 'package:dubbuck_front/providers/auth_provider.dart';
import 'package:dubbuck_front/providers/chat_provider.dart';
import 'package:dubbuck_front/providers/home_provider.dart';
import 'package:dubbuck_front/providers/setting_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constant/app_constants.dart';
import 'constant/color_constants.dart';
import 'constant/localizationConfig_constants.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            firebaseAuth: FirebaseAuth.instance,
            googleSignIn: GoogleSignIn(),
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
      child: MaterialApp(
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
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: ColorConstants.themeColor,
        ),
        home: SplashPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

