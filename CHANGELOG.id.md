# Changelog

Semua perubahan penting Kikoe didokumentasikan di sini. Formatnya mengikuti
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Belum dirilis

## v4.0.0

Desain dan interaksi menyeluruh. Ini gelombang terakhir dari program desain v3 yang dikirim dalam satu rilis.

### Fitur baru

- **Layar tinjau.** Tab Plain, Segmen, dan Kata untuk setiap transkrip selesai. Segmen menampilkan kategori keyakinan dan chip pembicara; filter mencakup pencarian teks, hanya keyakinan rendah, dan pembicara. Tampilan Kata memakai timing kata yang sudah dikumpulkan engine.
- **Alur tiga langkah.** Kedua aplikasi menampilkan `Pilih file`, `Setelan`, dan `Hasil` agar tahap saat ini jelas.
- **Navigasi bawah mobile.** Transcribe, History, dan More. More mengumpulkan FAQ, Tentang, Sponsor, Privasi, dan Lisensi dalam satu daftar yang konsisten.
- **Palet perintah desktop.** Ctrl+K atau Cmd+K membuka pilih file, mulai, batal, dan riwayat.
- **Sistem gerak.** Transisi fade dan scale yang bermakna dengan durasi masuk dan keluar terpisah, plus jalur reduced motion yang melewati animasi sama sekali.

### Peningkatan

- **Token desain tiga lapis.** Warna primitive, spacing, radius, dan gerak memberi peran semantik dan konstanta komponen. Mobile dan desktop memakai satu definisi.
- **Kontras dan tipografi.** Warna isi tombol dan akses dipisahkan sehingga teks putih di tombol mencapai 4,5:1. Teks caption naik dari 10,5 menjadi 12 px.
- **Aksesibilitas.** Tombol ikon punya label semantik, perubahan tahap diumumkan ke pembaca layar, dan `LinkTile` membuka label tombol.
- **Logika tinjau adalah helper murni** dengan tes unit di kedua aplikasi. Rangkaian Android kini 32 tes, desktop 24.

## v3.1.0

Gelombang terakhir program v3, berfokus pada alur kerja CLI.

### Fitur baru

- **Dry run.** `--dry-run` mendekode input dan melaporkan durasi audio, model yang dipilih, dan format keluaran tanpa melakukan transkripsi. Fitur ini menyatakan bahwa waktu bergantung pada perangkat dan model, bukan membuat perkiraan rekaan.
- **Output benchmark.** `--benchmark` mencetak waktu tempuh yang benar-benar terukur untuk tiap transkripsi di mesin saat ini.
- **Mode watch.** `--watch DIR` memeriksa direktori tiap dua detik dan mentranskrip file baru setelah ukurannya stabil. Ctrl+C menghentikan pemantauan.

### Peningkatan

- **Pemrosesan per file dipisahkan** dari loop utama CLI, sehingga mode batch dan watch memakai jalur yang sama dan tidak bisa berbeda perilaku.
- **Pembatalan di mode watch** memakai flag atomik eksplisit, bukan tebakan dari nilai progres.
- **Interaksi flash attention dan DTW didokumentasikan.** whisper.cpp mematikan DTW saat flash attention aktif tetapi tetap memberikan timing token yang dipakai untuk cue kata.

## v3.0.0

Rilis Kikoe terbesar sejauh ini. Timing per kata, deteksi pembicara, operasi editor, prompt tersimpan, dan konfigurasi CLI hadir bersamaan. Tidak ada model yang dihapus.

### Fitur baru

- **Timestamp per kata.** Kedua aplikasi dan CLI bisa mengumpulkan timing setiap kata. Ekspor SRT dan VTT memakai cue per kata saat fitur ini aktif. Flag CLI adalah `--word-timestamps`.
- **Deteksi pembicara.** Tinydiarize memberi label giliran bicara sebagai `SPEAKER_00`, `SPEAKER_01`, dan seterusnya. Kedua aplikasi punya toggle; CLI memakai `--diarize`.
- **Operasi editor.** Pisahkan segmen di tengah, gabungkan dengan segmen berikutnya, hapus segmen, dan bersihkan kata berulang yang kadang dihasilkan Whisper. Semua operasi berupa helper murni dengan tes unit.
- **Pustaka prompt.** Simpan kosakata khusus dengan nama, berpindah antarpreset, dan hapus preset. Prompt tersimpan secara lokal.
- **File konfigurasi CLI.** `kikoe.toml` menyediakan nilai awal untuk model, bahasa, kualitas, VAD, prompt, format, dan thread. Flag eksplisit tetap menimpa. Gunakan `--config FILE` untuk path lain.
- **File prompt CLI.** `--prompt-file FILE` membaca prompt awal multi-baris dari disk.
- **Aksesor C API.** `kk_last_segment_confidence`, `kk_last_segment_speaker`, `kk_last_word_count`, dan `kk_last_word_get` membuka data baru. Versi minor ABI menjadi 5.

### Peningkatan

- **Flash attention dan prompt terbawa** dari v2.4.0 tetap aktif.
- **Confidence diukur**, bukan ditebak: nilainya adalah rata-rata probabilitas token dari whisper.cpp.
- **Rangkaian Android kini 29 tes, desktop 21**, termasuk cakupan baru untuk split, merge, pembersihan, dan penghapusan kata berulang.

## v2.5.0

Rilis hasil audit runtime. Dua anomali progres diperbaiki dan riwayat kini bisa dicari.

### Fitur baru

- **Cari riwayat.** Kedua aplikasi menyaring transkripsi tersimpan berdasarkan nama file atau isi transkrip, tanpa membedakan huruf besar/kecil. Query kosong menampilkan semua; query tanpa hasil menampilkan kondisi kosong yang jelas.

### Perbaikan bug

- **Perkiraan selesai tidak lagi menghitung waktu dekoding media.** Jam kini dimulai pada persentase transkripsi pertama yang nyata. Dekoder tidak melaporkan persentase, sehingga memasukkannya melebih-lebihkan estimasi pada video panjang.
- **Engine yang dipakai ulang tidak bisa menampilkan 100 persen lama.** Nilai progres di luar tahap transkripsi diabaikan di kedua aplikasi, dan desktop menunggu persentase nyata pertama sebelum menyalakan jam.

### Peningkatan

- **`historyMatches` adalah helper murni** dengan tes unit di kedua aplikasi. Rangkaian Android kini 23 tes, desktop 15.

## v2.4.0

Rilis kecepatan dan akurasi. Transkripsi kini bisa diatur dari UI, dan progres langsung disertai perkiraan selesai yang diukur.

### Fitur baru

- **Preset kecepatan dan kualitas.** Kedua aplikasi menyediakan Cepat, Seimbang, dan Akurat. Preset menentukan model awal, VAD, dan strategi dekoding. Semua model yang ada, termasuk `medium-q5_0` dan `large-v3-turbo-q5_0`, tetap ada di pemilih dan bisa menimpa preset kapan saja.
- **Perkiraan selesai langsung.** Bar progres kini menampilkan estimasi waktu selesai di samping persentase. Nilainya dihitung dari progres yang benar-benar teramati, dirata-ratakan agar tidak loncat, dan disembunyikan sampai cukup data. Tahap dekoding tetap indeterminate karena decoder tidak melaporkan persentase.
- **Mode Akurat memakai beam search.** `kk_options.quality` memilih dekoding greedy atau beam-5. CLI mendapat `--quality fast|balanced|accurate`; versi minor ABI menjadi 4.

### Peningkatan

- **Flash attention diaktifkan** pada konteks whisper, mengurangi memori puncak untuk audio panjang.
- **Kosakata khusus terbawa ke setiap window dekoding** lewat `carry_initial_prompt`, sehingga nama dan istilah tetap benar jauh ke dalam rekaman panjang.
- **Script benchmark** (`scripts/benchmark_transcribe.sh`) mencatat waktu tempuh per kombinasi model dan kualitas. Pengukuran lokal pada sampel JFK 11 detik: tiny 0,81 detik, small-q5_1 6,52 detik, small-q5_1 dengan VAD 6,23 detik, small-q5_1 dengan VAD dan beam-5 6,95 detik.
- **Logika ETA berada di helper murni** dengan tes unit di kedua aplikasi. Rangkaian Android kini 18 tes, desktop 11.

## v2.3.1

Rilis stabilitas dari audit runtime terhadap build Android yang sudah dirilis. Dua race nyata bisa melewati atau merusak transkripsi secara diam diam; keduanya diperbaiki dan diuji.

### Perbaikan bug

- **Share kini selalu auto-start saat model tersimpan.** Share yang membuka aplikasi bisa diproses sebelum `ensureStarted()` memuat model tersimpan dan membuat direktori model. `selectedModelCached` masih bernilai false, sehingga file termuat tetapi transkripsi tidak pernah dimulai. Penanganan share kini menunggu startup dan memutar ulang batch terbaru setelah engine siap.
- **Event job lama tidak bisa lagi mencemari transkrip baru.** Jika share baru masuk saat job berjalan, event segmen, progres, dan selesai dari worker lama diterapkan ke job baru karena penanganan tanpa id. Event worker kini dikorelasikan dengan id job aktif; event dari job yang sudah digantikan diabaikan, dan perubahan input membatalkan job yang masih berjalan.

### Peningkatan

- **`ShareHandler` di aplikasi Android** membuat urutan startup/share menjadi jelas dan dapat diuji.
- **`AppState` menerima `Transcriber` yang disuntikkan** sehingga event worker bisa disimulasikan dalam tes unit.
- **Tujuh tes baru** mencakup urutan pemutaran ulang share dan filter event lama; rangkaian tes Android kini menjalankan 14 tes.

## v2.3.0

Rilis alur kerja pasca-transkripsi yang nyata: perbaiki kata yang berulang dan pergeseran subtitle tanpa meninggalkan editor.

### Fitur baru

- **Cari dan ganti di semua segmen.** Editor transkrip kini punya panel cari/ganti dengan opsi bedakan huruf besar/kecil. Satu tindakan memperbarui semua segmen yang cocok, sehingga kesalahan nama yang konsisten bisa diperbaiki dalam hitungan detik.
- **Geser timing.** Offset dalam milidetik menggeser awal/akhir semua segmen bersamaan, dibatasi di nol, sehingga subtitle yang mendahului atau terlambat bisa disejajarkan dari editor. Semua ekspor memakai teks hasil edit dan timestamp yang digeser.

### Peningkatan

- **Helper logika murni** (`transcript_editor_logic.dart`) menjaga cari/ganti dan pergeseran timing tetap diuji secara unit, lepas dari widget Flutter.
- **Sepenuhnya terlokalisasi** dalam Inggris dan Indonesia.

## v2.2.0

Rilis fitur besar: aplikasi tidak lagi terbatas pada registry model bawaan.

### Fitur baru

- **Impor model ggml sendiri.** Desktop dan Android kini bisa mengimpor berkas model `.bin` atau `.gguf` lewat pemilih berkas. Berkas disalin ke direktori model aplikasi, didaftarkan di daftar pilihan, diverifikasi lewat keberadaan berkas, dan dipakai langsung oleh jalur FFI `kk_engine_create(model_path)` yang sudah ada. Tidak ada perubahan core: CLI sudah menerima `--model PATH`, kini aplikasi juga.
- **Manajemen model.** Model hasil impor tersimpan di SharedPreferences, bisa dipilih atau dihapus dari bagian model, dan menampilkan ukuran dalam MB. Penghapusan menghapus berkas dan membersihkan pilihan dengan aman.

### Catatan

- Model hasil impor tidak punya entri SHA-256 bawaan; dipakai apa adanya, sama seperti `--model PATH` di CLI.
- Semua label baru tersedia dalam Inggris dan Indonesia.

## v2.1.0

Menyelesaikan klaim UI dwibahasa v2.0.0: FAQ dan string UI yang tersisa kini benar-benar terlokalisasi.

### Peningkatan

- **Semua pertanyaan dan jawaban FAQ diterjemahkan.** 23 entri FAQ di tiap aplikasi kini tampil dalam Bahasa Indonesia saat locale Indonesia, lewat peta `faqId` khusus. v2.0.0 hanya menerjemahkan string bingkai dan meninggalkan FAQ dalam Inggris.
- **Privasi dan prompt unduhan diterjemahkan.** Dialog izin penyimpanan, petunjuk "belum diunduh", petunjuk bagikan, bilah status, dan tagline aplikasi kini mengikuti locale pilihan.
- **Cakupan test.** `faq_l10n_test.dart` baru di tiap aplikasi memverifikasi terjemahan FAQ dan fallback yang aman, agar regresi tidak diam-diam mengembalikan konten Inggris saja.

### Catatan

v2.0.0 mengklaim UI sepenuhnya terlokalisasi padahal FAQ dan beberapa prompt masih Inggris. Rilis ini memperbaiki klaim tersebut.

## v2.0.0

Rilis pertama dengan antarmuka yang sepenuhnya terlokalisasi. Inggris tetap menjadi sumber; Bahasa Indonesia adalah terjemahan nyata, bukan placeholder.

### Fitur baru

- **UI dwibahasa (Inggris / Bahasa Indonesia).** Kedua aplikasi menerjemahkan string antarmuka yang terlihat lewat lapisan `L10n` terpusat. Tile Bahasa di About mengganti locale; pilihan tersimpan dan diterapkan ke seluruh pohon widget.
- **Test lokalisasi.** Tiap aplikasi punya test yang membuktikan Inggris mengembalikan teks sumber, Indonesia menerjemahkan kunci yang dikenal, dan string yang belum diterjemahkan jatuh ke Inggris dengan aman.

### Catatan

- Inggris tetap menjadi sumber setiap string. Terjemahan Indonesia yang belum ada jatuh ke Inggris, bukan widget kosong.
- Ini versi mayor karena sistem bahasa UI adalah hal baru; alur kerja yang ada tidak berubah.

## v1.9.0

Rilis audit: sakelar GPU yang tidak berfungsi disembunyikan pada build CPU-only, dan polling progres tidak lagi membangun ulang UI setiap detak.

### Peningkatan

- **`kk_gpu_enabled()` ditambahkan ke C API.** Melaporkan apakah pustaka yang dimuat dibangun dengan backend GPU. Aplikasi desktop kini menyembunyikan toggle "Use GPU" saat build CPU-only resmi tidak bisa menggunakannya.
- **Polling progres dioptimasi.** UI desktop hanya dibangun ulang saat persentase benar-benar berubah, bukan setiap detak 80 ms.

## v1.8.0

Rilis format dan verifikasi: dua format ekspor baru dan CI yang akhirnya memeriksa transkripsi sungguhan.

### Fitur baru

- **Ekspor Markdown (`md`).** Transkrip dengan timestamp sebagai dokumen Markdown yang mudah dibaca, untuk catatan dan publikasi.
- **Ekspor CSV (`csv`).** `index,start_ms,end_ms,text` dengan pengutipan ala RFC, untuk spreadsheet dan alat subtitle.

### Peningkatan

- **CI transkripsi end-to-end.** Langkah Ubuntu baru mengunduh model tiny-q5_1, mentranskrip sampel JFK yang disertakan, dan memeriksa teks yang diharapkan, sehingga merge tidak pernah hijau hanya karena `--help`.
- `--help`/`--version` dan pemilih format kedua aplikasi kini mencantumkan keenam format keluaran.

## v1.7.0

Rilis kenyamanan dan integrasi desktop: simpan transkrip tanpa klik tambahan, `--version` asli di CLI, dan launcher menu aplikasi Linux.

### Fitur baru

- **Simpan otomatis.** Opsi yang tersimpan. Saat aktif, transkrip yang selesai langsung ditulis ke folder keluaran (SRT di mobile, format pilihan di desktop). Nonaktif secara default.
- **CLI `--version`.** Mencetak `kikoe 1.7.0` lalu keluar; tidak butuh model maupun media.
- **Launcher Linux.** Bundle Linux kini menyertakan file freedesktop `kikoe.desktop` dan ikon 512x512, agar Kikoe muncul di menu aplikasi GNOME/KDE setelah menyalin dua file ke direktori share pengguna.

### Peningkatan

- String versi konsisten di CLI --version, --help, C API, CMake dan manifest kedua aplikasi.

## v1.6.0

Rilis pemolesan native: pintasan keyboard desktop, pembersihan audit dan verifikasi CI ke depannya.

### Fitur baru

- **Pintasan keyboard desktop.** Ctrl/Cmd+O memilih file, Ctrl/Cmd+Enter memulai antrean, Esc membatalkan transkripsi yang sedang berjalan. Pintasan bekerja di seluruh tampilan antrean dan panel kontrol.
- **Pintasan About tetap membuka dari ikon app bar; pintasan keyboard kini didokumentasikan di FAQ.**

### Peningkatan

- **HOMEPAGE_URL di CMake desktop mengarah ke repositori yang benar** (`https://github.com/nekonaru/kikoe`).
- **build.gradle.kts Android bersih** (TODO template dihapus; application ID sudah benar untuk produksi).

## v1.5.0

Rilis yang fokus pada distribusi: aplikasi desktop Linux dan macOS bergabung dengan Windows; rilis publik kini menjangkau semua platform desktop utama dari satu core C++.

### Fitur baru

- **Aplikasi desktop Linux.** Bundle `kikoe-linux-x64.tar.gz` baru dengan binary GTK `kikoe_desktop`; Flutter + FFI, antrean seret-lepas yang sama, model yang sama, kontrak folder keluaran yang sama.
- **Aplikasi desktop macOS.** Zip `kikoe-macos-x64.zip` baru berisi `Kikoe.app` (Swift runner, Flutter + FFI). Paritas penuh dengan aplikasi Windows pada CI rilis.
- **Entitlement sandbox macOS.** Profil Release dan Debug sekarang memberi `network.client`, `files.user-selected.read-write` dan `files.downloads.read-write`, sehingga unduhan model, pemilihan file, dan penyimpanan bekerja dari dalam sandbox.

### Peningkatan

- **CI rilis mengirim bundle desktop Linux dan macOS** bersama Windows; catatan rilis dan README kini mencakup keempat platform.
- **Dokumen dan FAQ mencerminkan platform baru.** Instalasi, build, tabel CI, FAQ tentang peringatan bundle desktop, pohon struktur proyek, dan kebijakan privasi diperbarui dan dijaga sinkron EN/ID.

## v1.4.0

Rilis fitur yang fokus pada kekokohan pipeline dan pemolesan jalur native.

### Fitur baru

- **Progres langsung saat transkripsi.** Kedua aplikasi sekarang melakukan polling `kk_last_progress()` (C API berversi baru dengan atomic read tanpa lock, aman dipanggil dari isolate mana pun) selama worker diblokir di dalam `whisper_full()`, bukan membiarkan progress bar statis.
- **Progres langsung di notifikasi Android.** Indikator progres sistem kini mengikuti polling native yang sama, sejajar dengan bar di aplikasi.
- **Event serah terima engine.** Worker mengirim `engineReady` yang membawa pointer engine native, sehingga UI bisa melakukan polling dengan aman tanpa menembus isolate lewat memori mentah.

### Peningkatan

- **Konsistensi versi.** Tag, banner CLI, versi C API, proyek CMake dan kedua aplikasi melapor 1.4.0.

## v1.3.0

Fitur baru sejak v1.2.0: editor transkrip di dalam aplikasi, pustaka riwayat, custom vocabulary, dan save yang tidak lagi bergantung pada worker.

### Fitur baru

- **Editor transkrip.** Perbaiki kesalahan pengenalan per segmen sebelum simpan. Ekspor SRT dan VTT tetap membawa timestamp yang tepat; ekspor JSON meng-escape Unicode dengan benar.
- **Pustaka riwayat.** Ketuk ikon riwayat untuk melihat 50 transkripsi terakhir dengan jumlah kata; buka ulang, salin, ekspor ulang, atau hapus salah satunya.
- **Custom vocabulary.** Bidang hint opsional mengarahkan decoder ke nama produk, nama tempat dan ejaanmu (tersimpan). Tidak aktif tanpa kamu nyalakan.
- **Render format lokal.** Save dan share merender TXT, SRT, VTT dan JSON di Dart, cocok dengan formatter core byte-untuk-byte; edit tercermin langsung.

### Peningkatan

- **Salin transkripsi sekali ketuk.** Kedua aplikasi menyalin seluruh teks dalam satu ketukan.
- **State per file di Android.** Antrean file yang di-pick/share kini menampilkan progres, memindahkan lewat tombol Next; keluaran save tiap file dilacak terpisah.
- **Pengaturan tersimpan antar sesi** (model, bahasa, translate, VAD, vocabulary).
- **Simpan tidak menimpa.** File yang sudah ada diberi akhiran -2, -3. Aplikasi desktop juga mendapat tombol Open output folder.

### Perbaikan bug

- **Pencarian jalur VAD CLI** memakai registry, bukan nama file hard-coded.

## v1.2.0

Rilis fitur: filter keheningan dengan Silero VAD di kedua aplikasi, pengaturan yang tersimpan, berbagi dan memilih banyak file di Android, dan serangkaian perbaikan dari audit mendalam.

### Fitur baru

- **Silero VAD di kedua aplikasi.** Toggle Filter silence memangkas bagian hening sebelum transkripsi. Model Silero (0.9 MB) diunduh pada pemakaian pertama.
- **Pengaturan tersimpan.** Model, bahasa, translate dan toggle VAD pilihanmu bertahan setelah aplikasi ditutup.
- **Berbagi dan memilih banyak file di Android.** Membagikan atau memilih beberapa file audio/video mengantrekan semuanya; aplikasi memproses satu per satu.
- **Tombol salin transkrip.** Sekali ketuk menyalin seluruh transkrip ke clipboard (item antrean desktop dan kartu transkrip mobile).
- **Buka folder keluaran (desktop).** Langsung membuka lokasi hasil simpan transkrip.

### Peningkatan

- **Tidak ada penimpaan diam-diam.** Menyimpan transkrip tidak pernah menimpa file yang ada; aplikasi menambah -2, -3 dan seterusnya bila nama sudah dipakai.
- **Error unduhan model terlihat.** Desktop kini menampilkan error-nya, bukan gagal tanpa pesan.
- **Share intent Android dihormati penuh.** Semua file yang dibagikan masuk antrean, bukan hanya yang pertama.
- **Decode Android lebih responsif.** Decoding media berjalan di thread latar.

### Perbaikan bug

- **Jalur VAD CLI.** Jalur model Silero diambil dari registry model, bukan nama file yang di-hardcode.

## v1.1.0

Rilis fitur: About, sponsor dan FAQ lengkap di dalam aplikasi, default keluaran Downloads/kikoe, dan pemberitahuan izin penyimpanan pertama kali di Android.

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
