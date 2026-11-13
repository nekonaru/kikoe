# Kikoe: PRD dan Master Prompt

Aplikasi transkripsi audio/video ke teks, gratis, tanpa batas pemakaian, jalan offline. Tersedia sebagai CLI, desktop, dan mobile dengan satu core C++.

Penulis: Niko (nekonaru) | Status: Draf v0.1 | Nama: Kikoe (nama repo: `kikoe`)

## Bagian 1: PRD

### 1. Ringkasan

Kikoe mengubah file audio atau video menjadi teks dan subtitle langsung di perangkat pengguna. Tidak ada server, akun, kuota, atau API key. Mesin pengenalan suara memakai whisper.cpp, dibungkus core C++ dengan C API sehingga CLI, desktop, dan mobile memakai logika yang sama.

Asal nama: "Kikoe" (聞こえ) berasal dari kata kerja Jepang kikoeru, yang berarti "terdengar" atau "dapat didengar". Cocok untuk aplikasi yang mengubah suara yang terdengar menjadi teks.

### 2. Masalah

- Layanan transkripsi populer membatasi menit gratis, meminta langganan, atau mengunggah audio ke cloud.
- Sebagian besar alat open source hanya berupa CLI atau skrip Python yang sulit dipakai orang non-teknis.
- Dukungan bahasa Indonesia sering jadi prioritas kedua di alat yang ada.

### 3. Tujuan

1. Transkripsi tanpa batas durasi dan jumlah file, gratis selamanya.
2. Privasi penuh: audio tidak pernah keluar dari perangkat.
3. Satu core, tiga bentuk: CLI, desktop, mobile.
4. Kualitas baik untuk bahasa Indonesia, dengan dukungan bahasa lain yang didukung model Whisper.
5. Mudah dipasang: satu installer atau satu binary per platform.

### 4. Bukan Tujuan (v1)

- Transkripsi real-time dari mikrofon (dipertimbangkan setelah v1).
- Diarisasi pembicara (siapa bicara apa).
- Fitur cloud, sinkronisasi akun, kolaborasi.
- Terjemahan teks ke bahasa lain (Whisper bisa menerjemahkan ke Inggris, jadikan opsi sederhana saja).
- Editor video.

### 5. Pengguna Sasaran

| Persona | Kebutuhan | Platform utama |
| --- | --- | --- |
| Mahasiswa | Mentranskrip rekaman kuliah dan wawancara | Desktop, mobile |
| Kreator konten | Subtitle SRT/VTT untuk video | Desktop, CLI |
| Jurnalis dan peneliti | Transkrip wawancara yang privat | Desktop |
| Developer | Otomasi batch lewat skrip | CLI |

### 6. Prinsip Produk

- Offline dulu: semua fitur inti jalan tanpa internet. Internet hanya dipakai untuk mengunduh model, dan itu opsional.
- Tanpa telemetri: tidak ada pengumpulan data apa pun.
- Sederhana di permukaan: pengguna awam cukup pilih file lalu klik mulai.
- Satu sumber kebenaran: semua logika inti ada di core, UI hanya lapisan tipis.

### 7. Kebutuhan Fungsional

Prioritas memakai MoSCoW: M = wajib v1, S = sebaiknya v1, C = bisa nanti.

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| FR-01 | Menerima input audio (wav, mp3, m4a, flac, ogg) dan video (mp4, mkv, mov, webm) | M |
| FR-02 | Dekode media ke PCM 16 kHz mono lewat FFmpeg | M |
| FR-03 | Transkripsi memakai whisper.cpp dengan pilihan model (tiny, base, small, medium, large) | M |
| FR-04 | Pilihan bahasa manual atau deteksi otomatis | M |
| FR-05 | Output TXT, SRT, VTT, JSON (dengan timestamp per segmen) | M |
| FR-06 | Progress dan pembatalan proses yang aman | M |
| FR-07 | Opsi jumlah thread | M |
| FR-08 | Batch banyak file dalam satu perintah atau satu antrean | S |
| FR-09 | Unduh model otomatis dengan verifikasi checksum, bisa dilanjutkan jika terputus | S |
| FR-10 | Akselerasi GPU opsional (Vulkan, Metal, CUDA) lewat flag build dan pilihan runtime | S |
| FR-11 | Pemotongan audio panjang menjadi potongan agar memori stabil | S |
| FR-12 | Terjemahan ke Inggris (task translate bawaan Whisper) | C |
| FR-13 | Kosakata kustom lewat initial prompt | C |
| FR-14 | Edit teks dan sinkron timestamp di UI | C |
| FR-15 | Transkripsi mikrofon real-time | C |

### 8. Kebutuhan Non-Fungsional

- Performa (target awal, diukur di akhir Tahap 1): model base pada CPU laptop menengah memproses audio minimal sekecil 1x kecepatan nyata (RTF ≤ 1.0).
- Memori: pemakaian puncak tidak melonjak seiring durasi file karena audio diproses per potongan.
- Stabilitas: file rusak atau format tidak didukung menghasilkan pesan galat jelas, bukan crash.
- Portabilitas: Windows, macOS, Linux untuk CLI dan desktop; Android untuk mobile. iOS dievaluasi kemudian.
- Privasi: nol permintaan jaringan selain unduh model yang diminta pengguna.
- Ukuran: binary CLI tanpa model sekecil mungkin; model dipisah dari installer.
- Lisensi: seluruh dependensi harus kompatibel dengan distribusi gratis dan open source (lihat bagian risiko tentang FFmpeg).

### 9. Arsitektur

```
kikoe/
├── core/              library C++ (static lib)
│   ├── include/       API publik (C API untuk FFI)
│   └── src/
│       ├── audio/     dekode media (FFmpeg) dan resampling
│       ├── engine/    pembungkus whisper.cpp
│       ├── format/    formatter TXT, SRT, VTT, JSON
│       └── model/     manajer model (unduh, verifikasi, cache)
├── cli/               executable CLI
├── desktop/           UI desktop (Flutter)
├── mobile/            UI mobile (Flutter + FFI)
├── third_party/       whisper.cpp (git submodule)
├── tests/             unit test dan audio sampel kecil
├── docs/
└── CMakeLists.txt
```

Alur data: file media → dekode (FFmpeg) → PCM 16 kHz mono → potongan → inferensi whisper.cpp → segmen bertimestamp → formatter → file keluaran.

Keputusan arsitektur:

- Core murni C++ tanpa dependensi UI. Semua komunikasi keluar lewat C API.
- Dekode dan inferensi dipisah di balik antarmuka internal, sehingga dekoder bisa diganti di mobile (misalnya decoder bawaan platform) tanpa menyentuh engine.
- Inferensi berjalan di thread kerja; progress dan segmen dikirim lewat callback.
- Flutter dipilih untuk desktop dan mobile agar satu basis kode UI, memanggil core lewat Dart FFI.

### 10. Kontrak C API (rancangan)

```c
typedef struct kk_engine kk_engine;

typedef struct {
  const char* model_path;
  int         n_threads;      // 0 = otomatis
  int         use_gpu;        // 0 atau 1
} kk_engine_params;

typedef struct {
  const char* language;       // "id", "en", atau "auto"
  int         translate;      // 0 atau 1
  const char* initial_prompt; // boleh NULL
} kk_options;

typedef struct {
  long long start_ms;
  long long end_ms;
  const char* text;           // UTF-8, dimiliki core selama callback
} kk_segment;

typedef void (*kk_progress_cb)(int percent, void* user);
typedef void (*kk_segment_cb)(const kk_segment* seg, void* user);

kk_engine* kk_engine_create(const kk_engine_params* p, int* err);
int        kk_transcribe(kk_engine* e, const char* media_path,
                         const kk_options* o,
                         kk_progress_cb on_progress,
                         kk_segment_cb on_segment, void* user);
void       kk_cancel(kk_engine* e);
int        kk_format_segments(/* segmen, format, buffer keluaran */);
const char* kk_error_string(int err);
void       kk_engine_free(kk_engine* e);
```

Aturan C API: tidak ada exception yang lolos melewati batas C, semua fungsi mengembalikan kode galat, kepemilikan memori didokumentasikan di header, dan versi API dicantumkan agar FFI tidak rusak diam-diam.

### 11. Pengalaman Pengguna per Platform

CLI:

```
kikoe input.mp4 --lang id --model small --format srt --threads 4 -o hasil.srt
kikoe *.mp3 --format txt,srt --outdir hasil/
kikoe --list-models
kikoe --download-model small
```

Desktop: seret dan lepas file, pilih bahasa dan model, tombol Mulai, progress bar, pratinjau teks yang muncul bertahap, tombol Simpan sebagai TXT/SRT/VTT/JSON, antrean untuk banyak file.

Mobile: pilih file dari penyimpanan atau bagikan dari aplikasi lain ke Kikoe, model kecil terkuantisasi, proses berjalan sebagai tugas latar dengan notifikasi progress, simpan atau bagikan hasil.

### 12. Strategi Model

- Model tidak dibundel di installer. Pengguna mengunduh sendiri, atau aplikasi menawarkan unduhan saat pertama kali jalan.
- Default CLI dan desktop: `small`. Default mobile: `base` atau `small` terkuantisasi, diputuskan setelah uji di perangkat nyata.
- Setiap model punya checksum yang diperiksa setelah unduh.
- Lokasi cache mengikuti konvensi platform dan bisa diubah lewat konfigurasi.

### 13. Roadmap dan Kriteria Selesai

| Tahap | Cakupan | Kriteria selesai |
| --- | --- | --- |
| 0. Fondasi | Repo, CMake, submodule whisper.cpp, CI build di tiga OS | Build hijau di Windows, macOS, Linux |
| 1. CLI minimal | Baca WAV 16 kHz, hasilkan teks | Audio sampel Indonesia menghasilkan teks terbaca |
| 2. Media apa pun | FFmpeg, SRT/VTT/JSON, opsi lang/model/threads | mp4 dan mp3 sampel menghasilkan SRT valid |
| 3. Kenyamanan | Progress, batch, unduh model, pembatalan, GPU opsional | Batch 10 file selesai, pembatalan tidak bocor memori |
| 4. C API stabil | Header publik, dokumentasi, test kontrak | Program C kecil memanggil core dengan benar |
| 5. Desktop | Flutter desktop via FFI | Alur seret-lepas sampai simpan berjalan di tiga OS |
| 6. Mobile | Build Android (NDK), model terkuantisasi, FFI | Transkripsi file 10 menit selesai di perangkat uji tanpa crash |
| 7. Rilis | Installer, README dwibahasa, SECURITY.md, lisensi | Rilis v1.0 publik di GitHub |

Estimasi kasar Tahap 1 sampai 3 adalah tiga minggu bila dikerjakan paruh waktu dengan bantuan AI. Tahap 5 dan 6 sebaiknya diestimasi ulang setelah core stabil.

### 14. Metrik Keberhasilan

Karena tidak ada telemetri, ukuran sukses bersifat terbuka dan manual:

- Real-time factor per model di perangkat acuan, dicatat di dokumen benchmark.
- WER pada kumpulan audio Indonesia kecil buatan sendiri, dibandingkan antar-model.
- Jumlah bintang, unduhan rilis, dan isu di GitHub.
- Jumlah format dan platform yang lolos uji manual per rilis.

### 15. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Lisensi FFmpeg: build GPL atau LGPL menentukan syarat distribusi | Hukum, distribusi | Pakai build LGPL dan tautan dinamis, catat di dokumen lisensi, periksa sebelum rilis |
| Mobile lambat atau kehabisan memori | Pengalaman buruk | Model kecil terkuantisasi, pemrosesan per potongan, batas ukuran model di UI |
| Akurasi bahasa Indonesia kurang pada audio berisik | Kepuasan pengguna | Saran model lebih besar, opsi initial prompt, dokumentasikan keterbatasan |
| Whisper berhalusinasi pada keheningan | Teks palsu | Aktifkan VAD atau filter keheningan, ambang no-speech |
| Fragmentasi GPU antar platform | Bug sulit dilacak | GPU opsional, CPU selalu jadi jalur utama yang diuji |
| Ruang lingkup membengkak | Proyek mandek | Kunci v1 pada kebutuhan M dan S, sisanya masuk daftar tunggu |
| Dekode di mobile berat dan besar | Ukuran aplikasi | Antarmuka dekoder terpisah agar bisa diganti decoder bawaan platform |

### 16. Lisensi dan Distribusi

whisper.cpp berlisensi MIT dan bobot model Whisper dirilis OpenAI dengan lisensi MIT. Lisensi proyek ini ditentukan pemilik repo; pilihan permisif (MIT atau Apache-2.0) paling sederhana selama dependensi kompatibel. Distribusi lewat GitHub Releases, dan APK untuk Android.

### 17. Pertanyaan Terbuka

1. Lisensi repo? (nama produk sudah final: Kikoe)
2. Apakah Flutter dipakai untuk desktop, atau Qt/Tauri dipertimbangkan?
3. Perangkat Android acuan untuk uji performa?
4. Perlu iOS di v1 atau cukup setelah v1?
5. Apakah transkripsi real-time masuk v1.1?

## Bagian 2: Master Prompt

Tempel prompt di bawah ke agen AI coding (misalnya OpenCode, Claude Code, atau sejenisnya) di root repo kosong. Prompt dibuat bertahap supaya agen tidak melompat ke semua fitur sekaligus.

```text
PERAN
Kamu adalah engineer senior C++ dan lintas-platform yang membantu saya membangun "Kikoe", aplikasi transkripsi audio/video ke teks yang gratis, tanpa batas, dan offline. Saya (Niko) mahasiswa bisnis digital yang suka vibe coding, jadi jelaskan keputusan penting dengan singkat dan bahasa yang mudah, tetapi jangan menyederhanakan kode.

KONTEKS PROYEK
- Mesin: whisper.cpp (git submodule di third_party/), core ditulis C++17 atau lebih baru.
- Core diekspos lewat C API (extern "C") supaya bisa dipanggil CLI, Flutter (Dart FFI), dan UI lain.
- Bentuk produk: CLI, desktop (Flutter), mobile Android (Flutter + FFI, build NDK).
- Dekode media memakai FFmpeg (LGPL, tautan dinamis) menjadi PCM 16 kHz mono float. Dekoder harus di balik antarmuka internal agar bisa diganti di mobile.
- Format keluaran: TXT, SRT, VTT, JSON, dengan formatter terpisah dari engine.
- Build sistem: CMake sejak awal, siap cross-compile ke Android.
- PROJECT_KIND = app. Jika ada rules.md dan guide.md di folder Dev Tools saya atau di repo, baca dulu dan ikuti; rules.md menang jika ada konflik. File itu lokal dan tidak boleh di-commit.

ATURAN KERAS
1. Offline dulu: tidak ada permintaan jaringan kecuali unduh model yang diminta pengguna. Tanpa telemetri, tanpa akun, tanpa API key.
2. Tidak ada exception yang boleh lolos melewati batas C API. Semua fungsi publik mengembalikan kode galat; kepemilikan memori didokumentasikan di header.
3. Core tidak boleh bergantung pada kode UI.
4. Jangan menambah dependensi tanpa menyebut alasan dan lisensinya. Dependensi harus kompatibel dengan distribusi open source gratis.
5. Jangan commit model, audio besar, rahasia, atau file lokal rules/guide.
6. Kode harus bisa dibuild di Windows, macOS, dan Linux; CPU selalu jalur utama, GPU hanya opsional lewat flag build.
7. Setiap tahap harus punya test dan lolos build sebelum lanjut ke tahap berikutnya.
8. Jangan mengerjakan tahap di luar yang sedang diminta.

CARA KERJA
- Mulai dengan menulis rencana singkat untuk tahap yang diminta (file apa yang dibuat, urutan, risiko), tunggu persetujuan saya, baru implementasi.
- Kerjakan per langkah kecil, jalankan build dan test setelah tiap langkah, laporkan hasil nyata (jangan mengklaim berhasil tanpa menjalankannya).
- Bagian inti pemanggilan whisper (inisialisasi konteks, parameter, loop segmen, callback) tulis dengan komentar yang menjelaskan alurnya, supaya saya bisa mempelajarinya.
- Jika ada keputusan yang mengubah arsitektur atau lisensi, berhenti dan tanyakan.
- Di akhir setiap tahap beri ringkasan: apa yang selesai, cara menjalankan, apa yang belum, dan saran tahap berikutnya.

STRUKTUR REPO
  kikoe/
    core/include, core/src/{audio,engine,format,model}
    cli/
    desktop/      (Tahap 5)
    mobile/       (Tahap 6)
    third_party/whisper.cpp
    tests/
    docs/
    CMakeLists.txt

C API (rancangan, boleh disempurnakan dengan alasan)
  kk_engine_create(params, &err), kk_transcribe(engine, media_path, options, on_progress, on_segment, user),
  kk_cancel(engine), kk_format_segments(...), kk_error_string(err), kk_engine_free(engine).
  Segmen: start_ms, end_ms, text UTF-8. Opsi: language ("id", "en", "auto"), translate, initial_prompt, n_threads, use_gpu.

TAHAP
0. Fondasi: struktur repo, CMake root, whisper.cpp sebagai submodule, .gitignore, CI build tiga OS, README awal.
1. CLI minimal: baca WAV 16 kHz mono, transkripsi dengan model base atau small, cetak teks ke terminal. Uji dengan audio Indonesia bersih.
2. Media apa pun: integrasi FFmpeg, formatter SRT/VTT/JSON/TXT, opsi --lang --model --format --threads -o.
3. Kenyamanan: progress, pembatalan aman, batch banyak file, unduh model dengan checksum dan resume, filter keheningan untuk mengurangi halusinasi, pemotongan audio panjang, GPU opsional (Vulkan/Metal/CUDA via flag).
4. C API stabil: header publik berversi, dokumentasi, test kontrak lewat program C kecil.
5. Desktop Flutter via Dart FFI: seret-lepas, antrean, progress, simpan hasil.
6. Mobile Android: build NDK, model terkuantisasi, tugas latar dengan notifikasi, bagikan dari aplikasi lain.
7. Rilis: installer, README dwibahasa, SECURITY.md, dokumen lisensi pihak ketiga, rilis v1.0.

DEFINISI SELESAI (per tahap)
- Build bersih di platform target tanpa peringatan penting.
- Test lulus, termasuk kasus galat (file hilang, format rusak, model tidak ada, pembatalan).
- Tidak ada kebocoran memori pada jalur normal dan jalur batal.
- Dokumentasi pemakaian diperbarui.

SEKARANG
Kerjakan hanya Tahap 0. Mulai dengan rencana singkat, lalu tanya jika ada hal yang belum jelas sebelum menulis kode.
```

### Cara memakai

1. Simpan Bagian 1 sebagai `docs/PRD.md` di repo agar agen bisa merujuknya.
2. Tempel Bagian 2 ke agen di repo kosong, mulai dari Tahap 0.
3. Setelah tiap tahap selesai, ganti baris "SEKARANG" menjadi tahap berikutnya (misalnya "Kerjakan hanya Tahap 1").
4. Jika keputusan di bagian pertanyaan terbuka sudah ada jawabannya, perbarui PRD dan baris konteks di master prompt.
