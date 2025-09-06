import 'package:floor/floor.dart';
import '../entities/kategori.dart';

@dao
abstract class KategoriDao {
  @Query('SELECT * FROM Kategori ORDER BY nama DESC')
  Future<List<Kategori>> findAllKategori();

  @insert
  Future<void> insertKategori(Kategori kategori);
}
