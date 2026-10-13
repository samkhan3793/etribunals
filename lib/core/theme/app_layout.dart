import 'package:flutter/material.dart';

class AppLayout {
  static double pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 12;
    if (width > 600) return 24;
    return 16;
  }

  static int gridCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 840) return 3;
    if (width >= 360) return 2;
    return 1;
  }

  static double gridAspect(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 360) return 1.6;
    return 1.05;
  }
}
