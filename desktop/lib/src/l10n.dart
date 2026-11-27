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

  String t(String source) => _locale == 'id' ? (_id[source] ?? faqId[source] ?? source) : source;

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

const Map<String, String> faqId = {
    'History': 'Riwayat',
    'Licenses': 'Lisensi',
    'More': 'Lainnya',
    'Review transcript': 'Tinjau transkrip',
    'Sponsor': 'Sponsor',
    'Transcribe': 'Transkrip',
    'Command palette': 'Palet perintah',
    'Pick files': 'Pilih file',
    'Start transcription': 'Mulai transkripsi',
    'All speakers': 'Semua pembicara',
    'Choose file': 'Pilih file',
    'High': 'Tinggi',
    'Low': 'Rendah',
    'Medium': 'Sedang',
    'Only low confidence': 'Hanya keyakinan rendah',
    'Plain': 'Polos',
    'Result': 'Hasil',
    'Search transcript': 'Cari transkrip',
    'Segments': 'Segmen',
    'Settings': 'Setelan',
    'Speaker': 'Pembicara',
    'Step': 'Langkah',
    'Transcription finished': 'Transkripsi selesai',
    'Unknown': 'Tidak diketahui',
    'Word timestamps are off. Enable them for precise timing.': 'Timestamp kata nonaktif. Aktifkan untuk timing presisi.',
    'Words': 'Kata',
    'of': 'dari',
    'Clean repeated words': 'Bersihkan kata berulang',
    'Delete segment': 'Hapus segmen',
    'Merge with next': 'Gabung dengan berikutnya',
    'Prompt name': 'Nama prompt',
    'Save': 'Simpan',
    'Save prompt': 'Simpan prompt',
    'Saved prompts': 'Prompt tersimpan',
    'Split segment': 'Pisahkan segmen',
    'Detect speakers': 'Deteksi pembicara',
    'Label speaker changes (experimental)': 'Beri label perubahan pembicara (eksperimen)',
    'Precise timing for every word (slower)': 'Timing presisi untuk setiap kata (lebih lambat)',
    'Word timestamps': 'Timestamp kata',
    'No matches': 'Tidak ada hasil',
    'Search history': 'Cari riwayat',
    'A preset sets the model and VAD. Pick any model below to override.': 'Preset menentukan model dan VAD. Pilih model di bawah untuk menimpa.',
    'Accurate': 'Akurat',
    'Balanced': 'Seimbang',
    'Estimated finish': 'Perkiraan selesai',
    'Fast': 'Cepat',
    'Speed and quality': 'Kecepatan dan kualitas',
    'Apply': 'Terapkan',
    'Case sensitive': 'Bedakan huruf besar/kecil',
    'Editing replaces the saved text; timestamps change only when shifted.': 'Pengubahan mengganti teks tersimpan; timestamp hanya berubah saat digeser.',
    'Find': 'Cari',
    'Find and replace': 'Cari dan ganti',
    'Replace all': 'Ganti semua',
    'Replace with': 'Ganti dengan',
    'Shift timing (ms)': 'Geser timing (ms)',
    'Shifted by': 'Digeser sejauh',
    'segments changed': 'segmen diubah',
    'Delete imported model': 'Hapus model hasil impor',
    'Import a model…': 'Impor model…',
    'imported': 'diimpor',
    '聛こえ · offline audio & video transcription': '聛こえ · transkripsi audio & video offline',
    'About > Version. Kikoe asks GitHub for the latest release and tells you whether you are up to date. Nothing is downloaded without you tapping a link.': 'Tentang > Versi. Kikoe bertanya ke GitHub untuk rilis terbaru dan memberi tahu apakah kamu sudah terbaru. Tidak ada yang diunduh tanpa kamu mengetuk tautan.',
    'Are my settings remembered?': 'Apakah pengaturan saya tersimpan?',
    'Are there keyboard shortcuts?': 'Apakah ada pintasan keyboard?',
    'Audio: WAV, MP3, M4A, FLAC, OGG, AAC, WMA, Opus. Video: MP4, MKV, MOV, WebM, AVI, 3GP. WAV and the platform codecs decode natively; the CLI decodes everything else through FFmpeg.': 'Audio: WAV, MP3, M4A, FLAC, OGG, AAC, WMA, Opus. Video: MP4, MKV, MOV, WebM, AVI, 3GP. WAV dan codec platform didekode secara native; CLI mendekode sisanya lewat FFmpeg.',
    'Can I edit the transcript?': 'Bisakah saya mengubah transkrip?',
    'Can I fix transcription mistakes before saving?': 'Bisakah saya memperbaiki kesalahan transkripsi sebelum menyimpan?',
    'Can I transcribe in Indonesian?': 'Bisakah saya mentranskrip dalam Bahasa Indonesia?',
    'Do I need an account or a subscription?': 'Apakah saya perlu akun atau langganan?',
    'Does Kikoe need the internet?': 'Apakah Kikoe butuh internet?',
    'How do I check for updates?': 'Bagaimana cara memeriksa pembaruan?',
    'How do I get better accuracy?': 'Bagaimana cara mendapat akurasi lebih baik?',
    'How do I support the project?': 'Bagaimana cara mendukung proyek ini?',
    'Is Kikoe free for commercial use?': 'Apakah Kikoe gratis untuk penggunaan komersial?',
    'It biases the model toward your names, product and place names and spellings. Use it whenever you notice recurring mistakes (e.g. "Kikoe" being misheard). Built-in and persisted on both apps.': 'Fitur ini mengarahkan model ke nama, produk, tempat, dan ejaan milikmu. Gunakan bila kamu melihat kesalahan yang berulang (misalnya "Kikoe" salah dengar). Tersedia dan tersimpan di kedua aplikasi.',
    'It trims silent regions before transcription using the Silero VAD model (0.9 MB, downloaded once on first use). Results usually come out cleaner and faster on uneven audio with long pauses. Off by default.': 'Fitur ini memangkas bagian hening sebelum transkripsi memakai model Silero VAD (0,9 MB, diunduh sekali saat pemakaian pertama). Hasil biasanya lebih bersih dan cepat pada audio dengan jeda panjang. Nonaktif secara default.',
    'Kikoe (聞こえ) turns audio and video files into text and subtitles. It is a free, open source app built on whisper.cpp. Transcription runs entirely on your device; nothing is uploaded.': 'Kikoe (聞こえ) mengubah audio dan video menjadi teks dan subtitle. Aplikasi open source gratis yang dibangun dengan whisper.cpp. Transkripsi berjalan sepenuhnya di perangkatmu; tidak ada yang diunggah.',
    'Models live in the app\'s private storage (or %LOCALAPPDATA%\\kikoe\\models for the CLI). Sizes: tiny is about 75 MB and large-v3 is about 3.1 GB. Download once, use forever.': 'Model tersimpan di penyimpanan privat aplikasi (atau %LOCALAPPDATA%\\kikoe\\models untuk CLI). Ukuran: tiny sekitar 75 MB dan large-v3 sekitar 3,1 GB. Unduh sekali, pakai selamanya.',
    'No. Kikoe is free forever. No minutes quota, no subscription, no API key, no account. Open source under the MIT License.': 'Tidak. Kikoe gratis selamanya. Tanpa kuota menit, langganan, API key, atau akun. Open source dengan Lisensi MIT.',
    'On Android 9 and below, to save transcripts into Downloads/kikoe. On Android 10+ saving uses the MediaStore and no storage permission is needed or requested.': 'Di Android 9 dan bawahnya, untuk menyimpan transkrip ke Downloads/kikoe. Di Android 10+ penyimpanan memakai MediaStore dan izin penyimpanan tidak dibutuhkan atau diminta.',
    'Only twice, both times because you started them: downloading a Whisper model (once per model) and checking for updates in About. Transcription itself is fully offline, and the app works with airplane mode on.': 'Hanya dua kali, keduanya karena kamu memulainya: mengunduh model Whisper (sekali per model) dan memeriksa pembaruan di Tentang. Transkripsi sendiri sepenuhnya offline, dan aplikasi bekerja dengan mode pesawat aktif.',
    'Open a GitHub issue with the file type, the model, what you expected and what happened. For security issues, do not open a public issue: use the private reporting route in SECURITY.md.': 'Buka isu GitHub dengan jenis berkas, model, yang kamu harapkan, dan yang terjadi. Untuk masalah keamanan, jangan buka isu publik: gunakan jalur pelaporan privat di SECURITY.md.',
    'Something went wrong. How do I report it?': 'Ada yang salah. Bagaimana cara melaporkannya?',
    'Star it on GitHub, and if Kikoe saved you hours, sponsor via GitHub Sponsors, Saweria, SociaBuzz or BagiBagi. Links are in About > Sponsor Kikoe.': 'Beri bintang di GitHub, dan bila Kikoe menghemat waktu transkripmu, dukung lewat GitHub Sponsors, Saweria, SociaBuzz, atau BagiBagi. Tautannya ada di Tentang > Dukung Kikoe.',
    'TXT, SRT, VTT and JSON. The apps offer all four; the CLI takes a comma-separated list via --format.': 'TXT, SRT, VTT dan JSON. Aplikasi menyediakan keempatnya; CLI menerima daftar dipisah koma lewat --format.',
    'The first pass (decoding media) reports no percentage. Once Whisper starts, the bar moves. On very long files the decode can take tens of seconds; let it finish.': 'Tahap pertama (dekode media) tidak melaporkan persentase. Setelah Whisper mulai, bilah bergerak. Pada berkas sangat panjang, dekode bisa memakan puluhan detik; biarkan selesai.',
    'The history icon in the app bar lists your last 50 transcriptions, with playback metadata. Tap one to view, copy, or export it; tap delete to remove it.': 'Ikon riwayat di bilah aplikasi menampilkan 50 transkrip terakhir beserta metadata. Ketuk salah satu untuk melihat, menyalin, atau mengekspornya; ketuk hapus untuk menghapus.',
    'The transcription progress bar says 0% for a long time?': 'Bilah progres transkripsi menunjukkan 0% terlalu lama?',
    'To show the progress of a long transcription in the notification shade, with a Cancel action. The transcription works without it; you are simply blind to progress.': 'Untuk menampilkan progres transkripsi panjang di panel notifikasi, dengan tombol Batal. Transkripsi tetap bekerja tanpa izin ini; kamu hanya tidak melihat progresnya.',
    'Transcripts are saved into the Downloads/kikoe folder on your device (or the folder you pick on desktop: choose another folder, or hit Reset to go back to the default). Kikoe does not upload them anywhere.': 'Transkrip tersimpan di folder Downloads/kikoe di perangkatmu (atau folder yang kamu pilih di desktop: pilih folder lain, atau tekan Reset untuk kembali ke default). Kikoe tidak mengunggahnya ke mana pun.',
    'Use a larger model (small or medium), give it clean audio without heavy background noise, and pick the right language instead of auto when you know it. A quiet room beats any model upgrade.': 'Gunakan model lebih besar (small atau medium), berikan audio bersih tanpa kebisingan latar, dan pilih bahasa yang tepat daripada auto bila kamu mengetahui bahasanya. Ruangan tenang lebih efektif daripada upgrade model.',
    'What does Custom vocabulary do?': 'Apa fungsi Kosakata khusus?',
    'What does Filter silence (VAD) do?': 'Apa fungsi Saring keheningan (VAD)?',
    'What is Kikoe?': 'Apa itu Kikoe?',
    'What output formats are available?': 'Format keluaran apa yang tersedia?',
    'Where are models stored and how big are they?': 'Di mana model disimpan dan berapa ukurannya?',
    'Where are my transcripts saved?': 'Di mana transkrip saya disimpan?',
    'Where is my history?': 'Di mana riwayat saya?',
    'Which file formats are supported?': 'Format berkas apa yang didukung?',
    'Which model should I pick?': 'Model mana yang sebaiknya saya pilih?',
    'Why does the app ask for notification permission?': 'Mengapa aplikasi meminta izin notifikasi?',
    'Why does the app ask for storage permission?': 'Mengapa aplikasi meminta izin penyimpanan?',
    'Yes, desktop only: Ctrl+O picks files, Ctrl+Enter starts the queue, Esc cancels the running transcription.': 'Ya, khusus desktop: Ctrl+O memilih berkas, Ctrl+Enter memulai antrean, Esc membatalkan transkripsi yang berjalan.',
    'Yes. Kikoe is MIT licensed. Use it at work, in your business, in your own products. Keep the copyright notice if you redistribute binaries.': 'Ya. Kikoe berlisensi MIT. Gunakan di kantor, bisnis, atau produkmu sendiri. Sertakan pemberitahuan hak cipta bila mendistribusikan ulang biner.',
    'Yes. Kikoe was built with Indonesian in mind. Pick id in the language dropdown, or leave it on auto and Kikoe will detect it. All Whisper languages are supported.': 'Ya. Kikoe dibangun dengan mempertimbangkan Bahasa Indonesia. Pilih id di daftar bahasa, atau biarkan auto agar Kikoe mendeteksinya. Semua bahasa Whisper didukung.',
    'Yes. Tap the pencil icon on the transcript to open the editor. Each segment is a text field; timestamps stay untouched, so SRT and VTT exports stay valid.': 'Ya. Ketuk ikon pensil pada transkrip untuk membuka editor. Setiap segmen adalah bidang teks; timestamp tidak berubah, sehingga ekspor SRT dan VTT tetap valid.',
    'Yes. Your preferred model, language, translate and VAD toggles are restored on the next launch. Files and models stay on your device.': 'Ya. Model, bahasa, toggle terjemahan, dan VAD pilihanmu dipulihkan saat aplikasi dibuka lagi. Berkas dan model tetap di perangkatmu.',
    'Yes: the transcript is selectable text. Copy it anywhere and edit, or share the SRT/VTT/JSON and edit in a player like VLC.': 'Ya: transkrip adalah teks yang bisa dipilih. Salin ke mana saja dan ubah, atau bagikan SRT/VTT/JSON dan edit di pemutar seperti VLC.',
    'tiny-q5_1 or base-q5_1 for quick drafts and weaker hardware, small-q5_1 as the recommended default, medium or large-v3 for the best accuracy when you have the RAM and patience. Quantized q5 models are noticeably lighter with a small quality cost.': 'tiny-q5_1 atau base-q5_1 untuk draf cepat dan perangkat lemah, small-q5_1 sebagai default yang disarankan, medium atau large-v3 untuk akurasi terbaik bila RAM dan kesabaran cukup. Model kuantisasi q5 jauh lebih ringan dengan sedikit pengorbanan kualitas.',
    '100% offline · no telemetry': '100% offline · tanpa telemetri',
    'Drop audio or video files here': 'Lepaskan berkas audio atau video di sini',
    'Kikoe saves your transcripts into Downloads/kikoe so they are easy to find. ': 'Kikoe menyimpan transkripmu ke Downloads/kikoe agar mudah ditemukan. ',
    'Not downloaded yet. Kikoe needs the model file on this device once; after that, everything runs offline.': 'Belum diunduh. Kikoe perlu berkas model di perangkat ini sekali; setelah itu, semuanya berjalan offline.',
    'Or share a file to Kikoe from any app.\\nFree, unlimited, 100% offline.': 'Atau bagikan berkas ke Kikoe dari aplikasi lain.\\nGratis, tanpa batas, 100% offline.',
};

String tr(String source) => L10n.instance.t(source);
