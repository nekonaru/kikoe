# Changelog

Semua perubahan penting Kikoe didokumentasikan di sini. Formatnya mengikuti
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Kikoe memakai
semantic versioning; sampai v1.0, C API publik dan flag CLI bisa berubah antar
release.

## [Belum dirilis]

## [1.0.0] - 2026-11-14

### Ditambahkan

- Mesin transkrip berbasis whisper.cpp v1.9.5, lewat C API stabil berversi,
  dipakai oleh setiap permukaan produk di bawah ini.
- **CLI**: transkrip file audio atau video apa pun ke TXT, SRT, VTT atau JSON.
  Mode batch, keluaran per file, filter keheningan Silero VAD, dan manajer
  unduhan model yang diverifikasi checksum dan bisa dilanjutkan
  (`kikoe --download-model`).
- **Aplikasi desktop** (Windows, macOS, Linux): antrean seret-lepas, pratinjau
  langsung, ekspor TXT/SRT/VTT/JSON per file, manajemen model dengan verifikasi
  checksum.
- **Aplikasi Android**: core yang sama lewat Dart FFI; transkrip di perangkat
  dengan decoding MediaCodec (tanpa FFmpeg), bagikan ke Kikoe, notifikasi
  progres berjalan.
- **Bundle desktop** (`kikoe-windows-x64`): `Kikoe.exe` plus `kikoe_ffi.dll`.
- **APK Android** (`kikoe-android-apks`), per ABI.
- CI membangun semua artifact di Windows, macOS dan Linux.
- Kebijakan keamanan, pemberitahuan pihak ketiga, README dan changelog dwibahasa.

### Keamanan

- Semua build yang diterbitkan menjaga audio di perangkat. Satu-satunya
  permintaan jaringan adalah unduhan model yang diminta pengguna, diverifikasi
  dengan SHA-256.

