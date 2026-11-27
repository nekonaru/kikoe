// Shared design tokens and building blocks for the Kikoe app.
//
// Tokens follow three layers: primitive values, semantic roles and component
// constants. Motion helpers respect the platform reduced-motion setting.
library;

import 'package:flutter/material.dart';

// Primitive colors.
const kBrand = Color(0xFFFF7A5C); // accent for text and icons on dark surfaces
const kBrandFill = Color(0xFFC93B22); // button fill, paired with white text
const kBrandSoft = Color(0x26FF7A5C);
const kBg = Color(0xFF141414);
const kSurface = Color(0xFF1F1F1F);
const kSurface2 = Color(0xFF2A2A2A);
const kSurface3 = Color(0xFF353531);
const kText = Color(0xFFF4F1EC);
const kDim = Color(0xFF9B988F);
const kOk = Color(0xFF6FCF97);
const kWarning = Color(0xFFE8C46A);
const kDanger = Color(0xFFE87070);

// Spacing scale.
const kSpaceXs = 4.0;
const kSpaceSm = 8.0;
const kSpaceMd = 12.0;
const kSpaceLg = 16.0;
const kSpaceXl = 24.0;
const kSpaceXxl = 32.0;

// Radius scale.
const kRadiusSm = 8.0;
const kRadiusMd = 12.0;
const kRadiusLg = 18.0;
const kRadiusXl = 24.0;
const kCardRadius = kRadiusLg;

// Motion scale. Exits are shorter than enters.
const kMotionFast = Duration(milliseconds: 100);
const kMotionEnter = Duration(milliseconds: 220);
const kMotionExit = Duration(milliseconds: 150);
const kMotionPage = Duration(milliseconds: 300);
const kCurveOut = Curves.easeOutCubic;
const kCurveInOut = Curves.easeInOutCubic;

/// True when motion should be skipped entirely.
bool kMotionAllowed(BuildContext context) =>
    !MediaQuery.of(context).disableAnimations;

/// Returns the duration or zero when reduced motion is requested.
Duration kMotion(BuildContext context, Duration duration) =>
    kMotionAllowed(context) ? duration : Duration.zero;

/// Fades and scales its child when [id] changes. When the platform requests
/// reduced motion the child appears instantly instead.
class MotionBox extends StatelessWidget {
  const MotionBox({
    super.key,
    required this.id,
    required this.child,
  });

  final Object id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: kMotion(context, kMotionEnter),
      reverseDuration: kMotion(context, kMotionExit),
      switchInCurve: kCurveOut,
      switchOutCurve: kCurveOut,
      child: KeyedSubtree(key: ValueKey(id), child: child),
    );
  }
}

/// Rounded elevated card used for every section in the app.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      child: Padding(padding: const EdgeInsets.all(kSpaceLg), child: child),
    );
  }
}

/// Small caps section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: kSpaceSm),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.4,
          color: kDim,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A tappable row used on the About and FAQ-adjacent screens.
class LinkTile extends StatelessWidget {
  const LinkTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kSpaceSm, vertical: kSpaceMd),
            child: Row(
              children: [
                Icon(icon, color: kBrand, size: 22),
                const SizedBox(width: kSpaceLg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                      if (subtitle != null)
                        Text(subtitle!, style: const TextStyle(fontSize: 12, color: kDim)),
                    ],
                  ),
                ),
                trailing ??
                    const Icon(Icons.chevron_right, color: kDim, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Divider that matches the surface palette.
class SoftDivider extends StatelessWidget {
  const SoftDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: kSurface2);
  }
}
