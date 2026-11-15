// Open source licenses screen.
library;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'kikoe_theme.dart';

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _LicensesScreenState extends State<LicensesScreen> {
  String _version = '…';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() => _version = info.version);
    });
  }

  static const _kikoeMit = '''MIT License

Copyright (c) 2026 Nicolas Dwi Dharma (nekonaru)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.''';

  static const _whisperMit = '''MIT License

Copyright (c) 2023-2026 The ggml authors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.''';

  static const _credits = [
    _Credit('whisper.cpp', 'MIT', 'github.com/ggml-org/whisper.cpp',
        'The speech recognition engine inside Kikoe. Pinned to v1.9.5 as a git submodule.'),
    _Credit('ggml', 'MIT', 'github.com/ggml-org/ggml',
        'The tensor library whisper.cpp is built on. Ships inside whisper.cpp.'),
    _Credit('Flutter & Dart', 'BSD-3-Clause', 'flutter.dev',
        'UI toolkit and runtime for the Android and Windows apps.'),
    _Credit('FFmpeg', 'LGPL or GPL', 'ffmpeg.org',
        'Used as a separate program for media decoding by the CLI. Not linked into Kikoe.'),
    _Credit('OpenAI Whisper', 'MIT', 'github.com/openai/whisper',
        'Model weights, downloaded on demand, never bundled.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: const Text('Open source licenses'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Kikoe is open source. So is everything inside it.',
              style: TextStyle(fontSize: 12, color: kDim),
            ),
            const SizedBox(height: 14),
            _LicenseBlock(
              title: 'Kikoe (this app)',
              badge: 'MIT',
              body: _kikoeMit,
            ),
            const SizedBox(height: 14),
            _LicenseBlock(
              title: 'whisper.cpp',
              badge: 'MIT',
              body: _whisperMit,
            ),
            const SizedBox(height: 18),
            const SectionLabel('Credits'),
            SectionCard(
              child: Column(
                children: [
                  for (final c in _credits) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, color: kOk, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(c.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: kText)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: kSurface3,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(c.license,
                                          style: const TextStyle(
                                              fontSize: 9.5, color: kDim, letterSpacing: 0.6)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(c.note,
                                    style: const TextStyle(
                                        fontSize: 11, color: kDim, height: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (c != _credits.last) const SoftDivider(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Kikoe',
                  applicationVersion: _version,
                  applicationLegalese: '© 2026 Nicolas Dwi Dharma (nekonaru)',
                ),
                child: const Text('Bundled Dart package licenses'),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Full notices: THIRD_PARTY_NOTICES.md in the repository',
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

class _LicenseBlock extends StatelessWidget {
  const _LicenseBlock({required this.title, required this.badge, required this.body});

  final String title;
  final String badge;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kCardRadius),
        border: Border.all(color: kSurface2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: kText)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kBrandSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(badge,
                      style: const TextStyle(
                          fontSize: 9.5, color: kBrand, letterSpacing: 0.8, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 10.5, height: 1.45, color: kDim)),
          ],
        ),
      ),
    );
  }
}

class _Credit {
  const _Credit(this.name, this.license, this.url, this.note);

  final String name;
  final String license;
  final String url;
  final String note;
}
