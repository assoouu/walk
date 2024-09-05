import 'dart:ui';

class LocalizationConfig {
  static Map<String, Locale> localeMapping = {
    'ko': Locale('ko', 'KR'), // 한국어
    'zh': Locale('zh', 'CN'), // 중국어 (간체)
    'zh-Hant': Locale('zh', 'TW'), // 중국어 (번체)
    'ja': Locale('ja', 'JP'), // 일본어
    'de': Locale('de', 'DE'), // 독일어
    'fr': Locale('fr', 'FR'), // 프랑스어
    'es': Locale('es', 'ES'), // 스페인어
    'it': Locale('it', 'IT'), // 이탈리아어
    'pt': Locale('pt', 'PT'), // 포르투갈어
    'ru': Locale('ru', 'RU'), // 러시아어
    'ar': Locale('ar', 'SA'), // 아랍어 (사우디아라비아)
    'hi': Locale('hi', 'IN'), // 힌디어
    'th': Locale('th', 'TH'), // 태국어
    'vi': Locale('vi', 'VN'), // 베트남어
    'id': Locale('id', 'ID'), // 인도네시아어
  };
}
