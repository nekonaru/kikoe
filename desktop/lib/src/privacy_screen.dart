// Privacy policy screen. The short version, written to match what the app
// actually does.
library;

import 'l10n.dart';
import 'package:flutter/material.dart';

import 'kikoe_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const _sections = [
    _PolicySection(
      'The short version',
      'Kikoe makes no network requests except the ones you start yourself: model downloads and the update check. Your audio, video, transcripts and media files never leave your device. There is no account, no telemetry, no analytics and no crash reporting.',
    ),
    _PolicySection(
      'What Kikoe collects',
      'Nothing. Kikoe has no servers, no accounts, no analytics SDK, no ads and no tracking. The app does not read your contacts, location, camera, microphone (transcription works on files, not live audio) or clipboard.',
    ),
    _PolicySection(
      'Network requests',
      'Exactly two kinds, both user-initiated: (1) model downloads from the public whisper.cpp model hub on Hugging Face, which you start yourself, and (2) the update check in About, which you start by tapping Version. Both transfer no personal data. If you open a link (GitHub, sponsors, releases), your browser talks to that site under its own privacy policy.',
    ),
    _PolicySection(
      'Where your files live',
      'Transcripts you save are written to the Downloads/kikoe folder on your device by default (you can pick another folder in the desktop app). Transcription happens on your device; the files are yours and stay there. Kikoe never uploads them.',
    ),
    _PolicySection(
      'Model files',
      'Whisper model files are downloaded once into the app\'s private storage (or the CLI cache directory). They are never sent anywhere. Model downloads are verified by SHA-256 before use.',
    ),
    _PolicySection(
      'Permissions',
      'Android requests only: INTERNET (model download and update check), POST_NOTIFICATIONS (transcription progress), and WRITE_EXTERNAL_STORAGE on Android 9 and below (saving to Downloads/kikoe; on Android 10+ the MediaStore API is used and this permission is not requested).',
    ),
    _PolicySection(
      'Third parties',
      'github.com (source, releases, update check), huggingface.co (model files). Sponsor links are optional and open in your browser: GitHub Sponsors, Saweria, SociaBuzz or BagiBagi. Kikoe receives no data and no payment information from those sites.',
    ),
    _PolicySection(
      'Data deletion',
      'Uninstalling the app removes its private data. Transcripts in Downloads/kikoe are ordinary files you keep; delete them with your file manager.',
    ),
    _PolicySection(
      'Children',
      'Kikoe collects no data from anyone, including children. It is a general-purpose utility.',
    ),
    _PolicySection(
      'Changes and contact',
      'This policy may change with new releases; the current version is always in the app and in the repository at PRIVACY.md. Questions: open a GitHub issue, or report security problems privately via the repository\'s security advisories.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text(tr('Privacy policy')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              'Effective: v1.0.1 · applies to all Kikoe apps',
              style: const TextStyle(fontSize: 11, color: kDim),
            ),
            const SizedBox(height: 12),
            const SectionCard(
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: kOk, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No data collection, no tracking, no account. Everything stays on your device.',
                      style: TextStyle(fontSize: 13, height: 1.4, color: kText),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final section in _sections) ...[
              SectionLabel(section.title),
              SectionCard(
                child: Text(section.body,
                    style: const TextStyle(fontSize: 12.5, height: 1.5, color: kText)),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection(this.title, this.body);

  final String title;
  final String body;
}
