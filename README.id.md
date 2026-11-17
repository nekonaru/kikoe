<div align="center">
  <img src="assets/brand/kikoe-tile.svg" alt="Logo Kikoe" width="120" />
  <h1>Kikoe: Transkripsi Audio/Video Offline</h1>
  <p><b>Transkripsikan audio dan video menjadi teks dan subtitle sepenuhnya di perangkatmu,<br/>
  dengan CLI, aplikasi desktop Windows dan aplikasi Android dari satu core C++.</b></p>

  <a href="https://github.com/nekonaru/kikoe/releases"><img src="https://img.shields.io/github/v/release/nekonaru/kikoe?style=flat-square&color=blue" alt="Release" /></a>
  <a href="https://github.com/nekonaru/kikoe/actions/workflows/ci.yml"><img src="https://github.com/nekonaru/kikoe/actions/workflows/ci.yml/badge.svg" alt="CI" /></a>
  <img src="https://img.shields.io/badge/Flutter-3.47.0-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter 3.47.0" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Desktop%20%7C%20CLI-3DDC84?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License: MIT" />
  <img src="https://img.shields.io/badge/Status-Active-brightgreen?style=flat-square" alt="Status: Active" />
</div>

<br />

[English](README.md) | **Bahasa Indonesia**

> [!NOTE]
> Kikoe tidak pernah mengirim audio kamu ke mana pun. Internet hanya dipakai saat kamu sendiri memulai unduhan model.

---

## Daftar Isi

- [Tentang](#tentang)
- [Fitur](#fitur)
- [Syarat](#syarat)
- [Instalasi](#instalasi)
- [Pemakaian](#pemakaian)
- [Struktur Proyek](#struktur-proyek)
- [Pengembangan](#pengembangan)
- [Pengujian](#pengujian)
- [Keamanan](#keamanan)
- [Integrasi Berkelanjutan](#integrasi-berkelanjutan)
- [FAQ](#faq)
- [Penulis](#penulis)
- [Lisensi](#lisensi)

---

## Tentang

**Kikoe** (聞こえ, dari bahasa Jepang *kikoeru*, "terdengar") mengubah file
audio dan video menjadi teks dan subtitle sepenuhnya di perangkatmu. Dibangun
di atas [whisper.cpp](https://github.com/ggml-org/whisper.cpp) dengan core C++
kecil ber-C API berversi, dipakai bersama oleh CLI, aplikasi desktop dan
aplikasi Android. Tanpa akun, tanpa kuota, tanpa cloud. Lihat
[docs/PRD.md](docs/PRD.md) untuk spesifikasi produk lengkap.

> _"Transkripsi gratis, tanpa batas, offline untuk semua."_

---

## Fitur

### Aplikasi Android

| Fitur | Deskripsi |
|-------|-----------|
| **Transkripsi di perangkat** | Core C++ yang sama lewat Dart FFI, decoding dengan MediaCodec, tanpa FFmpeg |
| **Filter keheningan (VAD)** | Silero VAD opsional memangkas bagian hening sebelum transkripsi |
| **Editor transkrip** | Perbaiki kesalahan sebelum simpan; timestamp SRT/VTT tetap valid |
| **Riwayat** | 50 transkripsi terakhir, tersimpan di perangkat, bisa dibuka/dibagikan lagi |
| **Custom vocabulary** | Glossari kata untuk nama produk/tempat, memperbaiki kata yang sering salah dengar |
| **Bagikan ke Kikoe** | Bagikan audio atau video dari aplikasi lain langsung ke Kikoe |
| **Notifikasi progres** | Notifikasi berjalan dengan progres selama proses berlangsung |
| **Manajemen model** | Unduh dan hapus model di dalam aplikasi; checksum diverifikasi setiap unduhan |

### Aplikasi desktop (Windows)

| Fitur | Deskripsi |
|-------|-----------|
| **Antrean seret-lepas** | Antrekan banyak file sekaligus, masing-masing dengan keluarannya sendiri |
| **Ekspor per file** | Ekspor TXT, SRT, VTT atau JSON per file |
| **Downloads/kikoe default** | Transkrip disimpan ke Downloads/kikoe secara default; pilih folder lain kapan pun, Reset kembali ke default |
| **Manajemen model** | Unduh dan verifikasi model di dalam aplikasi |
| **Editor transkrip** | Edit per segmen sebelum simpan; SRT/VTT tetap valid |
| **Riwayat** | 50 transkripsi terakhir di app, bisa diekspor dari sana |
| **Custom vocabulary** | Bantu model mengenali nama produk dan tempatmu |

### CLI

| Fitur | Deskripsi |
|-------|-----------|
| **Semua media** | WAV langsung; MP4, MKV, MP3, M4A, FLAC dan lainnya lewat FFmpeg |
| **Format keluaran** | TXT, SRT, VTT, JSON |
| **Mode batch** | Banyak file dengan keluaran per file (`--outdir`) |
| **Filter keheningan VAD** | Silero VAD opsional (`--vad`) |
| **Unduhan model terverifikasi** | SHA-256 diperiksa setiap unduhan, bisa dilanjutkan (`kikoe --download-model`) |
| **Seluruh set bahasa Whisper** | Setiap bahasa yang didukung Whisper, `--lang <kode>` atau `auto`, plus mode translate ke Inggris |
| **Pembatalan** | Ctrl+C membatalkan dengan bersih |

### Semua permukaan

| Fitur | Deskripsi |
|-------|-----------|
| **Gratis selamanya, tanpa batas** | Tanpa kuota menit, tanpa langganan, tanpa API key |
| **Privat** | Audio tidak pernah keluar dari perangkatmu, tanpa telemetri selamanya |
| **Bahasa Indonesia diutamakan** | Dirancang dengan Bahasa Indonesia di pikiran, plus semua bahasa Whisper |
| **Satu mesin** | Satu core C++ dengan C API berversi untuk setiap permukaan |

---

## Syarat

| Dependensi | Versi Minimum | Catatan |
|------------|---------------|---------|
| **CMake** | 3.16 | Membangun core dan CLI |
| **Kompiler C++17** | MSVC 2019+, GCC, atau Clang | Core dan CLI |
| **Git** | versi berapa pun yang terbaru | whisper.cpp adalah submodule |
| **FFmpeg** | 6 | Hanya CLI; diperlukan untuk decode media selain WAV |
| **Flutter** | 3.47.0 | Aplikasi desktop dan Android; tidak diperlukan untuk CLI |
| **JDK** | 17 | Hanya untuk build Android |
| **Android SDK** | API 37 (compile), API 24+ saat dijalankan | Hanya untuk build Android |
| **Android NDK** | 28.2.13676358 | Hanya untuk build Android |

> [!TIP]
> Kalau kamu hanya ingin memakai Kikoe, kamu tidak perlu Flutter, JDK, atau Android SDK. Unduh release dari halaman [Releases](https://github.com/nekonaru/kikoe/releases).

### Belum pernah pakai terminal? Mulai dari sini

<details>
<summary><b>Cara membuka terminal di Windows</b></summary>

1. Tekan tombol **Windows**, ketik `PowerShell`, lalu tekan **Enter**
2. Sebuah jendela terbuka. Di situlah kamu mengetik perintah
3. Setiap perintah `cmake`, `git`, `flutter` atau `kikoe` di panduan ini diketik di jendela itu, diikuti **Enter**

</details>

---

## Instalasi

### Opsi A: Unduh release (paling mudah)

1. Buka halaman [Releases](https://github.com/nekonaru/kikoe/releases)
2. Unduh file untuk platformmu:
   - `app-arm64-v8a-release.apk` untuk kebanyakan ponsel Android
   - `app-armeabi-v7a-release.apk` untuk perangkat Android 32-bit lawas
   - `app-x86_64-release.apk` untuk emulator x86_64
   - `kikoe-windows-x64.zip` untuk aplikasi desktop Windows
   - `kikoe-cli-windows-latest.zip` (Windows), `kikoe-cli-macos-latest.zip` (macOS) atau `kikoe-cli-ubuntu-latest.zip` (Linux) untuk CLI
3. Android: buka APK di ponselmu, izinkan instal dari sumber tidak dikenal bila diminta. Verifikasi sidik jari sertifikat di [SECURITY.md](SECURITY.md) sebelum memasang
4. Aplikasi desktop Windows: ekstrak zip-nya lalu jalankan `Kikoe.exe`
5. CLI: letakkan binarinya di PATH lalu jalankan `kikoe --help`

> [!IMPORTANT]
> Android memerlukan izin "Install unknown apps" untuk aplikasi yang kamu pakai memasang (browser atau file manager), dan izin notifikasi agar notifikasi progres bisa muncul. Tidak ada yang lain. Aplikasi desktop belum ditandatangani, jadi Windows SmartScreen akan memperingatkan saat pertama kali dijalankan; lihat FAQ.

### Opsi B: Build dari source (untuk pengembangan)

#### 1. Ambil kode proyek

<details>
<summary><b>Saya sudah punya Git</b></summary>

```bash
git clone --recurse-submodules https://github.com/nekonaru/kikoe.git
cd kikoe
```

</details>

<details>
<summary><b>Saya belum punya Git</b></summary>

1. Buka halaman repositori di GitHub
2. Klik tombol hijau **`Code`**, pilih **`Download ZIP`**
3. Ekstrak ZIP-nya ke folder pilihanmu, lalu di terminal:

```bash
cd kikoe-main
```

Catatan: ZIP tidak menyertakan submodule whisper.cpp. Membangun CLI dari ZIP
juga membutuhkan `third_party/whisper.cpp` pada tag yang disematkan; memakai
Git dengan `--recurse-submodules` adalah jalan yang sederhana.

</details>

#### 2. Build dan uji CLI

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build -C Release --output-on-failure
```

> [!IMPORTANT]
> `ctest` harus melaporkan **100% tests passed**.

#### 3. Build aplikasi

```bash
# Aplikasi desktop Windows
cd desktop
flutter pub get
flutter build windows --release

# Aplikasi Android (membutuhkan JDK 17, Android SDK 37, NDK 28.2.13676358)
cd mobile
flutter pub get
flutter build apk --release --split-per-abi
```

---

## Pemakaian

### Pertama kali

1. Unduh satu model (cukup sekali, butuh internet):

   ```bash
   kikoe --download-model tiny
   ```

2. Transkripsikan sesuatu:

   ```bash
   kikoe input.mp4 --lang id --format srt -o hasil.srt
   ```

3. Di aplikasi, ketuk kartu **Pick an audio or video file** (atau lepas file ke jendela desktop) dan tunggu transkripnya muncul

> [!NOTE]
> Model Whisper adalah file besar yang diunduh sekali dan disimpan di cache lokal. `kikoe --list-models` menampilkan apa yang tersedia dan apa yang sudah terunduh.

### Pemakaian sehari-hari

- `kikoe --format txt,srt,vtt,json input.mp4` untuk beberapa format sekaligus
- `kikoe *.mp3 --outdir transcripts/` untuk batch
- `kikoe --vad input.mp4` untuk melewati keheningan
- `kikoe --lang auto input.mp4` untuk deteksi bahasa otomatis
- Desktop: simpan TXT/SRT/VTT/JSON per file; transkrip tersimpan di Downloads/kikoe secara default (ubah di sidebar)
- Android: file tersimpan ke Downloads/kikoe; bagikan video dari galeri ke Kikoe

---

## Struktur Proyek

```
kikoe/
├── assets/brand/            # aset logo dan ikon
├── cli/                     # alat baris perintah kikoe
├── core/                    # core transkripsi C++17
│   ├── include/kikoe.h      # C API berversi
│   └── src/                 # engine, decoder, manajer model, formatter
├── desktop/                 # aplikasi desktop Windows (Flutter)
├── mobile/                  # aplikasi Android (Flutter + Dart FFI, Kotlin MediaCodec)
├── scripts/                 # pembuat catatan rilis
├── tests/                   # suite ctest (formatter, kontrak C API)
├── third_party/whisper.cpp  # git submodule (v1.9.5)
├── .github/workflows/ci.yml # build, test, kemas, rilis, pemindaian rahasia
├── CMakeLists.txt           # build core dan CLI
├── LICENSE                  # MIT
├── README.md                # dokumentasi (Inggris)
└── README.id.md             # dokumentasi (Bahasa Indonesia)
```

---

## Pengembangan

### Mengubah core atau CLI

1. Ubah kode di bawah `core/` atau `cli/`
2. Build ulang: `cmake --build build --config Release`
3. Jalankan tes: `ctest --test-dir build -C Release --output-on-failure`

### Mengubah aplikasi desktop atau Android

1. Ubah kode di bawah `desktop/` atau `mobile/`
2. `flutter pub get && flutter analyze && flutter test` di folder tersebut
3. Jika kamu mengubah C API, naikkan `kk_abi_version()` di `core/include/kikoe.h`
   dan periksa probe FFI:

```bat
cd desktop
set KIKOE_FFI_DLL=..\..\build\Release\kikoe_ffi.dll
set KIKOE_MODEL=%LOCALAPPDATA%\kikoe\models\ggml-tiny.bin
set KIKOE_MEDIA=..\third_party\whisper.cpp\samples\jfk.wav
dart run tool\probe_ffi.dart
```

### Menambahkan model ke registry

1. Tambahkan entrinya (nama, nama file, URL, ukuran, SHA-256) ke `core/src/model/model_registry.cpp`
2. Tambahkan entri yang sama ke `mobile/lib/src/model_menu.dart`
3. Hitung ulang ukuran dan SHA-256 dari file yang diterbitkan; jangan menebak

---

## Pengujian

Verifikasi sebelum setiap push, semuanya harus bersih:

```bash
ctest --test-dir build -C Release --output-on-failure
cd desktop && flutter analyze && flutter test
cd mobile && flutter analyze && flutter test
```

| Periksa | Syarat |
|-------|--------|
| `ctest --test-dir build -C Release` | Harus melaporkan 100% tests passed |
| `flutter analyze` (kedua aplikasi) | Harus melaporkan No issues found |
| `flutter test` (kedua aplikasi) | Harus lolos seluruh suite |

Lint dipaksa lewat `analysis_options.yaml` di masing-masing aplikasi (flutter_lints).
CI menjalankan pemeriksaan yang sama di Windows, macOS dan Linux pada setiap push dan pull request.

---

## Keamanan

Kikoe adalah aplikasi sepenuhnya offline tanpa backend, tanpa akun dan tanpa
pembelian. Satu-satunya permintaan jaringan adalah yang kamu mulai sendiri:
unduhan model dari hub model whisper.cpp publik (diverifikasi dengan SHA-256
setiap unduhan) dan pemeriksaan pembaruan di About. APK release ditandatangani
dengan release key Kikoe dan sidik jari sertifikatnya diterbitkan di
[SECURITY.md](SECURITY.md). Release dibangun dari commit yang ditag dan
repositori dipindai untuk mencari rahasia sebelum setiap push. Manifest
release Android menonaktifkan backup dan cleartext traffic.

> [!NOTE]
> Lihat [SECURITY.md](SECURITY.md) untuk kebijakan keamanan lengkap dan cara melaporkan kerentanan secara privat, dan [PRIVACY.md](PRIVACY.md) untuk kebijakan privasi.

---

## Integrasi Berkelanjutan

| Workflow | Fungsi |
|----------|--------|
| `ci.yml` (Build and test) | Build core dan ctest di Windows, macOS, Linux; zip CLI per OS |
| `ci.yml` (Build desktop) | Bundle desktop Windows `kikoe-windows-x64.zip` |
| `ci.yml` (Build Android APK) | APK release, ditandatangani, split per ABI |
| `ci.yml` (Release artifacts) | Pada tag `v*`, membuat GitHub Release dengan semua artefak |
| `ci.yml` (Secret scan) | gitleaks pada setiap push dan pull request |

Dependensi diperbarui setiap minggu oleh Dependabot. Jalur instalasi di catatan rilis selalu cocok dengan Opsi A di atas.

---

## FAQ

<details>
<summary><b>Apakah Kikoe butuh internet?</b></summary>

Hanya untuk mengunduh model whisper, dan hanya saat kamu memintanya. Transkripsi tidak pernah memakai jaringan.

</details>

<details>
<summary><b>APK mana yang harus saya pasang?</b></summary>

`app-arm64-v8a-release.apk` untuk hampir semua ponsel dalam satu dekade terakhir. Gunakan `app-armeabi-v7a-release.apk` hanya untuk perangkat 32-bit lawas, dan `app-x86_64-release.apk` untuk emulator x86_64.

</details>

<details>
<summary><b>Android bilang aplikasi yang terpasang berkonflik saat saya memasang v1.0.1?</b></summary>

Sertifikat tanda tangan berubah di v1.0.1. Copot aplikasi yang terpasang dari v1.0.0, lalu pasang v1.0.1. Model dan transkrip kamu tersimpan di penyimpananmu sendiri atau di folder privat aplikasi; model bisa diunduh ulang.

</details>

<details>
<summary><b>Kenapa Windows bilang aplikasi belum diverifikasi?</b></summary>

Bundle desktop tidak ditandatangani, jadi SmartScreen memperingatkan saat pertama kali dijalankan. Artefak dibangun oleh CI dari commit tag publik; verifikasi unduhanmu ke [SECURITY.md](SECURITY.md) dan checksum release.

</details>

<details>
<summary><b>File video saya tidak bisa di-decode?</b></summary>

Pasang FFmpeg 6 atau lebih baru dan pastikan `ffmpeg` ada di PATH untuk CLI. Aplikasi Android decode dengan MediaCodec dan tidak butuh FFmpeg; keluarkan dulu konten yang dilindungi DRM.

</details>

<details>
<summary><b>Di mana model disimpan dan berapa ukurannya?</b></summary>

Di cache lokal (`%LOCALAPPDATA%\kikoe\models` di Windows, `~/.cache/kikoe/models` di Linux, `~/Library/Caches/kikoe/models` di macOS). Kira-kira 75 MB untuk `tiny` sampai sekitar 3.1 GB untuk `large-v3`. Tidak ada yang dibundel dengan aplikasi.

</details>

<details>
<summary><b>Di mana transkrip saya disimpan?</b></summary>

Ke folder Downloads/kikoe di perangkatmu, secara default. Aplikasi desktop bisa menulis ke folder mana pun (Choose… di sidebar); tekan Reset untuk kembali ke default. Kikoe tidak pernah mengunggah transkrip.

</details>

<details>
<summary><b>Bagaimana cara mendukung Kikoe?</b></summary>

Beri bintang di GitHub, atau sponsor lewat GitHub Sponsors, Saweria, SociaBuzz atau BagiBagi. Tautannya ada di About (ikon info) di kedua aplikasi: About > Sponsor Kikoe.

</details>

---

<details>
<summary><b>Bisakah saya memperbaiki transkrip setelah selesai?</b></summary>

Bisa. Ketuk ikon pensil di header transkrip. Setiap segmen menjadi bidang teks; menyimpan mengganti teks sementara timestamp SRT/VTT tetap utuh.

</details>

<details>
<summary><b>Di mana transkripsi saya yang lalu?</b></summary>

Ikon riwayat (jam) di app bar menampilkan 50 transkripsi terakhir. Ketuk mana saja untuk melihat, menyalin atau mengekspornya; ketuk X untuk menghapus.

</details>

## Penulis

<div align="center">

| [![Nicolas Dwi Dharma](https://github.com/nekonaru.png?size=100)](https://github.com/nekonaru) |
|:---:|
| **Nicolas Dwi Dharma** |
| [github.com/nekonaru](https://github.com/nekonaru) |

</div>

---

## Lisensi

Didistribusikan di bawah **MIT License**. Lihat [`LICENSE`](LICENSE) untuk detailnya.
