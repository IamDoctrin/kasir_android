import 'package:floor/floor.dart';

@entity
class Transaksi {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'waktu_transaksi')
  final DateTime waktuTransaksi;

  final int subtotal;
  final int diskon;

  @ColumnInfo(name: 'ppn_persentase')
  final double ppnPersentase;

  @ColumnInfo(name: 'ppn_jumlah')
  final int ppnJumlah;

  @ColumnInfo(name: 'grand_total')
  final int grandTotal;

  final String status;
  final String? nomorTransaksi;
  final String? lokasiMeja;
  final int? nomorMeja;
  final String? metodePembayaran;

  Transaksi({
    this.id,
    required this.waktuTransaksi,
    required this.subtotal,
    required this.diskon,
    required this.ppnPersentase,
    required this.ppnJumlah,
    required this.grandTotal,
    required this.status,
    this.nomorTransaksi,
    this.lokasiMeja,
    this.nomorMeja,
    this.metodePembayaran,
  });
}
