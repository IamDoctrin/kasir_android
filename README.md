# Aplikasi Kasir - Gulai Kambiang Kakek

<p align="center">
  <img src="assets/images/app_logo_nobg.png" width="200">
</p>

Aplikasi Point of Sale (POS) atau kasir berbasis Android yang dirancang khusus untuk operasional rumah makan **Gulai Kambiang Kakek**. Aplikasi ini dibuat untuk berjalan secara *offline-first* pada perangkat tablet, memastikan kelancaran transaksi bahkan saat koneksi internet tidak stabil atau terputus.

---

## ✨ Fitur Utama

- **📱 Manajemen Transaksi**: Membuat pesanan baru, menyimpan pesanan (status "Open"), hingga proses pembayaran (Cash/Transfer).
- **🍽️ Manajemen Menu**: CRUD (Create, Read, Update, Delete) untuk daftar menu makanan, minuman, dan ekstra dengan antarmuka yang mudah.
- **📜 Riwayat Transaksi**: Melihat daftar transaksi harian dan kemarin, lengkap dengan status visual "Open" atau "Closed".
- **📊 Laporan Penjualan**: Menyajikan laporan penjualan ringkas (per produk) dan detail (per transaksi) dalam rentang waktu harian, mingguan, bulanan, atau kustom.
- **📄 Ekspor Data**: Mengekspor laporan penjualan ke dalam format **PDF** dan **Excel** untuk kebutuhan akuntansi dan pelaporan.
- **🔒 Database Lokal**: Seluruh data tersimpan aman di dalam perangkat menggunakan database Floor (SQLite), sehingga aplikasi tetap berfungsi penuh secara *offline*.
- **☁️ Sinkronisasi Otomatis**: Secara otomatis mengirim data transaksi yang sudah selesai ke server web (*backend*) saat aplikasi dibuka atau setiap 30 menit.
- **🌐 Penanganan Offline**: Jika tidak ada koneksi internet, data akan disimpan di antrean dan dikirim kembali nanti. Status sinkronisasi (`Tersinkronisasi` / `Menunggu`) ditampilkan secara visual di riwayat transaksi.
- **🖨️ Cetak Struk Langsung**: Terhubung dan mencetak struk langsung ke printer thermal Bluetooth (format 80mm) dari halaman *preview* tanpa memerlukan aplikasi perantara.

---

## 🛠️ Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev/)
- **Bahasa**: [Dart](https://dart.dev/)
- **Database**: [Floor](https://pub.dev/packages/floor) (SQLite wrapper)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Koneksi API**: [http](https://pub.dev/packages/http)
- **Cetak Struk Thermal**: [flutter_bluetooth_printer](https://pub.dev/packages/flutter_bluetooth_printer)
- **Ekspor Laporan**:
    - **PDF**: [printing](https://pub.dev/packages/printing) & [pdf](https://pub.dev/packages/pdf)
    - **Excel**: [excel](https://pub.dev/packages/excel)
- **Berbagi File**: [share_plus](https://pub.dev/packages/share_plus)
- **Integrasi Web**: [kasir_web](https://github.com/NoelleMeta/kasir_web)

---

## 🚀 Cara Menjalankan Proyek

1.  Pastikan Anda sudah menginstal Flutter SDK (disarankan versi 3.x.x ke atas).
2.  **Clone** repository ini:
    ```bash
    git clone https://github.com/IamDoctrin/kasir_android.git
    ```
3.  Pindah ke direktori proyek:
    ```bash
    cd kasir_android
    ```
4.  Buat file konfigurasi API. Salin `lib/config/api_config.dart.example` menjadi `lib/config/api_config.dart` dan sesuaikan isinya.
    ```dart
    // lib/config/api_config.dart
    class ApiConfig {
      static const String baseUrl = "https://URL_SERVER_ANDA/api/v1";
      static const String apiKey = "API_KEY_RAHASIA_ANDA";
    }
    ```
5.  Instal semua dependensi:
    ```bash
    flutter pub get
    ```
6.  Jalankan *code generator* untuk database:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
7.  Jalankan aplikasi:
    ```bash
    flutter run
    ```

---

## 📝 Status Proyek

Proyek ini telah menyelesaikan semua fitur inti yang direncanakan dan siap untuk digunakan dalam lingkungan produksi.
