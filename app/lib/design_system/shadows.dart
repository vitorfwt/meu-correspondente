import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static final BoxShadow official = BoxShadow(
    color: const Color(0xFF0D1B2A).withOpacity(0.08),
    blurRadius: 20,
    offset: const Offset(0, 4),
  );

  static final List<BoxShadow> officialShadows = [official];
}
