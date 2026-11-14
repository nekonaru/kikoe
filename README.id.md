<p align="center">
  <img src="assets/brand/kikoe-tile.svg" alt="Ikon Kikoe" width="128" height="128">
</p>

# Kikoe

**Transkrip audio/video gratis, tanpa batas, 100% offline. Tanpa akun, tanpa kuota, tanpa cloud.**

Kikoe (聞こえ, dari kata kerja Jepang *kikoeru*, "terdengar") mengubah file
audio dan video menjadi teks dan subtitle langsung di perangkatmu. Mesin
utamanya [whisper.cpp](https://github.com/ggml-org/whisper.cpp), dibungkus
core C++ kecil, dengan CLI hari ini dan aplikasi desktop serta Android yang
direncanakan dari core yang sama.

> Status: masih pengembangan awal. Pipeline transkripsi dibangun bertahap,
> lihat [roadmap](#roadmap). Gunakan dengan sadar dan siap-siap ada perubahan
> yang memutus sampai v1.0.

## Kenapa

- **Gratis selamanya, tanpa batas.** Tidak ada batas menit, langganan, atau API key.
- **Privat.** Audio kamu tidak pernah keluar dari perangkat. Tanpa telemetri.
- **Dukungan Bahasa Indonesia lebih baik.** Diutak-atik dengan Bahasa
  Indonesia sebagai prioritas, plus bahasa lain yang didukung Whisper.
- **Mudah dipasang.** Satu binary atau satu installer per platform.

## Platform

| Platform | Status |
| --- | --- |
| CLI (Windows, macOS, Linux) | Dalam pengembangan (Tahap 1-3) |
| Desktop (Flutter) | Direncanakan (Tahap 5) |
| Android (Flutter + FFI) | Direncanakan (Tahap 6) |

## Syarat

- CMake 3.16 atau lebih baru
- Compiler C++17 (MSVC, GCC, atau Clang)
- git (build menarik whisper.cpp sebagai submodule)
- FFmpeg 6 atau lebih baru (hanya untuk decode media selain WAV)

Berkas model Whisper **tidak** dibundel. Kamu mengunduh model yang kamu mau
(lihat [strategi model](docs/PRD.md#12-strategi-model)); Internet hanya dipakai
untuk unduhan itu.

## Build dari source

```sh
git clone --recurse-submodules https://github.com/nekonaru/kikoe.git
cd kikoe
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest --test-dir build --output-on-failure
```

Di Windows dengan Visual Studio, tambahkan `-G "Visual Studio 17 2022"` jika
auto-deteksi gagal, dan pilih konfigurasi dengan `--config Release`.

## Pemakaian

CLI masih dalam pengembangan aktif. Target antarmukanya:

```sh
kikoe input.mp4 --lang id --model small --format srt --threads 4 -o hasil.srt
kikoe *.mp3 --format txt,srt --outdir hasil/
kikoe --list-models
kikoe --download-model small
```

Lihat `kikoe --help` setelah Tahap 2 selesai. Spesifikasi fungsional lengkap
dan kontrak C API ada di [PRD](docs/PRD.md).

## Roadmap

| Tahap | Cakupan | Status |
| --- | --- | --- |
| 0 | Fondasi: repo, CMake, submodule, CI | Selesai |
| 1 | CLI minimal: WAV 16 kHz, cetak teks | Selesai |
| 2 | Media apa pun: FFmpeg, TXT/SRT/VTT/JSON | Selesai |
| 3 | Kenyamanan: progress, batal, batch, manajer model | Selesai |
| 4 | C API stabil dengan header berversi | Selesai |
| 5 | Aplikasi desktop (Flutter) | Selesai |
| 6 | Aplikasi Android (Flutter + FFI) | Selesai |
| 7 | Rilis: installer, dokumen, v1.0 | Dalam proses |

## Privasi

Kikoe tidak melakukan permintaan jaringan apa pun kecuali unduhan model yang
kamu minta sendiri. Tidak ada telemetri, analitik, laporan crash, atau akun.
Cara melaporkan kerentanan ada di [SECURITY.md](SECURITY.md).

## Komponen pihak ketiga

- [whisper.cpp](https://github.com/ggml-org/whisper.cpp) (MIT), disertakan
  sebagai git submodule di `third_party/whisper.cpp`
- Bobot model [OpenAI Whisper](https://github.com/openai/whisper) (MIT),
  diunduh sesuai permintaan, tidak pernah dibundel
- FFmpeg (LGPL atau GPL tergantung build), dipakai sebagai program terpisah
  untuk decode media, tidak ditautkan ke Kikoe

Daftar lengkap dan teks lisensi ada di [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Lisensi

[MIT](LICENSE)

---

English: [README.md](README.md)
