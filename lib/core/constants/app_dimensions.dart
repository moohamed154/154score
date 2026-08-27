import 'package:flutter/widgets.dart';

class AppDimensions {
  AppDimensions._();

  // Spacing & Padding
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Border Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 999.0;

  // Layout Breakpoints
  static const double smallPhoneMaxWidth = 360.0;
  static const double mobileMaxWidth = 768.0;
  static const double tabletMaxWidth = 1024.0;
  static const double desktopContentMaxWidth = 1280.0;

  // Sizes
  static const double logoSizeSm = 20.0;
  static const double logoSizeMd = 28.0;
  static const double logoSizeLg = 40.0;
  static const double logoSizeXl = 64.0;

  static const double cardHeightMatch = 84.0;
  static const double dateBarHeight = 56.0;

  // Responsive Helpers using modern MediaQuery.sizeOf(context)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width < smallPhoneMaxWidth;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletMaxWidth;
  }

  static double getHorizontalMargin(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < smallPhoneMaxWidth) return sm;
    if (width >= mobileMaxWidth) return xl;
    return lg;
  }

  static double getCardPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < smallPhoneMaxWidth) return sm;
    return lg;
  }
}
