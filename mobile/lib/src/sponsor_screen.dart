// Sponsor screen: external links to the author's sponsorship profiles.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'kikoe_theme.dart';

class SponsorScreen extends StatelessWidget {
  const SponsorScreen({super.key});

  static const _options = [
    _SponsorOption(
      icon: Icons.favorite,
      color: Color(0xFFE91E63),
      name: 'GitHub Sponsors',
      subtitle: 'github.com/sponsors/nekonaru',
      url: 'https://github.com/sponsors/nekonaru',
    ),
    _SponsorOption(
      icon: Icons.local_cafe_outlined,
      color: Color(0xFFFFB300),
      name: 'Saweria',
      subtitle: 'saweria.co/nekonaruu',
      url: 'https://saweria.co/nekonaruu',
    ),
    _SponsorOption(
      icon: Icons.diversity_3_outlined,
      color: Color(0xFF1DBF73),
      name: 'SociaBuzz',
      subtitle: 'sociabuzz.com/nekonaru/donate',
      url: 'https://sociabuzz.com/nekonaru/donate',
    ),
    _SponsorOption(
      icon: Icons.card_giftcard_outlined,
      color: Color(0xFF7C4DFF),
      name: 'BagiBagi',
      subtitle: 'bagibagi.co/Nekonaru',
      url: 'https://bagibagi.co/Nekonaru',
    ),
  ];

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the browser.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: const Text('Sponsor Kikoe'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: kBrandSoft,
                border: Border.all(color: kBrand.withValues(alpha: 0.4)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.volunteer_activism, color: kBrand, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Kikoe is free, ad-free and open source.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'It is built and maintained by one developer in spare time. If Kikoe saves you hours of transcription, a small tip keeps the project alive.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: kDim, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Ways to support'),
            for (final option in _options) ...[
              SectionCard(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _open(context, option.url),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: option.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(option.icon, color: option.color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(option.name,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                              const SizedBox(height: 2),
                              Text(option.subtitle,
                                  style: const TextStyle(fontSize: 11, color: kDim)),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new, color: kDim, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Every option opens in your browser. Kikoe never sees the transaction.',
                style: TextStyle(fontSize: 11, color: kDim),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorOption {
  const _SponsorOption({
    required this.icon,
    required this.color,
    required this.name,
    required this.subtitle,
    required this.url,
  });

  final IconData icon;
  final Color color;
  final String name;
  final String subtitle;
  final String url;
}
