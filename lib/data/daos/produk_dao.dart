import 'package:floor/floor.dart';
import '../entities/produk.dart';

@dao
abstract class ProdukDao {
  @Query('SELECT * FROM Produk ORDER BY nama ASC')
  Future<List<Produk>> findAllProduk();

  // Pencarian berdasarkan nama
  @Query('SELECT * FROM Produk WHERE nama LIKE :query ORDER BY nama ASC')
  Future<List<Produk>> findProdukBySearch(String query);

  // Pencarian berdasarkan Nama dan Kategori
  @Query(
    'SELECT * FROM Produk WHERE nama LIKE :query AND kategori_id = :kategoriId ORDER BY nama ASC',
  )
  Future<List<Produk>> findProdukBySearchAndCategory(
    String query,
    int kategoriId,
  );

  @Query('SELECT * FROM Produk WHERE nama = :nama LIMIT 1')
  Future<Produk?> findProdukByName(String nama);

  @insert
  Future<void> insertProduk(Produk produk);

  @update
  Future<void> updateProduk(Produk produk);

  @delete
  Future<void> deleteProduk(Produk produk);
}
