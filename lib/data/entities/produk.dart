import 'package:floor/floor.dart';
import 'kategori.dart';

@Entity(
  foreignKeys: [
    ForeignKey(
      childColumns: ['kategori_id'],
      parentColumns: ['id'],
      entity: Kategori,
    ),
  ],
)
class Produk {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String nama;
  final int harga;
  final String satuan;

  @ColumnInfo(name: 'kategori_id')
  final int kategoriId;

  Produk({
    this.id,
    required this.nama,
    required this.harga,
    this.satuan = 'Porsi',
    required this.kategoriId,
  });
}
