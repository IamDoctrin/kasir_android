import 'package:floor/floor.dart';
import 'produk.dart';
import 'transaksi.dart';

@Entity(
  foreignKeys: [
    ForeignKey(
      childColumns: ['transaksi_id'],
      parentColumns: ['id'],
      entity: Transaksi,
    ),
    ForeignKey(
      childColumns: ['produk_id'],
      parentColumns: ['id'],
      entity: Produk,
    ),
  ],
)
class DetailTransaksi {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'transaksi_id')
  final int transaksiId;

  @ColumnInfo(name: 'produk_id')
  final int produkId;

  final int kuantitas;

  @ColumnInfo(name: 'harga_saat_transaksi')
  final int hargaSaatTransaksi;

  DetailTransaksi({
    this.id,
    required this.transaksiId,
    required this.produkId,
    required this.kuantitas,
    required this.hargaSaatTransaksi,
  });
}
