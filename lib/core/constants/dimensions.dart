import 'package:flutter/material.dart';

class Dimensions {
  // Spacing
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double space3XL = 32.0;
  static const double space4XL = 40.0;
  static const double space5XL = 48.0;
  static const double space6XL = 56.0;
  static const double space7XL = 64.0;

  // Border Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 20.0;
  static const double radiusCircle = 100.0;

  // Button Dimensions
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonBorderWidth = 1.5;

  // Input Field Dimensions
  static const double inputHeight = 52.0;
  static const double inputBorderWidth = 1.0;
  static const double inputBorderRadius = 8.0;

  // Card Dimensions
  static const double cardRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double cardElevationHover = 8.0;

  // App Bar
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;

  // Bottom Navigation
  static const double bottomNavHeight = 56.0;

  // Icons
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 28.0;
  static const double iconSizeXL = 32.0;
  static const double iconSizeXXL = 40.0;

  // Images
  static const double imageHeightSmall = 80.0;
  static const double imageHeightMedium = 120.0;
  static const double imageHeightLarge = 200.0;
  static const double imageHeightXLarge = 240.0;

  // Progress Indicators
  static const double progressIndicatorSize = 32.0;
  static const double progressIndicatorStroke = 3.0;

  // Divider
  static const double dividerThickness = 1.0;

  // Tab Bar
  static const double tabBarHeight = 48.0;
  static const double tabBarIndicatorHeight = 3.0;

  // Dialog
  static const double dialogRadius = 16.0;
  static const double dialogWidth = 320.0;

  // Bottom Sheet
  static const double bottomSheetRadius = 20.0;

  // Skeleton Loader
  static const double skeletonBorderRadius = 8.0;

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // Aspect Ratios
  static const double aspectRatioCard = 16 / 9;
  static const double aspectRatioProject = 4 / 3;
  static const double aspectRatioProfile = 1;

  // Padding
  static const EdgeInsets screenPadding = EdgeInsets.all(spaceL);
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceL);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: spaceXL,
    vertical: spaceM,
  );

  // Margins
  static const EdgeInsets defaultMargin = EdgeInsets.all(spaceL);
  static const EdgeInsets sectionMargin = EdgeInsets.only(
    top: spaceXXL,
    bottom: spaceXXL,
  );

  // Grid
  static const double gridSpacing = spaceL;
  static const int gridColumnsMobile = 2;
  static const int gridColumnsTablet = 3;
  static const int gridColumnsDesktop = 4;
}
