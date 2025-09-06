# Aplikasi Kasir - Gulai Kambiang Kakek

<p align="center">
  <img src="assets/images/app_logo.png" width="200">
</p>

Aplikasi Point of Sale (POS) atau kasir berbasis Android yang dirancang khusus untuk operasional rumah makan. Aplikasi ini dibuat untuk berjalan secara offline pada perangkat tablet berukuran 11 inci, memastikan kelancaran transaksi bahkan tanpa koneksi internet.

---

## ✨ Fitur Utama

- **📱 Manajemen Transaksi**: Membuat pesanan baru, menyimpan pesanan (bayar nanti), hingga proses pembayaran (Cash/Transfer).
- **🍽️ Manajemen Menu**: Menambah, mengedit, dan menghapus daftar menu makanan, minuman, dan ekstra dengan mudah.
- **📜 Riwayat Transaksi**: Melihat daftar transaksi harian dan kemarin, lengkap dengan status "Open" atau "Closed".
- **📊 Laporan Penjualan**: Menyajikan laporan penjualan ringkas dan detail dalam rentang waktu harian, mingguan, bulanan, atau kustom.
- **📄 Ekspor Data**: Mengekspor laporan penjualan ke dalam format **PDF** dan **Excel** untuk kebutuhan akuntansi.
- **🔒 Database Lokal**: Seluruh data tersimpan aman di dalam perangkat menggunakan database Floor (SQLite), sehingga aplikasi tetap berfungsi penuh secara offline.

---

## 🛠️ Teknologi yang Digunakan

- **Framework**: [Flutter](https://flutter.dev/)
- **Bahasa**: [Dart](https://dart.dev/)
- **Database**: [Floor](https://pub.dev/packages/floor) (SQLite wrapper)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Ekspor PDF**: [printing](https://pub.dev/packages/printing) & [pdf](https://pub.dev/packages/pdf)
- **Ekspor Excel**: [excel](https://pub.dev/packages/excel)
- **Berbagi File**: [share_plus](https://pub.dev/packages/share_plus)

---

## 🚀 Cara Menjalankan Proyek

1.  Pastikan Anda sudah menginstal Flutter SDK.
2.  **Clone** repository ini:
    ```bash
    git clone [https://github.com/IamDoctrin/kasir_android](https://github.com/IamDoctrin/kasir_android.git)
    ```
3.  Pindah ke direktori proyek:
    ```bash
    cd kasir-android
    ```
4.  Instal semua dependensi:
    ```bash
    flutter pub get
    ```
5.  Jalankan *code generator*:
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```
6.  Jalankan aplikasi:
    ```bash
    flutter run
    ```

---

## 📝 Status Proyek

Proyek ini telah menyelesaikan semua fitur inti yang direncanakan dan siap untuk digunakan dalam lingkungan produksi.
