# Changelog

Semua perubahan penting Kikoe didokumentasikan di sini. Formatnya mengikuti
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Belum dirilis

### Fitur baru

- **Layar About.** Identitas penulis, tautan profil GitHub, dan pemeriksaan pembaruan sekali ketuk terhadap rilis GitHub terbaru.
- **Layar Sponsor.** GitHub Sponsors, Saweria, SociaBuzz dan BagiBagi, satu ketukan masing-masing, dibuka di browser.
- **FAQ lengkap di dalam aplikasi.** 18 jawaban meliputi penyimpanan, model, format, akurasi, izin, pembaruan, lisensi dan dukungan.
- **Layar kebijakan privasi dan PRIVACY.md.** Kebijakannya ada di aplikasi dan di repositori.
- **Layar lisensi open source.** Teks MIT untuk Kikoe dan whisper.cpp, plus kredit untuk ggml, Flutter, FFmpeg dan bobot model Whisper.

### Peningkatan

- **Downloads/kikoe secara default.** Transkrip sekarang tersimpan ke Downloads/kikoe di Android dan desktop, bukan di sebelah file sumber. Desktop tetap punya opsi folder kustom; Reset kembali ke default.
- **Pemberitahuan penyimpanan pertama kali di Android.** Di Android 9 dan di bawahnya aplikasi meminta izin penyimpanan lama sekali saja; di Android 10+ penyimpanan memakai MediaStore dan tidak ada izin yang diminta.
- **UI dan UX diperbarui.** App bar baru dengan aksi FAQ dan About, kartu pemilih yang lebih kaya, section card yang konsisten, dan hub About (versi, sponsor, privasi, lisensi) di balik ikon info.
- **Decode Android lebih mulus.** Decoding media berjalan di thread latar, bukan thread UI, sehingga aplikasi tetap responsif untuk file panjang.
- **Aksi simpan di mobile.** Transkrip tersimpan langsung ke Downloads/kikoe; share tersedia sebagai aksi sekunder.
- **Log lebih senyap di release.** Logging debug hanya aktif di build debug.

## v1.0.1

Rilis keamanan: APK ditandatangani dengan release key, jalur unduhan yang fail-closed, manifest Android yang dikeraskan, dan string versi yang konsisten.

### Peningkatan

- **Tanda tangan rilis.** APK Android sekarang ditandatangani dengan release key Kikoe, bukan debug key, dan build tagged gagal bila secret tanda tangan tidak ada. Verifikasi sidik jari sertifikat di SECURITY.md.
- **Unduhan fail-closed.** Unduhan model dan pemanggilan ffmpeg tidak lagi meneruskan karakter yang bisa ditafsirkan shell; input yang tidak terduga menggagalkan proses alih-alih dijalankan.
- **Manifest dikeraskan.** Backup dan cleartext traffic sekarang dinonaktifkan secara eksplisit (`allowBackup="false"`, `usesCleartextTraffic="false"`).
- **Verifikasi unduhan.** CI memverifikasi tanda tangan setiap APK dengan `apksigner` sebelum diterbitkan.
- **Pembaruan dependensi.** Dependabot sekarang mengusulkan pembaruan mingguan untuk GitHub Actions, dependensi Dart dan Gradle.

### Perbaikan bug

- **Versi bergeser.** Tag, versi C API, banner `--help` CLI, versi proyek CMake dan kedua aplikasi semuanya melapor 1.0.1. Biner v1.0.0 melapor 0.1.0.

## v1.0.0

Rilis publik pertama: transkripsi audio dan video offline ke teks dan subtitle di Android, desktop Windows dan baris perintah.

### Fitur baru

- **Mesin transkrip.** whisper.cpp v1.9.5 lewat C API stabil berversi, dipakai oleh setiap permukaan.
- **CLI.** Transkripsikan file audio atau video apa pun ke TXT, SRT, VTT atau JSON. Mode batch, keluaran per file, filter keheningan Silero VAD, dan unduhan model terverifikasi dan bisa dilanjutkan (`kikoe --download-model`).
- **Aplikasi desktop Windows.** Antrean seret-lepas, ekspor TXT/SRT/VTT/JSON per file, folder keluaran kustom, manajemen model dengan verifikasi checksum.
- **Aplikasi Android.** Core yang sama lewat Dart FFI; transkripsi di perangkat dengan decoding MediaCodec (tanpa FFmpeg), bagikan ke Kikoe, notifikasi berjalan dengan progres.
- **Bundle desktop Windows.** `kikoe-windows-x64.zip`: `Kikoe.exe` plus `kikoe_ffi.dll`.
- **APK Android.** Split per ABI; zip CLI untuk Windows, macOS dan Linux.
- **Rilis dibangun CI.** Setiap artefak dibangun oleh CI dari commit tag; repo dipindai untuk mencari rahasia sebelum setiap push.
- **Kebijakan keamanan dan pemberitahuan.** SECURITY.md, pemberitahuan pihak ketiga, README dan changelog dwibahasa.
