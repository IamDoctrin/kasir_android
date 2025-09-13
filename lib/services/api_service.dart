import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/database_instance.dart';
import '../data/entities/transaksi.dart';
import '../data/models/cart_item.dart';
import '../data/sync_manager.dart';
import '../data/entities/detail_transaksi.dart';

class SyncResult {
  final bool hasUnsyncedData;
  final int failureCount;
  SyncResult({required this.hasUnsyncedData, required this.failureCount});
}

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
      'jumlahBayar': transaksi.jumlahBayar,
      'jumlahKembali': transaksi.jumlahKembali,
      'items':
          items
              .map(
                (item) => {
                  'namaProduk': item.produk.nama,
                  'kategoriId': item.produk.kategoriId,
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
        // print(
        //   'BERHASIL: Transaksi #${transaksi.nomorTransaksi} terkirim ke server.',
        // );
        return true;
      } else {
        // print(
        //   'GAGAL: Transaksi #${transaksi.nomorTransaksi}. Status: ${response.statusCode}, Body: ${response.body}',
        // );
        return false;
      }
    } on SocketException {
      // print(
      //   'GAGAL: Transaksi #${transaksi.nomorTransaksi}: Tidak ada koneksi internet atau server tidak ditemukan.',
      // );
      return false;
    } catch (e) {
      // print(
      //   'GAGAL: Transaksi #${transaksi.nomorTransaksi}: Terjadi error -> $e',
      // );
      return false;
    }
  }

  Future<SyncResult> sinkronkanTransaksiTertunda() async {
    int failureCount = 0;
    final db = await DatabaseInstance.database;
    final unsyncedList = await db.transaksiDao.findUnsyncedTransactions();

    if (unsyncedList.isEmpty) {
      await SyncManager.setLastSyncTime(); // Tetap update waktu sync
      return SyncResult(hasUnsyncedData: false, failureCount: 0);
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
          jumlahBayar: trx.jumlahBayar,
          jumlahKembali: trx.jumlahKembali,
        );
        await db.transaksiDao.updateTransaksi(syncedTrx);
      } else {
        // Jika gagal, naikkan counter
        failureCount++;
      }
    }
    // Kembalikan jumlah total kegagalan
    await SyncManager.setLastSyncTime();
    return SyncResult(hasUnsyncedData: true, failureCount: failureCount);
  }

  Future<String> ambilDanSimpanTransaksiDariWeb() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transaksi');
    final db = await DatabaseInstance.database;

    try {
      // 1. Ambil data dari server
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json', 'X-Api-Key': ApiConfig.apiKey},
      );

      if (response.statusCode != 200) {
        return "Gagal mengambil data dari server. Status: ${response.statusCode}";
      }

      final List<dynamic> dataFromServer = json.decode(response.body);
      if (dataFromServer.isEmpty) {
        return "Tidak ada data di server untuk disinkronkan.";
      }

      int newTransactionCount = 0;

      // 2. Proses dan simpan setiap transaksi
      for (var trxData in dataFromServer) {
        final nomorTransaksiServer = trxData['nomor_transaksi'];

        // Cek apakah transaksi ini sudah ada di database lokal
        final existingTrx = await db.transaksiDao.findTransaksiByNomor(
          nomorTransaksiServer,
        );

        if (existingTrx == null) {
          // Jika belum ada, simpan transaksi baru
          final newTrx = Transaksi(
            nomorTransaksi: nomorTransaksiServer,
            waktuTransaksi: DateTime.parse(trxData['waktu_transaksi']),
            diskon:
                trxData['diskon'] ??
                0, // Ambil dari server, jika tidak ada, beri nilai 0
            ppnPersentase: trxData['ppn_persentase'] ?? 11.0,
            subtotal: trxData['subtotal'],
            ppnJumlah: trxData['ppn_jumlah'],
            grandTotal: trxData['grand_total'],
            status: 'Closed', // Asumsi semua data dari server sudah Closed
            metodePembayaran: trxData['metode_pembayaran'],
            lokasiMeja: trxData['lokasi_meja'],
            nomorMeja: trxData['nomor_meja'],
            jumlahBayar: trxData['jumlah_bayar'],
            jumlahKembali: trxData['jumlah_kembali'],
            isSynced: 1, // Tandai sebagai sudah sinkron
          );

          final newId = await db.transaksiDao.insertTransaksi(newTrx);
          if (newId == null) continue;

          // Simpan detail item
          final List<dynamic> itemsData = trxData['items'];
          for (var itemData in itemsData) {
            // Cari produk lokal berdasarkan nama
            final produk = await db.produkDao.findProdukByName(
              itemData['nama_produk'],
            );
            if (produk != null) {
              final detail = DetailTransaksi(
                transaksiId: newId,
                produkId: produk.id!,
                kuantitas: itemData['kuantitas'],
                hargaSaatTransaksi: itemData['harga_satuan'],
              );
              await db.detailTransaksiDao.insertDetailTransaksi(detail);
            }
          }
          newTransactionCount++;
        }
      }
      return "$newTransactionCount transaksi baru berhasil diunduh dari server.";
    } catch (e) {
      return "Terjadi error saat sinkronisasi: $e";
    }
  }
}
