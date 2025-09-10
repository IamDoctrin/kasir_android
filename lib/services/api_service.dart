import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/database_instance.dart';
import '../data/entities/transaksi.dart';
import '../data/models/cart_item.dart';

class ApiService {
  Future<bool> kirimTransaksi(Transaksi transaksi, List<CartItem> items) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transaksi');

    final body = json.encode({
      'nomorTransaksi': transaksi.nomorTransaksi,
      'waktuTransaksi': transaksi.waktuTransaksi.toIso8601String(),
      'subtotal': transaksi.subtotal,
      'ppnJumlah': transaksi.ppnJumlah,
      'grandTotal': transaksi.grandTotal,
      'status': transaksi.status,
      'metodePembayaran': transaksi.metodePembayaran,
      'lokasiMeja': transaksi.lokasiMeja,
      'nomorMeja': transaksi.nomorMeja,
      'items':
          items
              .map(
                (item) => {
                  'namaProduk': item.produk.nama,
                  'kuantitas': item.kuantitas,
                  'hargaSatuan': item.produk.harga,
                },
              )
              .toList(),
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'X-Api-Key': ApiConfig.apiKey,
        },
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // print('Transaksi #${transaksi.nomorTransaksi} berhasil dikirim ke server.');
        return true;
      } else {
        // print(
        //     'Gagal mengirim transaksi #${transaksi.nomorTransaksi}. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } on SocketException {
      // print(
      //     'Gagal mengirim transaksi #${transaksi.nomorTransaksi}: Tidak ada koneksi internet.');
      return false;
    } catch (e) {
      // print(
      //     'Gagal mengirim transaksi #${transaksi.nomorTransaksi}: Terjadi error -> $e');
      return false;
    }
  }

  /// Menjalankan proses sinkronisasi untuk semua transaksi yang tertunda.
  Future<void> sinkronkanTransaksiTertunda() async {
    // print("Memulai proses sinkronisasi...");
    final db = await DatabaseInstance.database;
    final unsyncedList = await db.transaksiDao.findUnsyncedTransactions();

    if (unsyncedList.isEmpty) {
      // print("Tidak ada transaksi yang perlu disinkronkan.");
      return;
    }

    // print("Ditemukan ${unsyncedList.length} transaksi untuk disinkronkan.");

    final allProduk = await db.produkDao.findAllProduk();
    final produkMap = {for (var p in allProduk) p.id!: p};

    for (final trx in unsyncedList) {
      final details = await db.detailTransaksiDao.findDetailByTransaksiId(
        trx.id!,
      );
      final items =
          details.map((detail) {
            return CartItem(
              produk: produkMap[detail.produkId]!,
              kuantitas: detail.kuantitas,
            );
          }).toList();

      final isSuccess = await kirimTransaksi(trx, items);

      if (isSuccess) {
        final syncedTrx = Transaksi(
          id: trx.id,
          waktuTransaksi: trx.waktuTransaksi,
          subtotal: trx.subtotal,
          diskon: trx.diskon,
          ppnPersentase: trx.ppnPersentase,
          ppnJumlah: trx.ppnJumlah,
          grandTotal: trx.grandTotal,
          status: trx.status,
          nomorTransaksi: trx.nomorTransaksi,
          lokasiMeja: trx.lokasiMeja,
          nomorMeja: trx.nomorMeja,
          metodePembayaran: trx.metodePembayaran,
          isSynced: 1,
        );
        await db.transaksiDao.updateTransaksi(syncedTrx);
        // print("Update lokal untuk Transaksi #${trx.nomorTransaksi} berhasil.");
      }
    }
    // print("Proses sinkronisasi selesai.");
  }
}
