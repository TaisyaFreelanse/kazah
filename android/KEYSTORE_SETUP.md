# Настройка подписи приложения

## Шаг 1: Заполните key.properties

Откройте файл `android/key.properties` и заполните следующие данные:

```
storePassword=ВАШ_ПАРОЛЬ_ОТ_KEYSTORE
keyPassword=ВАШ_ПАРОЛЬ_ОТ_КЛЮЧА
keyAlias=ВАШ_ALIAS_КЛЮЧА
storeFile=app/keystore.jks
```

**Где взять эти данные:**
- `storePassword` - пароль от keystore.jks (который вы использовали при создании)
- `keyPassword` - пароль от ключа (может быть таким же как storePassword)
- `keyAlias` - имя alias ключа (обычно "upload" или "key" или имя, которое вы указали при создании)

**Чтобы узнать alias, выполните:**
```bash
keytool -list -v -keystore android/app/keystore.jks
```
(потребуется ввести пароль от keystore)

## Шаг 2: Сборка AAB

После заполнения key.properties выполните:
```bash
flutter build appbundle --release
```

Готовый файл будет в: `build/app/outputs/bundle/release/app-release.aab`

