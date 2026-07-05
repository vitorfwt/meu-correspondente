import 'package:flutter/material.dart';
import '../../design_system/radius.dart';
import '../../design_system/shadows.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.radiusCards),
        boxShadow: AppShadows.officialShadows,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: child,
      ),
    );
  }
}
