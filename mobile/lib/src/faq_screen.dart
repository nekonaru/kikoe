// FAQ screen: answers to the questions users actually ask.
library;

import 'package:flutter/material.dart';

import 'kikoe_theme.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _items = [
    _Faq('What is Kikoe?',
        'Kikoe (聞こえ) turns audio and video files into text and subtitles. It is a free, open source app built on whisper.cpp. Transcription runs entirely on your device; nothing is uploaded.'),
    _Faq('Do I need an account or a subscription?',
        'No. Kikoe is free forever. No minutes quota, no subscription, no API key, no account. Open source under the MIT License.'),
    _Faq('Does Kikoe need the internet?',
        'Only twice, both times because you started them: downloading a Whisper model (once per model) and checking for updates in About. Transcription itself is fully offline, and the app works with airplane mode on.'),
    _Faq('Where are my transcripts saved?',
        'Transcripts are saved into the Downloads/kikoe folder on your device (or the folder you pick on desktop: choose another folder, or hit Reset to go back to the default). Kikoe does not upload them anywhere.'),
    _Faq('Where are models stored and how big are they?',
        'Models live in the app\'s private storage (or %LOCALAPPDATA%\\kikoe\\models for the CLI). Sizes: tiny is about 75 MB and large-v3 is about 3.1 GB. Download once, use forever.'),
    _Faq('Which model should I pick?',
        'tiny-q5_1 or base-q5_1 for quick drafts and weaker hardware, small-q5_1 as the recommended default, medium or large-v3 for the best accuracy when you have the RAM and patience. Quantized q5 models are noticeably lighter with a small quality cost.'),
    _Faq('Which file formats are supported?',
        'Audio: WAV, MP3, M4A, FLAC, OGG, AAC, WMA, Opus. Video: MP4, MKV, MOV, WebM, AVI, 3GP. WAV and the platform codecs decode natively; the CLI decodes everything else through FFmpeg.'),
    _Faq('What output formats are available?',
        'TXT, SRT, VTT and JSON. The apps offer all four; the CLI takes a comma-separated list via --format.'),
    _Faq('Can I transcribe in Indonesian?',
        'Yes. Kikoe was built with Indonesian in mind. Pick id in the language dropdown, or leave it on auto and Kikoe will detect it. All Whisper languages are supported.'),
    _Faq('How do I get better accuracy?',
        'Use a larger model (small or medium), give it clean audio without heavy background noise, and pick the right language instead of auto when you know it. A quiet room beats any model upgrade.'),
    _Faq('Can I edit the transcript?',
        'Yes: the transcript is selectable text. Copy it anywhere and edit, or share the SRT/VTT/JSON and edit in a player like VLC.'),
    _Faq('Why does the app ask for notification permission?',
        'To show the progress of a long transcription in the notification shade, with a Cancel action. The transcription works without it; you are simply blind to progress.'),
    _Faq('Why does the app ask for storage permission?',
        'On Android 9 and below, to save transcripts into Downloads/kikoe. On Android 10+ saving uses the MediaStore and no storage permission is needed or requested.'),
    _Faq('The transcription progress bar says 0% for a long time?',
        'The first pass (decoding media) reports no percentage. Once Whisper starts, the bar moves. On very long files the decode can take tens of seconds; let it finish.'),
    _Faq('Something went wrong. How do I report it?',
        'Open a GitHub issue with the file type, the model, what you expected and what happened. For security issues, do not open a public issue: use the private reporting route in SECURITY.md.'),
    _Faq('Is Kikoe free for commercial use?',
        'Yes. Kikoe is MIT licensed. Use it at work, in your business, in your own products. Keep the copyright notice if you redistribute binaries.'),
    _Faq('How do I support the project?',
        'Star it on GitHub, and if Kikoe saved you hours, sponsor via GitHub Sponsors, Saweria, SociaBuzz or BagiBagi. Links are in About > Sponsor Kikoe.'),
    _Faq('What does Filter silence (VAD) do?',
        'It trims silent regions before transcription using the Silero VAD model (0.9 MB, downloaded once on first use). Results usually come out cleaner and faster on uneven audio with long pauses. Off by default.'),
    _Faq('Are my settings remembered?',
        'Yes. Your preferred model, language, translate and VAD toggles are restored on the next launch. Files and models stay on your device.'),
    _Faq('How do I check for updates?',
        'About > Version. Kikoe asks GitHub for the latest release and tells you whether you are up to date. Nothing is downloaded without you tapping a link.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: const Text('FAQ'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Answers to the questions that come up most often.',
                style: TextStyle(fontSize: 12, color: kDim)),
            const SizedBox(height: 12),
            for (final item in _items) ...[
              SectionCard(
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    expansionTileTheme: const ExpansionTileThemeData(
                      iconColor: kBrand,
                      collapsedIconColor: kDim,
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 4),
                    title: Text(
                      item.question,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kText,
                        height: 1.35,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.answer,
                          style: const TextStyle(fontSize: 12.5, height: 1.5, color: kDim),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            const Center(
              child: Text('Still stuck? Open a GitHub issue.',
                  style: TextStyle(fontSize: 11, color: kDim)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}
