// About screen: who made Kikoe, with update check and links to the rest of
// the app's information surfaces.
library;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'kikoe_theme.dart';
import 'licenses_screen.dart';
import 'privacy_screen.dart';
import 'sponsor_screen.dart';
import 'faq_screen.dart';
import 'update_checker.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '…';
  bool _checking = false;
  UpdateCheckResult? _result;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() {
        _version = 'v${info.version} (build ${info.buildNumber})';
      });
    });
  }

  Future<void> _checkUpdates() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _result = null;
    });
    final info = await PackageInfo.fromPlatform();
    final result = await UpdateChecker.instance.check(info.version);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: const Text('About'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const SizedBox(height: 6),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('assets/icon.png', width: 88, height: 88),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text('Kikoe',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: kText, letterSpacing: 0.3)),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text('聞こえ · offline audio & video transcription',
                  style: TextStyle(fontSize: 12, color: kDim)),
            ),
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                children: [
                  LinkTile(
                    icon: Icons.fingerprint,
                    title: 'Version',
                    subtitle: _version,
                    onTap: _checkUpdates,
                    trailing: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: kBrand),
                          )
                        : const Icon(Icons.refresh, color: kDim, size: 20),
                  ),
                  if (_result != null) ...[
                    const SoftDivider(),
                    _UpdateResultBanner(
                      result: _result!,
                      onOpenRelease: () => _open(UpdateChecker.releasesUrl),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Built by'),
            SectionCard(
              child: Column(
                children: [
                  LinkTile(
                    icon: Icons.person_outline,
                    title: 'Nicolas Dwi Dharma',
                    subtitle: 'Creator and maintainer · @nekonaru on GitHub',
                    onTap: () => _open('https://github.com/nekonaru'),
                    trailing: const Icon(Icons.open_in_new, color: kDim, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('Support'),
            SectionCard(
              child: Column(
                children: [
                  LinkTile(
                    icon: Icons.volunteer_activism_outlined,
                    title: 'Sponsor Kikoe',
                    subtitle: 'Keep Kikoe free and ad-free',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SponsorScreen()),
                    ),
                  ),
                  const SoftDivider(),
                  LinkTile(
                    icon: Icons.star_border,
                    title: 'Star on GitHub',
                    subtitle: 'github.com/nekonaru/kikoe',
                    onTap: () => _open('https://github.com/nekonaru/kikoe'),
                    trailing: const Icon(Icons.open_in_new, color: kDim, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionLabel('App information'),
            SectionCard(
              child: Column(
                children: [
                  LinkTile(
                    icon: Icons.help_outline,
                    title: 'FAQ',
                    subtitle: 'Common questions, answered',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    ),
                  ),
                  const SoftDivider(),
                  LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy policy',
                    subtitle: 'What Kikoe does and does not collect',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                    ),
                  ),
                  const SoftDivider(),
                  LinkTile(
                    icon: Icons.description_outlined,
                    title: 'Open source licenses',
                    subtitle: 'MIT · whisper.cpp · third-party notices',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LicensesScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Center(
              child: Text('Made with respect for your privacy.',
                  style: TextStyle(fontSize: 11, color: kDim)),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateResultBanner extends StatelessWidget {
  const _UpdateResultBanner({required this.result, required this.onOpenRelease});

  final UpdateCheckResult result;
  final VoidCallback onOpenRelease;

  @override
  Widget build(BuildContext context) {
    switch (result.status) {
      case UpdateStatus.upToDate:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: kOk, size: 20),
              SizedBox(width: 10),
              Text('You are on the latest version.',
                  style: TextStyle(fontSize: 13, color: kText)),
            ],
          ),
        );
      case UpdateStatus.updateAvailable:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.system_update_alt, color: kBrand, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('v${result.latestVersion} is available.',
                    style: const TextStyle(fontSize: 13, color: kText)),
              ),
              TextButton(onPressed: onOpenRelease, child: const Text('Open release')),
            ],
          ),
        );
      case UpdateStatus.failed:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: kBrand, size: 20),
              SizedBox(width: 10),
              Text('Could not check. Check your connection.',
                  style: TextStyle(fontSize: 13, color: kText)),
            ],
          ),
        );
    }
  }
}
