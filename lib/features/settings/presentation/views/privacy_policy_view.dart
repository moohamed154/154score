import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_brand_logo.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  static const String privacyPolicyUrl =
      'https://154score-api.medohs770.workers.dev/privacy';

  Future<void> _openExternalPolicy(BuildContext context, bool isArabic) async {
    await HapticFeedback.selectionClick();
    final uri = Uri.parse(privacyPolicyUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تعذر فتح الرابط في المتصفح الخارجي'
                : 'Could not open link in external browser',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          isArabic ? 'سياسة الخصوصية' : 'Privacy Policy',
          style: AppTypography.getHeadingMedium(
            isDark: isDark,
            isArabic: isArabic,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: isArabic ? 'فتح في المتصفح' : 'Open in Browser',
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            onPressed: () => _openExternalPolicy(context, isArabic),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.lg),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppBrandLogo(size: 48, isDark: isDark),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic
                                ? 'سياسة الخصوصية وشروط الاستخدام'
                                : 'Privacy Policy & Terms of Use',
                            style: AppTypography.getBodyLarge(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isArabic
                                ? 'آخر تحديث: 23 أكتوبر 2026'
                                : 'Last Updated: October 23, 2026',
                            style: AppTypography.getBodySmall(
                              isDark: isDark,
                              isArabic: isArabic,
                            ).copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  isArabic
                      ? 'نحن في 154Score نلتزم بحماية خصوصيتك وضمان تجربة رياضية آمنة وسريعة لمتابعة نتائج المباريات المباشرة والإحصائيات والأخبار الرياضية دون الحاجة لإنشاء حساب أو جمع أي بيانات شخصية حساسة.'
                      : 'At 154Score, we are committed to protecting your privacy and delivering a secure, fast real-time football experience without requiring account registration or collecting sensitive personal data.',
                  style: AppTypography.getBodySmall(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildSectionCard(
            isDark: isDark,
            isArabic: isArabic,
            icon: Icons.verified_user_rounded,
            title: isArabic
                ? '1. التزامنا بالخصوصية (Privacy-by-Design)'
                : '1. Our Privacy Commitment',
            points: isArabic
                ? const [
                    'لا يتطلب التطبيق إنشاء حساب أو تسجيل دخول أو تقديم اسمك أو بريدك الإلكتروني أو رقم هاتفك.',
                    'لا نجمع ولا نشارك ولا نبيع أي بيانات شخصية أو موقع جغرافي (GPS) لأي جهات إعلانية أو أطراف ثالثة.',
                  ]
                : const [
                    'No account registration, sign-in, name, email address, or phone number is required to use 154Score.',
                    'We never collect precise GPS location and never sell, rent, or share personal data with advertisers or third parties.',
                  ],
          ),

          const SizedBox(height: 14),

          _buildSectionCard(
            isDark: isDark,
            isArabic: isArabic,
            icon: Icons.storage_rounded,
            title: isArabic
                ? '2. البيانات والتفضيلات المحفوظة'
                : '2. Stored Preferences & Technical Data',
            points: isArabic
                ? const [
                    'الفرق والبطولات والمباريات المفضلة: تُحفظ محلياً على جهازك فقط لتخصيص جدول المباريات والترتيب.',
                    'إعدادات العرض: اللغة، المظهر (الداكن/الفاتح)، حجم الخط، والمنطقة الزمنية تُحفظ محلياً داخل مساحة التطبيق الآمنة.',
                    'رموز الإشعارات (FCM / APNs): عند تفعيل التنبيهات، يُستخدم رمز تقني عشوائي لإرسال تنبيهات الأهداف والمباريات التي اخترت متابعتها فقط.',
                  ]
                : const [
                    'Starred Teams, Leagues & Matches: Stored locally on your device to personalize your match schedule and standings.',
                    'Display Preferences: Language, theme mode, font scaling, and timezone offset are stored locally on your device.',
                    'Push Notification Tokens (FCM / APNs): Used strictly to deliver goal, kickoff, and match alerts you opt into.',
                  ],
          ),

          const SizedBox(height: 14),

          _buildSectionCard(
            isDark: isDark,
            isArabic: isArabic,
            icon: Icons.notifications_active_rounded,
            title: isArabic
                ? '3. الأذونات والأنشطة المباشرة (Live Activity)'
                : '3. Permissions & Live Activities',
            points: isArabic
                ? const [
                    'إذن الإنترنت والشبكة: لجلب نتائج المباريات المباشرة والتشكيلات والأخبار عبر اتصال مشفر (HTTPS / WSS).',
                    'إذن الإشعارات والخدمة الأمامية: لعرض إشعارات الأهداف وميزة النشاط المباشر (Live Activity) لعداد المباراة على شاشة القفل.',
                    'تنتهي جلسات متابعة المباراة المباشرة تلقائياً فور انتهاء المباراة أو عند إيقافها يدوياً من الإشعار.',
                  ]
                : const [
                    'Internet & Network State: Fetches live scores, lineups, and news over encrypted HTTPS and WebSockets.',
                    'Notifications & Foreground Service: Powers goal alerts and Lock Screen Live Activity match clocks.',
                    'Live Activity sessions automatically terminate as soon as a match ends or when manually stopped.',
                  ],
          ),

          const SizedBox(height: 14),

          _buildSectionCard(
            isDark: isDark,
            isArabic: isArabic,
            icon: Icons.lock_rounded,
            title: isArabic
                ? '4. أمن البيانات والتحكم الكامل للمستخدم'
                : '4. Data Security & User Controls',
            points: isArabic
                ? const [
                    'جميع الاتصالات بين التطبيق والخوادم مشفرة بالكامل ومحمية بتوقيعات أمنية مشفرة (HMAC).',
                    'يمكنك إلغاء الاشتراك في إشعارات أي فريق أو مباراة في أي وقت، أو مسح بيانات التطبيق من إعدادات الجهاز لحذف كافة التفضيلات المحلية نهائياً.',
                    'للتواصل معنا بخصوص الخصوصية أو الدعم الفني: medohs770@gmail.com',
                  ]
                : const [
                    'All communications between the App and 154Score servers are encrypted via TLS/HTTPS and protected with HMAC cryptographic signatures.',
                    'You can disable notifications at any time or clear app storage / uninstall the app to permanently delete all local preferences.',
                    'For privacy inquiries or support, contact us at: medohs770@gmail.com',
                  ],
          ),

          const SizedBox(height: 20),

          // Open Web Version Button
          ElevatedButton.icon(
            onPressed: () => _openExternalPolicy(context, isArabic),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            icon: const Icon(Icons.public_rounded, size: 20),
            label: Text(
              isArabic
                  ? 'عرض النسخة الكاملة على الويب'
                  : 'View Full Web Privacy Policy',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required bool isArabic,
    required IconData icon,
    required String title,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.getBodyLarge(
                    isDark: isDark,
                    isArabic: isArabic,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map(
            (pt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pt,
                      style: AppTypography.getBodySmall(
                        isDark: isDark,
                        isArabic: isArabic,
                      ).copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
