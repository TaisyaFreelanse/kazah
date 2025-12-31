class AppStrings {
  // Главное меню
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

  // Пакеты
  static const Map<String, String> moreQuestions = {
    'KZ': 'Көбірек сұрақтар',
    'RU': 'Больше вопросов',
  };

  static const Map<String, String> history = {
    'KZ': 'Қазақстан тарихы',
    'RU': 'История Казахстана',
  };

  // Сообщения
  static const Map<String, String> timeoutMessage = {
    'KZ': 'Ты не успел. Попробуй еще раз',
    'RU': 'К сожалению, ты не успел ответить',
  };

  // Кнопки
  static const Map<String, String> restart = {
    'KZ': 'ҚАЙТА БАСТАУ',
    'RU': 'НАЧАТЬ ЗАНОВО',
  };

  static const Map<String, String> mainMenu = {
    'KZ': 'БАСТЫ МӘЗІРГЕ',
    'RU': 'В ГЛАВНОЕ МЕНЮ',
  };

  // Пакеты
  static const Map<String, String> purchased = {
    'KZ': 'Сатып алынған',
    'RU': 'Куплено',
  };

  static const Map<String, String> buy = {
    'KZ': 'Сатып алу',
    'RU': 'Купить',
  };

  // Получить строку по языку
  static String getString(Map<String, String> strings, String language) {
    return strings[language] ?? strings['RU'] ?? '';
  }
}

