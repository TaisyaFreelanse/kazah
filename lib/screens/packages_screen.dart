import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../models/package_info.dart';
import '../services/purchase_service.dart';
import '../services/package_service.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../widgets/package_badge.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final PurchaseService _purchaseService = PurchaseService();
  final PackageService _packageService = PackageService();
  List<PackageInfo> _packages = [];
  bool _isLoading = true;

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем пакеты из API
      final packages = await _packageService.getActivePackages();
      
      // Проверяем статус покупки для каждого пакета
      final packagesWithPurchaseStatus = <PackageInfo>[];
      for (final package in packages) {
        final isPurchased = await _purchaseService.isPackagePurchased(package.id);
        packagesWithPurchaseStatus.add(PackageInfo(
          id: package.id,
          nameKz: package.nameKz,
          nameRu: package.nameRu,
          color: package.color,
          isPurchased: isPurchased,
          price: package.price,
        ));
      }

      setState(() {
        _packages = packagesWithPurchaseStatus;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки пакетов: $e');
      // Fallback на пакеты по умолчанию
      final moreQuestionsPurchased = await _purchaseService.isPackagePurchased('more_questions');
      final historyPurchased = await _purchaseService.isPackagePurchased('history');

      setState(() {
        _packages = [
          PackageInfo(
            id: 'more_questions',
            nameKz: AppStrings.moreQuestions['KZ']!,
            nameRu: AppStrings.moreQuestions['RU']!,
            color: AppColors.packageMoreQuestions,
            isPurchased: moreQuestionsPurchased,
          ),
          PackageInfo(
            id: 'history',
            nameKz: AppStrings.history['KZ']!,
            nameRu: AppStrings.history['RU']!,
            color: AppColors.packageHistory,
            isPurchased: historyPurchased,
          ),
        ];
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPackages();
    _setupPurchaseListener();
  }

  void _setupPurchaseListener() {
    // Настраиваем обработчик обновлений покупок
    _purchaseService.onPurchaseUpdated = (packageId, success, error) {
      if (!mounted) return;

      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final currentLanguage = languageProvider.currentLanguage;

      if (success) {
        // Обновляем список пакетов
        _loadPackages();

        // Показываем сообщение об успешной покупке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentLanguage == 'KZ'
                  ? 'Пакет сатып алынды!'
                  : 'Пакет куплен!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (error != null) {
        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }

  Future<void> _handlePurchase(String packageId) async {
    // Инициируем покупку через In-App Purchase
    await _purchaseService.buyPackage(packageId);
    // Результат будет обработан через onPurchaseUpdated callback
  }

  Future<void> _handleRestorePurchases() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.currentLanguage;

    // Восстанавливаем покупки
    await _purchaseService.restorePurchases();

    // Показываем сообщение
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            currentLanguage == 'KZ'
                ? 'Покупки восстанавливаются...'
                : 'Восстановление покупок...',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.currentLanguage;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppStrings.getString(
                          AppStrings.additionalQuestions,
                          currentLanguage,
                        ),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Список пакетов
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              itemCount: _packages.length,
                              itemBuilder: (context, index) {
                                final package = _packages[index];
                                return _buildPackageCard(package, currentLanguage);
                              },
                            ),
                          ),
                          // Кнопка восстановления покупок
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: TextButton(
                              onPressed: _handleRestorePurchases,
                              child: Text(
                                currentLanguage == 'KZ'
                                    ? 'Покупкаларды қалпына келтіру'
                                    : 'Восстановить покупки',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(PackageInfo package, String language) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Цветовой значок пакета
            PackageBadge(color: package.color),
            const SizedBox(width: 16),
            
            // Название пакета
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.getName(language),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.isPurchased
                        ? AppStrings.getString(AppStrings.purchased, language)
                        : '',
                    style: TextStyle(
                      fontSize: 14,
                      color: package.isPurchased ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Кнопка покупки/статус
            if (package.isPurchased)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 32,
              )
            else
              ElevatedButton(
                onPressed: () => _handlePurchase(package.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: package.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppStrings.getString(AppStrings.buy, language),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

