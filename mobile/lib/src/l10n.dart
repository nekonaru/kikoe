// Auto-generated from the English source strings. English is the source of
// truth; Indonesian is the translation. Missing keys fall back to English.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class L10n extends ChangeNotifier {
  L10n._();
  static final instance = L10n._();

  static const _prefKey = 'kikoe_ui_language';
  String _locale = 'en';
  String get locale => _locale;
  Locale get flutterLocale => Locale(_locale);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _locale = prefs.getString(_prefKey) == 'id' ? 'id' : 'en';
      notifyListeners();
    } catch (_) {
      _locale = 'en';
    }
  }

  Future<void> setLocale(String value) async {
    final next = value == 'id' ? 'id' : 'en';
    if (next == _locale) return;
    _locale = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, _locale);
    } catch (_) {}
    notifyListeners();
  }

  String t(String source) => _locale == 'id' ? (_id[source] ?? source) : source;

  static const Map<String, String> _id = {
    'About': 'Tentang',
    'All saved transcriptions will be deleted. Media files are untouched.': 'Semua transkrip tersimpan akan dihapus. Berkas media tidak tersentuh.',
    'Allow': 'Izinkan',
    'Answers to the questions that come up most often.': 'Jawaban atas pertanyaan yang paling sering muncul.',
    'Bundled Dart package licenses': 'Lisensi paket Dart yang disertakan',
    'Cancel': 'Batal',
    'Change': 'Ganti',
    'Clear history?': 'Hapus riwayat?',
    'Could not check. Check your connection.': 'Gagal memeriksa. Periksa koneksimu.',
    'Could not open the browser.': 'Gagal membuka browser.',
    'Delete all': 'Hapus semua',
    'Edit transcript': 'Ubah transkrip',
    'Editing replaces the saved text; timestamps never change.': 'Pengubahan mengganti teks tersimpan; timestamp tidak pernah berubah.',
    'Effective: v1.0.1 · applies to all Kikoe apps': 'Berlaku: v1.0.1 · untuk semua aplikasi Kikoe',
    'Every option opens in your browser. Kikoe never sees the transaction.': 'Setiap pilihan dibuka di browser. Kikoe tidak pernah melihat transaksinya.',
    'FAQ': 'Tanya Jawab',
    'Filter silence (VAD)': 'Saring keheningan (VAD)',
    'Finish file, tap Next': 'Selesaikan berkas, ketuk Berikutnya',
    'Full notices: THIRD_PARTY_NOTICES.md in the repository': 'Pemberitahuan lengkap: THIRD_PARTY_NOTICES.md di repositori',
    'It is built and maintained by one developer in spare time. If Kikoe saves you hours of transcription, a small tip keeps the project alive.': 'Dibangun dan dipelihara oleh satu pengembang di waktu luang. Jika Kikoe menghemat waktu transkripmu, sedikit dukungan menjaga proyek tetap hidup.',
    'Kikoe': 'Kikoe',
    'Kikoe is free, ad-free and open source.': 'Kikoe gratis, tanpa iklan, dan open source.',
    'Kikoe is open source. So is everything inside it.': 'Kikoe open source. Begitu juga semua isinya.',
    'Language': 'Bahasa',
    'Made with respect for your privacy.': 'Dibuat dengan menghormati privasimu.',
    'No data collection, no tracking, no account. Everything stays on your device.': 'Tidak ada pengumpulan data, pelacakan, atau akun. Semuanya tetap di perangkatmu.',
    'Not now': 'Nanti saja',
    'Nothing yet': 'Belum ada',
    'Open release': 'Buka rilis',
    'Open source licenses': 'Lisensi open source',
    'Or share a file to Kikoe from any app.\nFree, unlimited, 100% offline.': 'Atau bagikan berkas ke Kikoe dari aplikasi lain.\nGratis, tanpa batas, 100% offline.',
    'Pick an audio or video file': 'Pilih berkas audio atau video',
    'Privacy policy': 'Kebijakan privasi',
    'Recent transcriptions': 'Transkripsi terakhir',
    'SAVE': 'SIMPAN',
    'SRT goes to Downloads/kikoe when done': 'SRT tersimpan di Downloads/kikoe saat selesai',
    'Save automatically': 'Simpan otomatis',
    'Save transcripts to Downloads': 'Simpan transkrip ke Downloads',
    'Saves into Downloads/kikoe': 'Tersimpan di Downloads/kikoe',
    'Share': 'Bagikan',
    'Silero model (0.9 MB) downloads once': 'Model Silero (0,9 MB) diunduh sekali',
    'Skip silent regions with Silero VAD': 'Lewati bagian hening dengan Silero VAD',
    'Sponsor Kikoe': 'Dukung Kikoe',
    'Still stuck? Open a GitHub issue.': 'Masih buntu? Buka isu di GitHub.',
    'Transcript copied to clipboard': 'Transkrip disalin ke papan klip',
    'Translate to English': 'Terjemahkan ke Inggris',
    'You are on the latest version.': 'Kamu memakai versi terbaru.',
    'Your transcriptions will appear here.': 'Transkripsimu akan muncul di sini.',
    '聞こえ · offline': '聞こえ · offline',
  };
}

String tr(String source) => L10n.instance.t(source);
