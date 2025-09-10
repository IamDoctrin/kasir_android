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
        print(
          'BERHASIL: Transaksi #${transaksi.nomorTransaksi} terkirim ke server.',
        );
        return true;
      } else {
        print(
          'GAGAL: Transaksi #${transaksi.nomorTransaksi}. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } on SocketException {
      print(
        'GAGAL: Transaksi #${transaksi.nomorTransaksi}: Tidak ada koneksi internet atau server tidak ditemukan.',
      );
      return false;
    } catch (e) {
      print(
        'GAGAL: Transaksi #${transaksi.nomorTransaksi}: Terjadi error -> $e',
      );
      return false;
    }
  }

  // UBAH TIPE RETURN DARI void MENJADI Future<int>
  Future<int> sinkronkanTransaksiTertunda() async {
    int failureCount = 0; // Tambahkan counter untuk kegagalan

    final db = await DatabaseInstance.database;
    final unsyncedList = await db.transaksiDao.findUnsyncedTransactions();

    if (unsyncedList.isEmpty) {
      return 0; // Kembalikan 0 jika tidak ada yang perlu disinkronkan
    }

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
      } else {
        // Jika gagal, naikkan counter
        failureCount++;
      }
    }
    // Kembalikan jumlah total kegagalan
    return failureCount;
  }
}
