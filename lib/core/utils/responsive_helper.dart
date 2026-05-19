import 'package:flutter/material.dart';

/// Helper class for responsive design across mobile, tablet, and desktop
class ResponsiveHelper {
  const ResponsiveHelper._();

  /// Breakpoints for different device types
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get screen width
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if device is mobile (width < 600)
  static bool isMobile(BuildContext context) {
    return getWidth(context) < mobileBreakpoint;
  }

  /// Check if device is tablet (600 <= width < 900)
  static bool isTablet(BuildContext context) {
    final width = getWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is desktop (width >= 900)
  static bool isDesktop(BuildContext context) {
    return getWidth(context) >= tabletBreakpoint;
  }

  /// Check if device is large screen (tablet or desktop)
  static bool isLargeScreen(BuildContext context) {
    return getWidth(context) >= mobileBreakpoint;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(24);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(12);
    }
  }

  /// Get responsive font size
  static double getFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isDesktop(context)) {
      return desktop;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 2;
    }
  }

  /// Get responsive container width (for centered content on large screens)
  static double? getContainerWidth(BuildContext context) {
    if (isDesktop(context)) {
      return 1200.0;
    } else if (isTablet(context)) {
      return 800.0;
    } else {
      return null; // Full width on mobile
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    if (isDesktop(context)) {
      return 28;
    } else if (isTablet(context)) {
      return 24;
    } else {
      return 20;
    }
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    if (isDesktop(context)) {
      return 56;
    } else if (isTablet(context)) {
      return 50;
    } else {
      return 44;
    }
  }

  /// Get responsive avatar size
  static double getAvatarSize(BuildContext context) {
    if (isDesktop(context)) {
      return 80;
    } else if (isTablet(context)) {
      return 60;
    } else {
      return 45;
    }
  }

  /// Get responsive card elevation
  static double getCardElevation(BuildContext context) {
    if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Get responsive border radius
  static double getBorderRadius(BuildContext context) {
    if (isDesktop(context)) {
      return 16;
    } else if (isTablet(context)) {
      return 12;
    } else {
      return 8;
    }
  }

  /// Scale a value based on screen size
  static double scale(BuildContext context, double value) {
    if (isDesktop(context)) {
      return value * 1.3;
    } else if (isTablet(context)) {
      return value * 1.15;
    } else {
      return value;
    }
  }
}
