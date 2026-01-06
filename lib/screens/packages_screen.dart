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
import '../utils/responsive.dart';
import '../services/cache_service.dart';
import 'game_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen>
    with SingleTickerProviderStateMixin {
  final PurchaseService _purchaseService = PurchaseService();
  final PackageService _packageService = PackageService.instance;
  List<PackageInfo> _packages = [];
  bool _isLoading = true;
  bool _testMode = false;
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
    _setupPurchaseListener();
    _loadPackagesInitial();
    _loadTestMode();
  }

  Future<void> _loadTestMode() async {
    final testMode = _purchaseService.getTestMode();
    setState(() {
      _testMode = testMode;
    });
  }

  Future<void> _toggleTestMode() async {
    final newMode = !_testMode;
    await _purchaseService.setTestMode(newMode);
    setState(() {
      _testMode = newMode;
    });
    
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.currentLanguage;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentLanguage == 'KZ'
              ? 'Тест режимі ${newMode ? "қосылды" : "өшірілді"}'
              : 'Тестовый режим ${newMode ? "включен" : "выключен"}',
        ),
        backgroundColor: newMode ? AppColors.correctAnswer : AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadPackagesInitial() async {
    try {
      final cachedPackages = await _packageService.getActivePackages();
      if (cachedPackages.isNotEmpty && mounted) {
        final productIds = cachedPackages.map((p) => p.getProductId()).toSet();
        await _purchaseService.updateProductIds(productIds);
        await _updatePackagesWithPurchaseStatus(cachedPackages);
        _animationController.forward();
      }
    } catch (e) {
    }
    _loadPackages();
  }

  Future<void> _updatePackagesWithPurchaseStatus(List<PackageInfo> packages) async {
    final purchaseChecks = packages.map((package) => 
      _purchaseService.isPackagePurchased(package.id).then((isPurchased) => 
        PackageInfo(
          id: package.id,
          nameKz: package.nameKz,
          nameRu: package.nameRu,
          color: package.color,
          isPurchased: isPurchased,
          price: package.price,
        )
      )
    );
    
    final packagesWithPurchaseStatus = await Future.wait(purchaseChecks);

    packagesWithPurchaseStatus.sort((a, b) {
      final aName = a.getName('RU').toLowerCase();
      final bName = b.getName('RU').toLowerCase();

      if (aName.contains('больше вопросов') || aName.contains('көбірек сұрақтар')) return -1;
      if (bName.contains('больше вопросов') || bName.contains('көбірек сұрақтар')) return 1;

      if (aName.contains('история') || aName.contains('тарихы')) return -1;
      if (bName.contains('история') || bName.contains('тарихы')) return 1;

      return 0;
    });

    if (mounted) {
      setState(() {
        _packages = packagesWithPurchaseStatus;
        _isLoading = false;
      });
    }
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
      final packages = await _packageService.getActivePackages();
      
      if (packages.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final productIds = packages.map((p) => p.getProductId()).toSet();
      await _purchaseService.updateProductIds(productIds);

      await _updatePackagesWithPurchaseStatus(packages);
      _animationController.forward();
    } catch (e) {
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

    _purchaseService.onPurchaseUpdated = (packageId, success, error) async {
      if (!mounted) return;

      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final currentLanguage = languageProvider.currentLanguage;

      if (success) {
        CacheService.instance.clearCache();
        _loadPackages();

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
            duration: const Duration(seconds: 2),
            action: _testMode
                ? SnackBarAction(
                    label: currentLanguage == 'KZ' ? 'Ойынға өту' : 'К игре',
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameScreen(),
                        ),
                      );
                    },
                  )
                : null,
          ),
        );

        if (_testMode) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const GameScreen(),
              ),
            );
          }
        }
      } else if (error != null) {

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
    final package = _packages.firstWhere(
      (p) => p.id == packageId,
      orElse: () => throw Exception('Пакет не найден'),
    );
    
    final productId = package.getProductId();
    await _purchaseService.buyPackage(packageId, productId: productId);
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

              LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = Responsive.screenHeight(context);
                  final isSmallScreen = screenHeight < 700;

                  return Padding(
                    padding: Responsive.horizontalPadding(
                      context,
                      small: isSmallScreen ? 16 : 20,
                      medium: 22,
                      large: 24,
                    ).copyWith(
                      top: Responsive.dp(context, isSmallScreen ? 12 : 16),
                      bottom: Responsive.dp(context, isSmallScreen ? 12 : 16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            color: AppColors.cardBackground,
                            size: Responsive.iconSize(context, small: 24, medium: 28, large: 32),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(width: Responsive.dp(context, 8)),
                        Expanded(
                          child: GestureDetector(
                            onLongPress: _toggleTestMode,
                            child: Text(
                              AppStrings.getString(
                                AppStrings.additionalQuestions,
                                currentLanguage,
                              ),
                              style: GoogleFonts.nunito(
                                fontSize: Responsive.textSize(context, isSmallScreen ? 18 : 20),
                                fontWeight: FontWeight.bold,
                                color: AppColors.cardBackground,
                                letterSpacing: Responsive.dp(context, 0.3),
                              ),
                            ),
                          ),
                        ),
                        if (_testMode)
                          Container(
                            margin: EdgeInsets.only(left: Responsive.dp(context, 8)),
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.dp(context, 8),
                              vertical: Responsive.dp(context, 4),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.correctAnswer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(Responsive.dp(context, 8)),
                              border: Border.all(
                                color: AppColors.correctAnswer,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'TEST',
                              style: GoogleFonts.nunito(
                                fontSize: Responsive.textSize(context, 10),
                                fontWeight: FontWeight.bold,
                                color: AppColors.correctAnswer,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = Responsive.screenHeight(context);
                  final isSmallScreen = screenHeight < 700;

                  return Padding(
                    padding: Responsive.horizontalPadding(
                      context,
                      small: isSmallScreen ? 16 : 20,
                      medium: 22,
                      large: 24,
                    ).copyWith(
                      bottom: Responsive.dp(context, isSmallScreen ? 8 : 12),
                    ),
                    child: Text(
                      AppStrings.getString(AppStrings.packageInfo, currentLanguage),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: Responsive.textSize(context, isSmallScreen ? 12 : 14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.cardBackground.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  );
                },
              ),

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
                                fontSize: Responsive.adaptiveFontSize(context, small: 16, medium: 17, large: 18),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final screenHeight = Responsive.screenHeight(context);
                              final isSmallScreen = screenHeight < 700;

                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: ListView.builder(
                                  padding: Responsive.horizontalPadding(
                                    context,
                                    small: isSmallScreen ? 16 : 20,
                                    medium: 22,
                                    large: 24,
                                  ).copyWith(
                                    top: Responsive.dp(context, 8),
                                    bottom: Responsive.dp(context, 8),
                                  ),
                                  itemCount: _packages.length,
                                  itemBuilder: (context, index) {
                                    final package = _packages[index];
                                    return _buildPackageCard(package, currentLanguage, index);
                                  },
                                ),
                              );
                            },
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
    final screenHeight = Responsive.screenHeight(context);
    final isSmallScreen = screenHeight < 700;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: Responsive.dp(context, 10),
          sigmaY: Responsive.dp(context, 10),
        ),
        child: Container(
          margin: EdgeInsets.only(bottom: Responsive.dp(context, isSmallScreen ? 12 : 16)),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.4),
            borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
            border: Border.all(
              color: isPurchased
                  ? AppColors.correctAnswer.withOpacity(0.5)
                  : AppColors.cardBorder.withOpacity(0.5),
              width: Responsive.dp(context, 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: package.color.withOpacity(0.3),
                blurRadius: Responsive.dp(context, 15),
                spreadRadius: Responsive.dp(context, 1),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: Responsive.dp(context, 8),
                offset: Offset(0, Responsive.dp(context, 2)),
              ),
            ],
          ),
          child: Padding(
            padding: Responsive.symmetricPadding(
              context,
              small: isSmallScreen ? 12 : 16,
              medium: 18,
              large: 20,
            ),
            child: Row(
              children: [

                Container(
                  width: Responsive.dp(context, isSmallScreen ? 48 : 56),
                  height: Responsive.dp(context, isSmallScreen ? 48 : 56),
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
                        blurRadius: Responsive.dp(context, 12),
                        spreadRadius: Responsive.dp(context, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.quiz,
                    color: AppColors.textPrimary,
                    size: Responsive.dp(context, isSmallScreen ? 24 : 28),
                  ),
                ),
                SizedBox(width: Responsive.dp(context, isSmallScreen ? 10 : 12)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        package.getName(language),
                        style: GoogleFonts.nunito(
                          fontSize: Responsive.textSize(context, isSmallScreen ? 15 : 17),
                          fontWeight: FontWeight.bold,
                          color: isPurchased
                              ? AppColors.textPrimary
                              : AppColors.textPrimary.withOpacity(0.9),
                          letterSpacing: Responsive.dp(context, 0.3),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: Responsive.dp(context, isSmallScreen ? 4 : 6)),
                      if (package.price != null && !isPurchased) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${package.price}',
                              style: GoogleFonts.nunito(
                                fontSize: Responsive.textSize(context, isSmallScreen ? 14 : 16),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: Responsive.dp(context, 4)),
                            Text(
                              '₸',
                              style: GoogleFonts.nunito(
                                fontSize: Responsive.textSize(context, isSmallScreen ? 14 : 16),
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
                              size: Responsive.dp(context, isSmallScreen ? 14 : 16),
                              color: AppColors.correctAnswer,
                            ),
                            SizedBox(width: Responsive.dp(context, 6)),
                            Text(
                              AppStrings.getString(AppStrings.purchased, language),
                              style: GoogleFonts.nunito(
                                fontSize: Responsive.textSize(context, isSmallScreen ? 12 : 14),
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

                SizedBox(width: Responsive.dp(context, isSmallScreen ? 8 : 12)),

                if (isPurchased)
                  Container(
                    padding: Responsive.symmetricPadding(
                      context,
                      small: isSmallScreen ? 8 : 10,
                      medium: 12,
                      large: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.correctAnswer.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.correctAnswer,
                        width: Responsive.dp(context, 1.5),
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.correctAnswer,
                      size: Responsive.dp(context, isSmallScreen ? 20 : 24),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
                      boxShadow: [
                        BoxShadow(
                          color: package.color.withOpacity(0.5),
                          blurRadius: Responsive.dp(context, 12),
                          spreadRadius: Responsive.dp(context, 1),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _handlePurchase(package.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBackground,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.dp(context, isSmallScreen ? 16 : 20),
                          vertical: Responsive.dp(context, isSmallScreen ? 10 : 12),
                        ),
                        minimumSize: Size(
                          0,
                          Responsive.dp(context, isSmallScreen ? 36 : 40),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        AppStrings.getString(AppStrings.buy, language),
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: Responsive.textSize(context, isSmallScreen ? 13 : 14),
                          letterSpacing: Responsive.dp(context, 0.3),
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
