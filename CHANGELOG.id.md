# Changelog

Semua perubahan penting Kikoe didokumentasikan di sini. Formatnya mengikuti
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Belum dirilis

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
