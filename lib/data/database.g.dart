// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  KategoriDao? _kategoriDaoInstance;

  ProdukDao? _produkDaoInstance;

  TransaksiDao? _transaksiDaoInstance;

  DetailTransaksiDao? _detailTransaksiDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 4,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Kategori` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `nama` TEXT NOT NULL)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Produk` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `nama` TEXT NOT NULL, `harga` INTEGER NOT NULL, `satuan` TEXT NOT NULL, `kategori_id` INTEGER NOT NULL, FOREIGN KEY (`kategori_id`) REFERENCES `Kategori` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Transaksi` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `waktu_transaksi` INTEGER NOT NULL, `subtotal` INTEGER NOT NULL, `diskon` INTEGER NOT NULL, `ppn_persentase` REAL NOT NULL, `ppn_jumlah` INTEGER NOT NULL, `grand_total` INTEGER NOT NULL, `status` TEXT NOT NULL, `nomorTransaksi` TEXT, `lokasiMeja` TEXT, `nomorMeja` INTEGER, `metodePembayaran` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `DetailTransaksi` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `transaksi_id` INTEGER NOT NULL, `produk_id` INTEGER NOT NULL, `kuantitas` INTEGER NOT NULL, `harga_saat_transaksi` INTEGER NOT NULL, FOREIGN KEY (`transaksi_id`) REFERENCES `Transaksi` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION, FOREIGN KEY (`produk_id`) REFERENCES `Produk` (`id`) ON UPDATE NO ACTION ON DELETE NO ACTION)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  KategoriDao get kategoriDao {
    return _kategoriDaoInstance ??= _$KategoriDao(database, changeListener);
  }

  @override
  ProdukDao get produkDao {
    return _produkDaoInstance ??= _$ProdukDao(database, changeListener);
  }

  @override
  TransaksiDao get transaksiDao {
    return _transaksiDaoInstance ??= _$TransaksiDao(database, changeListener);
  }

  @override
  DetailTransaksiDao get detailTransaksiDao {
    return _detailTransaksiDaoInstance ??=
        _$DetailTransaksiDao(database, changeListener);
  }
}

class _$KategoriDao extends KategoriDao {
  _$KategoriDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _kategoriInsertionAdapter = InsertionAdapter(
            database,
            'Kategori',
            (Kategori item) =>
                <String, Object?>{'id': item.id, 'nama': item.nama});

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Kategori> _kategoriInsertionAdapter;

  @override
  Future<List<Kategori>> findAllKategori() async {
    return _queryAdapter.queryList('SELECT * FROM Kategori ORDER BY nama DESC',
        mapper: (Map<String, Object?> row) =>
            Kategori(id: row['id'] as int?, nama: row['nama'] as String));
  }

  @override
  Future<void> insertKategori(Kategori kategori) async {
    await _kategoriInsertionAdapter.insert(kategori, OnConflictStrategy.abort);
  }
}

class _$ProdukDao extends ProdukDao {
  _$ProdukDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _produkInsertionAdapter = InsertionAdapter(
            database,
            'Produk',
            (Produk item) => <String, Object?>{
                  'id': item.id,
                  'nama': item.nama,
                  'harga': item.harga,
                  'satuan': item.satuan,
                  'kategori_id': item.kategoriId
                }),
        _produkUpdateAdapter = UpdateAdapter(
            database,
            'Produk',
            ['id'],
            (Produk item) => <String, Object?>{
                  'id': item.id,
                  'nama': item.nama,
                  'harga': item.harga,
                  'satuan': item.satuan,
                  'kategori_id': item.kategoriId
                }),
        _produkDeletionAdapter = DeletionAdapter(
            database,
            'Produk',
            ['id'],
            (Produk item) => <String, Object?>{
                  'id': item.id,
                  'nama': item.nama,
                  'harga': item.harga,
                  'satuan': item.satuan,
                  'kategori_id': item.kategoriId
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Produk> _produkInsertionAdapter;

  final UpdateAdapter<Produk> _produkUpdateAdapter;

  final DeletionAdapter<Produk> _produkDeletionAdapter;

  @override
  Future<List<Produk>> findAllProduk() async {
    return _queryAdapter.queryList('SELECT * FROM Produk ORDER BY nama ASC',
        mapper: (Map<String, Object?> row) => Produk(
            id: row['id'] as int?,
            nama: row['nama'] as String,
            harga: row['harga'] as int,
            satuan: row['satuan'] as String,
            kategoriId: row['kategori_id'] as int));
  }

  @override
  Future<List<Produk>> findProdukBySearch(String query) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Produk WHERE nama LIKE ?1 ORDER BY nama ASC',
        mapper: (Map<String, Object?> row) => Produk(
            id: row['id'] as int?,
            nama: row['nama'] as String,
            harga: row['harga'] as int,
            satuan: row['satuan'] as String,
            kategoriId: row['kategori_id'] as int),
        arguments: [query]);
  }

  @override
  Future<List<Produk>> findProdukBySearchAndCategory(
    String query,
    int kategoriId,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Produk WHERE nama LIKE ?1 AND kategori_id = ?2 ORDER BY nama ASC',
        mapper: (Map<String, Object?> row) => Produk(id: row['id'] as int?, nama: row['nama'] as String, harga: row['harga'] as int, satuan: row['satuan'] as String, kategoriId: row['kategori_id'] as int),
        arguments: [query, kategoriId]);
  }

  @override
  Future<void> insertProduk(Produk produk) async {
    await _produkInsertionAdapter.insert(produk, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateProduk(Produk produk) async {
    await _produkUpdateAdapter.update(produk, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteProduk(Produk produk) async {
    await _produkDeletionAdapter.delete(produk);
  }
}

class _$TransaksiDao extends TransaksiDao {
  _$TransaksiDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _transaksiInsertionAdapter = InsertionAdapter(
            database,
            'Transaksi',
            (Transaksi item) => <String, Object?>{
                  'id': item.id,
                  'waktu_transaksi':
                      _dateTimeConverter.encode(item.waktuTransaksi),
                  'subtotal': item.subtotal,
                  'diskon': item.diskon,
                  'ppn_persentase': item.ppnPersentase,
                  'ppn_jumlah': item.ppnJumlah,
                  'grand_total': item.grandTotal,
                  'status': item.status,
                  'nomorTransaksi': item.nomorTransaksi,
                  'lokasiMeja': item.lokasiMeja,
                  'nomorMeja': item.nomorMeja,
                  'metodePembayaran': item.metodePembayaran
                }),
        _transaksiUpdateAdapter = UpdateAdapter(
            database,
            'Transaksi',
            ['id'],
            (Transaksi item) => <String, Object?>{
                  'id': item.id,
                  'waktu_transaksi':
                      _dateTimeConverter.encode(item.waktuTransaksi),
                  'subtotal': item.subtotal,
                  'diskon': item.diskon,
                  'ppn_persentase': item.ppnPersentase,
                  'ppn_jumlah': item.ppnJumlah,
                  'grand_total': item.grandTotal,
                  'status': item.status,
                  'nomorTransaksi': item.nomorTransaksi,
                  'lokasiMeja': item.lokasiMeja,
                  'nomorMeja': item.nomorMeja,
                  'metodePembayaran': item.metodePembayaran
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Transaksi> _transaksiInsertionAdapter;

  final UpdateAdapter<Transaksi> _transaksiUpdateAdapter;

  @override
  Future<List<Transaksi>> findAllTransaksi() async {
    return _queryAdapter.queryList(
        'SELECT id, waktu_transaksi, subtotal, diskon, ppn_persentase, ppn_jumlah, grand_total, status, nomorTransaksi, lokasiMeja, nomorMeja, metodePembayaran FROM Transaksi ORDER BY waktu_transaksi DESC',
        mapper: (Map<String, Object?> row) => Transaksi(
            id: row['id'] as int?,
            waktuTransaksi:
                _dateTimeConverter.decode(row['waktu_transaksi'] as int),
            subtotal: row['subtotal'] as int,
            diskon: row['diskon'] as int,
            ppnPersentase: row['ppn_persentase'] as double,
            ppnJumlah: row['ppn_jumlah'] as int,
            grandTotal: row['grand_total'] as int,
            status: row['status'] as String,
            nomorTransaksi: row['nomorTransaksi'] as String?,
            lokasiMeja: row['lokasiMeja'] as String?,
            nomorMeja: row['nomorMeja'] as int?,
            metodePembayaran: row['metodePembayaran'] as String?));
  }

  @override
  Future<List<Transaksi>> findTransactionsForToday(
    int startOfDay,
    int endOfDay,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Transaksi WHERE waktu_transaksi BETWEEN ?1 AND ?2 ORDER BY waktu_transaksi DESC',
        mapper: (Map<String, Object?> row) => Transaksi(id: row['id'] as int?, waktuTransaksi: _dateTimeConverter.decode(row['waktu_transaksi'] as int), subtotal: row['subtotal'] as int, diskon: row['diskon'] as int, ppnPersentase: row['ppn_persentase'] as double, ppnJumlah: row['ppn_jumlah'] as int, grandTotal: row['grand_total'] as int, status: row['status'] as String, nomorTransaksi: row['nomorTransaksi'] as String?, lokasiMeja: row['lokasiMeja'] as String?, nomorMeja: row['nomorMeja'] as int?, metodePembayaran: row['metodePembayaran'] as String?),
        arguments: [startOfDay, endOfDay]);
  }

  @override
  Future<Transaksi?> findTransaksiById(int id) async {
    return _queryAdapter.query(
        'SELECT id, waktu_transaksi, subtotal, diskon, ppn_persentase, ppn_jumlah, grand_total, status, nomorTransaksi, lokasiMeja, nomorMeja, metodePembayaran FROM Transaksi WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Transaksi(id: row['id'] as int?, waktuTransaksi: _dateTimeConverter.decode(row['waktu_transaksi'] as int), subtotal: row['subtotal'] as int, diskon: row['diskon'] as int, ppnPersentase: row['ppn_persentase'] as double, ppnJumlah: row['ppn_jumlah'] as int, grandTotal: row['grand_total'] as int, status: row['status'] as String, nomorTransaksi: row['nomorTransaksi'] as String?, lokasiMeja: row['lokasiMeja'] as String?, nomorMeja: row['nomorMeja'] as int?, metodePembayaran: row['metodePembayaran'] as String?),
        arguments: [id]);
  }

  @override
  Future<void> deleteTransaksiById(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM Transaksi WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<int?> countTransactionsForToday(
    int startOfDay,
    int endOfDay,
  ) async {
    return _queryAdapter.query(
        'SELECT COUNT(id) FROM Transaksi WHERE waktu_transaksi >= ?1 AND waktu_transaksi < ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [startOfDay, endOfDay]);
  }

  @override
  Future<int?> getTotalPpnByDateRange(
    int startDate,
    int endDate,
  ) async {
    return _queryAdapter.query(
        'SELECT SUM(ppn_jumlah) FROM Transaksi     WHERE status = \'Closed\' AND waktu_transaksi BETWEEN ?1 AND ?2',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [startDate, endDate]);
  }

  @override
  Future<List<Transaksi>> findTransaksiByDateRange(
    int startDate,
    int endDate,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Transaksi WHERE waktu_transaksi BETWEEN ?1 AND ?2 ORDER BY waktu_transaksi DESC',
        mapper: (Map<String, Object?> row) => Transaksi(id: row['id'] as int?, waktuTransaksi: _dateTimeConverter.decode(row['waktu_transaksi'] as int), subtotal: row['subtotal'] as int, diskon: row['diskon'] as int, ppnPersentase: row['ppn_persentase'] as double, ppnJumlah: row['ppn_jumlah'] as int, grandTotal: row['grand_total'] as int, status: row['status'] as String, nomorTransaksi: row['nomorTransaksi'] as String?, lokasiMeja: row['lokasiMeja'] as String?, nomorMeja: row['nomorMeja'] as int?, metodePembayaran: row['metodePembayaran'] as String?),
        arguments: [startDate, endDate]);
  }

  @override
  Future<int> insertTransaksi(Transaksi transaksi) {
    return _transaksiInsertionAdapter.insertAndReturnId(
        transaksi, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateTransaksi(Transaksi transaksi) async {
    await _transaksiUpdateAdapter.update(transaksi, OnConflictStrategy.abort);
  }
}

class _$DetailTransaksiDao extends DetailTransaksiDao {
  _$DetailTransaksiDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _detailTransaksiInsertionAdapter = InsertionAdapter(
            database,
            'DetailTransaksi',
            (DetailTransaksi item) => <String, Object?>{
                  'id': item.id,
                  'transaksi_id': item.transaksiId,
                  'produk_id': item.produkId,
                  'kuantitas': item.kuantitas,
                  'harga_saat_transaksi': item.hargaSaatTransaksi
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DetailTransaksi> _detailTransaksiInsertionAdapter;

  @override
  Future<List<DetailTransaksi>> findDetailByTransaksiId(int transaksiId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM DetailTransaksi WHERE transaksi_id = ?1',
        mapper: (Map<String, Object?> row) => DetailTransaksi(
            id: row['id'] as int?,
            transaksiId: row['transaksi_id'] as int,
            produkId: row['produk_id'] as int,
            kuantitas: row['kuantitas'] as int,
            hargaSaatTransaksi: row['harga_saat_transaksi'] as int),
        arguments: [transaksiId]);
  }

  @override
  Future<void> deleteDetailByTransaksiId(int transaksiId) async {
    await _queryAdapter.queryNoReturn(
        'DELETE FROM DetailTransaksi WHERE transaksi_id = ?1',
        arguments: [transaksiId]);
  }

  @override
  Future<void> insertDetailTransaksi(DetailTransaksi detailTransaksi) async {
    await _detailTransaksiInsertionAdapter.insert(
        detailTransaksi, OnConflictStrategy.abort);
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
