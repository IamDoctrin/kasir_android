import 'package:floor/floor.dart';
import '../entities/detail_transaksi.dart';

@dao
abstract class DetailTransaksiDao {
  @Query('SELECT * FROM DetailTransaksi WHERE transaksi_id = :transaksiId')
  Future<List<DetailTransaksi>> findDetailByTransaksiId(int transaksiId);

  @insert
  Future<void> insertDetailTransaksi(DetailTransaksi detailTransaksi);

  @Query('DELETE FROM DetailTransaksi WHERE transaksi_id = :transaksiId')
  Future<void> deleteDetailByTransaksiId(int transaksiId);
}
