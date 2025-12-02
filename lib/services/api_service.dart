import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/database_instance.dart';
import '../data/entities/transaksi.dart';
import '../data/models/cart_item.dart';
import '../data/sync_manager.dart';
import '../data/entities/detail_transaksi.dart';
import '../data/entities/produk.dart';

class SyncResult {
  final bool hasUnsyncedData;
  final int failureCount;
  final List<String> errorMessages;

  SyncResult({
    required this.hasUnsyncedData,
    required this.failureCount,
    required this.errorMessages,
  });
}

class ApiService {
  // Mengirim data transaksi ke server
  Future<(bool, String?)> kirimTransaksi(
    Transaksi transaksi,
    List<CartItem> items,
  ) async {
    var url = Uri.parse('${ApiConfig.baseUrl}/transaksi');
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

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'X-Api-Key': ApiConfig.apiKey,
    };

    try {
      // Gunakan custom client untuk kontrol redirect
      final client = http.Client();
      var request =
          http.Request('POST', url)
            ..headers.addAll(headers)
            ..body = body;

      // Kirim request tanpa auto-redirect
      final responseStream = await client.send(request);
      var response = await http.Response.fromStream(responseStream);

      // Cek apakah ada redirect (status code 302)
      if (response.statusCode == 302) {
        final newLocation = response.headers['location'];
        if (newLocation != null) {
          // Jika ada lokasi baru, kirim ulang request ke sana
          url = Uri.parse(newLocation);
          request =
              http.Request('POST', url)
                ..headers.addAll(headers)
                ..body = body;
          final redirectedResponseStream = await client.send(request);
          response = await http.Response.fromStream(redirectedResponseStream);
        } else {
          return (
            false,
            'Server melakukan redirect (302) tetapi tidak memberikan lokasi baru.',
          );
        }
      }

      client.close();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return (true, null); // Berhasil
      } else {
        return (false, 'Server Error ${response.statusCode}: ${response.body}');
      }
    } on SocketException {
      return (false, 'Tidak ada koneksi internet.');
    } catch (e) {
      return (false, 'Terjadi error tak terduga: $e');
    }
  }

  Future<SyncResult> sinkronkanTransaksiTertunda() async {
    int failureCount = 0;
    final List<String> errorMessages = [];
    final db = await DatabaseInstance.database;
    final unsyncedList = await db.transaksiDao.findUnsyncedTransactions();

    if (unsyncedList.isEmpty) {
      await SyncManager.setLastSyncTime();
      return SyncResult(
        hasUnsyncedData: false,
        failureCount: 0,
        errorMessages: [],
      );
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

      final (isSuccess, errorMessage) = await kirimTransaksi(trx, items);

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
        failureCount++;
        errorMessages.add(
          'Transaksi #${trx.nomorTransaksi ?? trx.id}: ${errorMessage ?? "Gagal tanpa pesan"}',
        );
      }
    }
    await SyncManager.setLastSyncTime();

    return SyncResult(
      hasUnsyncedData: true,
      failureCount: failureCount,
      errorMessages: errorMessages,
    );
  }

  Stream<String> ambilDanSimpanTransaksiDariWeb() async* {
    final db = await DatabaseInstance.database;
    int newTransactionCount = 0;
    int currentPage = 1;
    int? totalPages;

    try {
      yield "Mempersiapkan data lokal...";

      final allProdukList = await db.produkDao.findAllProduk();
      final Map<String, Produk> produkMapByName = {
        for (var p in allProdukList) p.nama: p,
      };

      final allLocalTrx = await db.transaksiDao.findAllTransaksi();
      final Set<String?> existingNomorSet =
          allLocalTrx.map((t) => t.nomorTransaksi).toSet();

      yield "Menghubungi server...";

      while (true) {
        if (totalPages != null) {
          yield "Mengunduh halaman $currentPage dari $totalPages...";
        } else {
          yield "Mengunduh halaman $currentPage...";
        }

        final url = Uri.parse(
          '${ApiConfig.baseUrl}/transaksi?page=$currentPage',
        );
        final response = await http.get(
          url,
          headers: {
            'Accept': 'application/json',
            'X-Api-Key': ApiConfig.apiKey,
          },
        );

        if (response.statusCode != 200) {
          yield "ERROR: Gagal mengambil data. Status: ${response.statusCode}";
          return;
        }

        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> pageData = responseData['data'] as List<dynamic>;

        totalPages ??= responseData['last_page'] as int?;

        if (pageData.isEmpty) {
          break;
        }

        yield "Memproses halaman $currentPage... (Menyimpan data)";
        int countDiHalamanIni = 0;

        for (var trxData in pageData) {
          final nomorTransaksiServer = trxData['nomor_transaksi'];

          if (!existingNomorSet.contains(nomorTransaksiServer)) {
            final newTrx = Transaksi(
              nomorTransaksi: nomorTransaksiServer,
              waktuTransaksi: DateTime.parse(trxData['waktu_transaksi']),
              diskon: trxData['diskon'] ?? 0,
              ppnPersentase:
                  (trxData['ppn_persentase'] as num?)?.toDouble() ?? 11.0,
              subtotal: trxData['subtotal'],
              ppnJumlah: trxData['ppn_jumlah'],
              grandTotal: trxData['grand_total'],
              status: 'Closed',
              metodePembayaran: trxData['metode_pembayaran'],
              lokasiMeja: trxData['lokasi_meja'],
              nomorMeja: trxData['nomor_meja'],
              jumlahBayar: trxData['jumlah_bayar'],
              jumlahKembali: trxData['jumlah_kembali'],
              isSynced: 1,
            );

            final newId = await db.transaksiDao.insertTransaksi(newTrx);
            if (newId == null) continue;

            final List<dynamic> itemsData = trxData['items'];
            for (var itemData in itemsData) {
              var produk = produkMapByName[itemData['nama_produk']];

              if (produk == null) {
                final newProduk = Produk(
                  nama: itemData['nama_produk'],
                  harga: itemData['harga_satuan'],
                  kategoriId: itemData['kategori_id'] ?? 0,
                );
                final newProdukId = await db.produkDao.insertProduk(newProduk);
                if (newProdukId != null) {
                  produk = Produk(
                    id: newProdukId,
                    nama: newProduk.nama,
                    harga: newProduk.harga,
                    kategoriId: newProduk.kategoriId,
                  );
                  produkMapByName[produk.nama] = produk;
                }
              }

              if (produk != null) {
                final detail = DetailTransaksi(
                  transaksiId: newId,
                  produkId: produk.id!,
                  kuantitas: itemData['kuantitas'],
                  hargaSaatTransaksi: itemData['harga_satuan'],
                  namaProduk: itemData['nama_produk'],
                );
                await db.detailTransaksiDao.insertDetailTransaksi(detail);
              }
            }
            countDiHalamanIni++;
            existingNomorSet.add(nomorTransaksiServer);
          }
        }

        newTransactionCount += countDiHalamanIni;
        currentPage++;
      }

      await SyncManager.setLastSyncTime();

      if (newTransactionCount == 0) {
        yield "Selesai. Tidak ada data baru yang diunduh.";
      } else {
        yield "Selesai. Total $newTransactionCount transaksi baru berhasil diunduh.";
      }
    } catch (e) {
      yield "ERROR (Halaman $currentPage): ${e.toString()}";
    }
  }

  Future<bool> hapusTransaksiDiServer(String nomorTransaksi) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transaksi/$nomorTransaksi');
    try {
      final response = await http.delete(
        url,
        headers: {'Accept': 'application/json', 'X-Api-Key': ApiConfig.apiKey},
      );
      // Berhasil jika status 200 (OK) atau 404 (sudah terhapus di server)
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      // Gagal karena masalah koneksi
      return false;
    }
  }
}
