import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../providers/language_provider.dart';
import '../models/package_info.dart';
import '../services/purchase_service.dart';
import '../services/package_service.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen>
    with SingleTickerProviderStateMixin {
  final PurchaseService _purchaseService = PurchaseService();
  final PackageService _packageService = PackageService();
  List<PackageInfo> _packages = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _loadPackages();
    _setupPurchaseListener();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _purchaseService.dispose();
    super.dispose();
  }

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
      
      _animationController.forward();
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
            price: 1000,
          ),
          PackageInfo(
            id: 'history',
            nameKz: AppStrings.history['KZ']!,
            nameRu: AppStrings.history['RU']!,
            color: AppColors.packageHistory,
            isPurchased: historyPurchased,
            price: 1000,
          ),
        ];
        _isLoading = false;
      });
      
      _animationController.forward();
    }
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
            backgroundColor: AppColors.correctAnswer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (error != null) {
        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.wrongAnswer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    };
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
                ? 'Покупкаларды қалпына келтіру...'
                : 'Восстановление покупок...',
          ),
          backgroundColor: AppColors.darkCard,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.splashTop,
              AppColors.splashMiddle,
              AppColors.splashMiddle2,
              AppColors.splashBottom,
              AppColors.splashAccent,
              AppColors.cardBackground,
            ],
            stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Заголовок с улучшенным дизайном
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                        style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cardBackground,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Список пакетов
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                        ),
                      )
                    : _packages.isEmpty
                        ? Center(
                            child: Text(
                              currentLanguage == 'KZ'
                                  ? 'Пакеттер жоқ'
                                  : 'Пакеты недоступны',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 8.0,
                              ),
                              itemCount: _packages.length,
                              itemBuilder: (context, index) {
                                final package = _packages[index];
                                return _buildPackageCard(package, currentLanguage, index);
                              },
                            ),
                          ),
              ),
              
              // Кнопка восстановления покупок
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton(
                    onPressed: _handleRestorePurchases,
                    child: Text(
                      currentLanguage == 'KZ'
                          ? 'Покупкаларды қалпына келтіру'
                          : 'Восстановить покупки',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard(PackageInfo package, String language, int index) {
    final isPurchased = package.isPurchased;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isPurchased
                  ? AppColors.correctAnswer.withOpacity(0.5)
                  : AppColors.cardBorder.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: package.color.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            // Большой цветовой значок пакета
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    package.color,
                    package.color.withOpacity(0.6),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: package.color.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                Icons.quiz,
                color: AppColors.textPrimary,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            
            // Название и информация о пакете
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.getName(language),
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isPurchased
                          ? AppColors.textPrimary
                          : AppColors.textPrimary.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (package.price != null && !isPurchased) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${package.price} ₸',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ] else if (isPurchased) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.correctAnswer,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.getString(AppStrings.purchased, language),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.correctAnswer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Кнопка покупки/статус
            if (isPurchased)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.correctAnswer.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.correctAnswer,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.correctAnswer,
                  size: 28,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: package.color.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _handlePurchase(package.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: package.color,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppStrings.getString(AppStrings.buy, language),
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
