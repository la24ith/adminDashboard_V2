import 'package:flutter/material.dart';

class ResponsiveHelper {
  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    if (width < 1600) return 4;
    return 5;
  }

  static double getCardAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 0.85;
    if (width < 900) return 0.8;
    if (width < 1200) return 0.75;
    return 0.7;
  }

  static double getCardHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return 380;
    if (width < 900) return 360;
    return 340;
  }
}
