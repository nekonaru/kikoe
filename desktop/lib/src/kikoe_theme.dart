// Shared design tokens and building blocks for the Kikoe app.
library;

import 'package:flutter/material.dart';

const kBrand = Color(0xFFE8492D);
const kBrandSoft = Color(0x26E8492D);
const kBg = Color(0xFF141414);
const kSurface = Color(0xFF1F1F1F);
const kSurface2 = Color(0xFF2A2A2A);
const kSurface3 = Color(0xFF353531);
const kText = Color(0xFFF4F1EC);
const kDim = Color(0xFF9B988F);
const kOk = Color(0xFF6FCF97);
const kCardRadius = 18.0;

/// Rounded elevated card used for every section in the app.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
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
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          letterSpacing: 1.5,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
          child: Row(
            children: [
              Icon(icon, color: kBrand, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
                    if (subtitle != null)
                      Text(subtitle!, style: const TextStyle(fontSize: 11, color: kDim)),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right, color: kDim, size: 20),
            ],
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
