import 'package:floor/floor.dart';
import 'package:intl/intl.dart';
import '../entities/transaksi.dart';
import '../database.dart';

@dao
abstract class TransaksiDao {
  Future<String> generateNewTransactionNumber(AppDatabase database) async {
    final now = DateTime.now();
    final startOfDay =
        DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay =
        DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        ).millisecondsSinceEpoch;

    final todayCount =
        (await countTransactionsForToday(startOfDay, endOfDay)) ?? 0;

    final nextUrut = (todayCount + 1).toString().padLeft(2, '0');
    final tglFormat = DateFormat('ddMMyy').format(now);
    return 'TRX$tglFormat$nextUrut';
  }

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

  @Query(
    'SELECT id, waktu_transaksi, subtotal, diskon, ppn_persentase, ppn_jumlah, grand_total, status, nomorTransaksi, lokasiMeja, nomorMeja, metodePembayaran FROM Transaksi WHERE id = :id',
  )
  Future<Transaksi?> findTransaksiById(int id);

  @insert
  Future<int?> insertTransaksi(Transaksi transaksi);

  @update
  Future<void> updateTransaksi(Transaksi transaksi);

  @Query('DELETE FROM Transaksi WHERE id = :id')
  Future<void> deleteTransaksiById(int id);

  @Query(
    'SELECT COUNT(id) FROM Transaksi WHERE waktu_transaksi >= :startOfDay AND waktu_transaksi < :endOfDay',
  )
  Future<int?> countTransactionsForToday(int startOfDay, int endOfDay);

  @Query('''
    SELECT SUM(ppn_jumlah) FROM Transaksi
    WHERE status = 'Closed' AND waktu_transaksi BETWEEN :startDate AND :endDate
  ''')
  Future<int?> getTotalPpnByDateRange(int startDate, int endDate);

  @Query(
    'SELECT * FROM Transaksi WHERE waktu_transaksi BETWEEN :startDate AND :endDate ORDER BY waktu_transaksi DESC',
  )
  Future<List<Transaksi>> findTransaksiByDateRange(int startDate, int endDate);
}
