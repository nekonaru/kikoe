# Changelog

Semua perubahan penting Kikoe didokumentasikan di sini. Formatnya mengikuti
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Kikoe memakai
semantic versioning; sampai v1.0, C API publik dan flag CLI bisa berubah antar
release.

## [Belum dirilis]

## [1.0.1] - 2026-11-15

### Keamanan

- **APK Android sekarang ditandatangani dengan release key Kikoe**, bukan
  debug key. CI menggagalkan build tagged bila secret tanda tangan tidak ada.
  Verifikasi sertifikat dengan sidik jari SHA-256:
  `06:87:03:24:C4:97:56:DE:7D:B3:B0:8D:A4:F2:31:55:44:42:12:6E:41:33:F9:23:56:EC:56:64:D5:CF:4B:9A`.
  Aplikasi yang terpasang dari v1.0.0 harus dicopot sebelum memasang v1.0.1,
  karena sertifikatnya berubah.
- **Unduhan model dan pemanggilan ffmpeg tidak lagi meneruskan karakter yang
  bisa ditafsirkan shell**; argumen diberi tanda kutip per platform dan
  apa pun yang tidak terduga gagal dengan aman (fail closed).
- **`android:allowBackup="false"` dan `usesCleartextTraffic="false"`**
  ditetapkan di manifest release, jadi transkrip dan model tidak ikut ke
  backup cloud dan cleartext traffic tidak pernah dicoba.
- **Versi konsisten**: tag, output `--version` CLI, versi proyek CMake dan
  versi aplikasi semuanya 1.0.1 (v1.0.0 mengirim biner yang melapor 0.1.0).

### Perbaikan

- Konsistensi string versi di seluruh C API, CLI, sistem build dan kedua
  aplikasi (lihat poin terakhir di Keamanan di atas).

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

