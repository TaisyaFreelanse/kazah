class AppStrings {

  static const Map<String, String> start = {
    'KZ': 'СТАРТ ОЙЫН',
    'RU': 'СТАРТ ИГРЫ',
  };

  static const Map<String, String> additionalQuestions = {
    'KZ': 'ҚОСЫМША СҰРАҚТАР',
    'RU': 'ДОПОЛНИТЕЛЬНЫЕ ВОПРОСЫ',
  };

  static const Map<String, String> exitGame = {
    'KZ': 'ОЙЫННАН ШЫҒУ',
    'RU': 'ВЫХОД ИЗ ИГРЫ',
  };

  static const Map<String, String> moreQuestions = {
    'KZ': 'Көбірек сұрақтар',
    'RU': 'Больше вопросов',
  };

  static const Map<String, String> history = {
    'KZ': 'Қазақстан тарихы',
    'RU': 'История Казахстана',
  };

  static const Map<String, String> timeoutMessage = {
    'KZ': 'Сіз уақытында жауап бермедіңіз. Қайта бастаңыз',
    'RU': 'К сожалению, ты не успел ответить',
  };

  static const Map<String, String> restart = {
    'KZ': 'ҚАЙТА БАСТАУ',
    'RU': 'НАЧАТЬ ЗАНОВО',
  };

  static const Map<String, String> mainMenu = {
    'KZ': 'БАСТЫ МӘЗІРГЕ',
    'RU': 'В ГЛАВНОЕ МЕНЮ',
  };

  static const Map<String, String> purchased = {
    'KZ': 'Сатып алынған',
    'RU': 'Куплено',
  };

  static const Map<String, String> buy = {
    'KZ': 'Сатып алу',
    'RU': 'Купить',
  };

  static const Map<String, String> packageInfo = {
    'KZ': 'Әр пакет бір рет қана сатып алынады және сізде мәңгілікке қалады.\nПакетке кіретін сұрақ шыққан кезде, ол түсті белгішемен белгіленеді',
    'RU': 'Каждый пакет приобретается один раз и остается у вас навсегда.\nКогда вам попадется вопрос из пакета, он будет иметь цветовой значок',
  };

  static const Map<String, String> wrongAnswerMessage = {
    'KZ': 'Сенің жауабын қате',
    'RU': 'Ты ответил неверно',
  };

  static String getString(Map<String, String> strings, String language) {
    return strings[language] ?? strings['RU'] ?? '';
  }
}

