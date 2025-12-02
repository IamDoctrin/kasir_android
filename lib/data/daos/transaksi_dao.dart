import 'package:floor/floor.dart';
import 'package:intl/intl.dart';
import '../entities/transaksi.dart';
import '../database.dart';

@dao
abstract class TransaksiDao {
  Future<String> generateNewTransactionNumber(AppDatabase database) async {
    final now = DateTime.now();
    final tglFormat = DateFormat('ddMMyy').format(now);
    final prefix = 'TRX$tglFormat';

    // 1. Cari transaksi terakhir dengan awalan tanggal hari ini
    final lastTransaction = await findLastTransactionByPrefix('$prefix%');

    int nextUrut = 1;
    if (lastTransaction != null && lastTransaction.nomorTransaksi != null) {
      // 2. Jika ada, ambil nomor urut terakhir dan tambahkan 1
      final lastNumberStr = lastTransaction.nomorTransaksi!.substring(
        prefix.length,
      );
      final lastNumber = int.tryParse(lastNumberStr) ?? 0;
      nextUrut = lastNumber + 1;
    }

    // 3. Buat ID baru
    final urutStr = nextUrut.toString().padLeft(2, '0');
    return '$prefix$urutStr';
  }

  @Query(
    'SELECT * FROM Transaksi WHERE nomorTransaksi LIKE :prefix ORDER BY nomorTransaksi DESC LIMIT 1',
  )
  Future<Transaksi?> findLastTransactionByPrefix(String prefix);

  @Query(
    'SELECT id, waktu_transaksi, subtotal, diskon, ppn_persentase, ppn_jumlah, grand_total, status, nomorTransaksi, lokasiMeja, nomorMeja, metodePembayaran FROM Transaksi ORDER BY waktu_transaksi DESC',
  )
  Future<List<Transaksi>> findAllTransaksi();

  @Query(
    'SELECT * FROM Transaksi WHERE waktu_transaksi BETWEEN :startOfDay AND :endOfDay ORDER BY waktu_transaksi DESC',
  )
  Future<List<Transaksi>> findTransactionsForToday(
    int startOfDay,
    int endOfDay,
  );

  @Query('SELECT * FROM Transaksi WHERE id = :id')
  Future<Transaksi?> findTransaksiByIdRaw(int id);
  Future<Transaksi?> findTransaksiById(int id) async {
    final trx = await findTransaksiByIdRaw(id);
    if (trx == null) return null;
    if (trx.isSynced == null) {
      return Transaksi(
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
        isSynced: 0,
      );
    }
    return trx;
  }

  @insert
  Future<int?> insertTransaksi(Transaksi transaksi);

  @update
  Future<void> updateTransaksi(Transaksi transaksi);

  @Query('DELETE FROM Transaksi WHERE id = :id')
  Future<void> deleteTransaksiById(int id);

  @Query('''
    SELECT SUM(ppn_jumlah) FROM Transaksi
    WHERE status = 'Closed' AND waktu_transaksi BETWEEN :startDate AND :endDate
  ''')
  Future<int?> getTotalPpnByDateRange(int startDate, int endDate);

  @Query('''
    SELECT * FROM Transaksi 
    WHERE waktu_transaksi BETWEEN :startDate AND :endDate 
    ORDER BY
      CASE status
        WHEN 'Open' THEN 1
        ELSE 2
      END,
      waktu_transaksi DESC
    ''')
  Future<List<Transaksi>> findTransaksiByDateRange(int startDate, int endDate);

  @Query(
    "SELECT * FROM Transaksi WHERE status = 'Closed' AND (is_synced = 0 OR is_synced IS NULL)",
  )
  Future<List<Transaksi>> findUnsyncedTransactions();

  @Query(
    'SELECT * FROM Transaksi WHERE nomorTransaksi = :nomorTransaksi LIMIT 1',
  )
  Future<Transaksi?> findTransaksiByNomor(String nomorTransaksi);
}
