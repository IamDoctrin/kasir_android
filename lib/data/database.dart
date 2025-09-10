import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'daos/kategori_dao.dart';
import 'daos/produk_dao.dart';
import 'daos/transaksi_dao.dart';
import 'daos/detail_transaksi_dao.dart';
import 'entities/kategori.dart';
import 'entities/produk.dart';
import 'entities/transaksi.dart';
import 'entities/detail_transaksi.dart';
import 'type_converters.dart';

part 'database.g.dart';

final MIGRATION_1_2 = Migration(1, 2, (database) async {
  await database.execute('ALTER TABLE Transaksi ADD COLUMN lokasiMeja TEXT');
  await database.execute('ALTER TABLE Transaksi ADD COLUMN nomorMeja INTEGER');
});

final MIGRATION_2_3 = Migration(2, 3, (database) async {
  await database.execute(
    'ALTER TABLE Transaksi ADD COLUMN metodePembayaran TEXT',
  );
});

final MIGRATION_3_4 = Migration(3, 4, (database) async {
  await database.execute(
    'ALTER TABLE Transaksi ADD COLUMN nomorTransaksi TEXT',
  );
});

final MIGRATION_4_5 = Migration(4, 5, (database) async {
  await database.execute(
    'ALTER TABLE Transaksi ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0',
  );
});

@TypeConverters([DateTimeConverter])
@Database(version: 5, entities: [Kategori, Produk, Transaksi, DetailTransaksi])
abstract class AppDatabase extends FloorDatabase {
  KategoriDao get kategoriDao;
  ProdukDao get produkDao;
  TransaksiDao get transaksiDao;
  DetailTransaksiDao get detailTransaksiDao;
}

Future<void> seedDatabase(sqflite.Database database) async {
  await database.execute('DELETE FROM Produk');
  await database.execute('DELETE FROM Kategori');

  // Isi Kategori: 1=Makanan, 2=Minuman, 3=Extra
  await database.execute(
    'INSERT INTO Kategori (id, nama) VALUES (?, ?), (?, ?), (?, ?)',
    [1, 'Makanan', 2, 'Minuman', 3, 'Extra'],
  );

  // --- MENU MAKANAN ---
  // Menu Utama
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Gulai Kepala Kambing', 200000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Gulai Kambing + Nasi', 50000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Gulai Kambing', 40000, 'Porsi', 1],
  );
  // Nasi Goreng
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Nasi Goreng Kambing', 35000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Nasi Goreng Spesial', 30000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Nasi Goreng Biasa', 15000, 'Porsi', 1],
  );
  // Pecel
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Pecel Ayam + Nasi', 25000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Pecel Lele + Nasi', 25000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Pecel Nila + Nasi', 25000, 'Porsi', 1],
  );
  // Mie
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Mie Goreng Spesial', 30000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Mie Goreng Indomie', 13000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Mie Pedas', 18000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Mie Rebus Indomie', 13000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Mie Nas', 18000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kwetiauw Goreng', 25000, 'Porsi', 1],
  );
  // Khas Minang
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Ayam Goreng Panas + Nasi', 25000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Dendeng Kering + Nasi', 30000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Rendang + Nasi', 30000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Lele Goreng Panas + Nasi', 23000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Nila Goreng Panas + Nasi', 23000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Balado Telur Ikan Asin', 12000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Ayam Bumbu + Nasi', 25000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Gulai Ayam + Nasi', 25000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Gulai Ikan + Nasi', 23000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Telur Barendo', 15000, 'Porsi', 1],
  ); // Masuk kategori Makanan
  // Soto dan Sup
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Soto Padang + Nasi', 30000, 'Porsi', 1],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Sop Iga + Nasi', 50000, 'Porsi', 1],
  );
  // Ekstra
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jengkol Lado Hijau', 10000, 'Porsi', 3],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kentang Goreng', 20000, 'Porsi', 3],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Nugget Goreng', 20000, 'Porsi', 3],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Nasi Tambah', 5000, 'Porsi', 3],
  );

  // --- MENU MINUMAN ---
  // Coffe
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Hitam Penuh', 8000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Hitam Penuh (D)', 10000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Hitam 1/2', 5000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Susu Penuh', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Susu Penuh (D)', 14000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Susu 1/2', 7000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopmil Panas', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopmil Panas (D)', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Susu Jahe', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Cappucino Panas', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Cappucino Panas (D)', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Luwak White Coffe', 10000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Luwak White Coffe (D)', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Ginseng', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Kopi Ginseng (D)', 17000, 'Porsi', 2],
  );
  // Non Coffe
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Telur', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Telur Ginseng', 18000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Telur Jahe', 18000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Susu Jahe', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Susu', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Susu (D)', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Manis', 7000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Manis (D)', 8000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Tawar', 3000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Tawar (D)', 5000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Tarik', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Teh Tarik (D)', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Chocolatos', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Chocolatos (D)', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jeruk', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Susu Jahe', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Susu Putih', 10000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Susu Putih (D)', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Fanta Susu', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Sempayang', 5000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Milo', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Milo (D)', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Lemon Tea', 10000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Lemon Tea (D)', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Nutrisari', 8000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Pop Es', 10000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Es Kosong', 5000, 'Porsi', 2],
  );
  // Jus Buah
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Naga', 18000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Alpukat', 18000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Tomat', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Wortel', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Tomat + Wortel', 18000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Timun', 12000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Jeruk', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Mangga', 18000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Timun + Nanas', 18000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Jus Nanas', 15000, 'Porsi', 2],
  );
  // Es Krim
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Es Krim Coklat/Vanilla/Strowbarry', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Es Markisa', 15000, 'Porsi', 2],
  );
  await database.execute(
    'INSERT INTO Produk (nama, harga, satuan, kategori_id) VALUES (?, ?, ?, ?)',
    ['Es Doger', 15000, 'Porsi', 2],
  );
}
