import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database_instance.dart';
import '../../data/entities/kategori.dart';
import '../../data/entities/produk.dart';
import '../widgets/form_menu_dialog.dart';

class ManajemenMenuPage extends StatefulWidget {
  const ManajemenMenuPage({super.key});

  @override
  State<ManajemenMenuPage> createState() => _ManajemenMenuPageState();
}

class _ManajemenMenuPageState extends State<ManajemenMenuPage> {
  late Future<List<Produk>> _produkFuture;
  List<Kategori> _kategoriList = [];
  Map<int, String> _kategoriMap = {};

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _produkFuture = _loadData();
  }

  Future<List<Produk>> _loadData() async {
    final db = await DatabaseInstance.database;
    _kategoriList = await db.kategoriDao.findAllKategori();
    _kategoriMap = {for (var item in _kategoriList) item.id!: item.nama};
    return db.produkDao.findAllProduk();
  }

  void _refreshData() {
    setState(() {
      _produkFuture = _loadData();
    });
  }

  void _showFormDialog({Produk? produk}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FormMenuDialog(
          produk: produk,
          kategoriList: _kategoriList,
          onSubmit: (produkBaru) async {
            final db = await DatabaseInstance.database;
            if (produk == null) {
              await db.produkDao.insertProduk(produkBaru);
            } else {
              await db.produkDao.updateProduk(produkBaru);
            }
            _refreshData();
          },
        );
      },
    );
  }

  void _deleteProduk(Produk produk) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text('Anda yakin ingin menghapus menu "${produk.nama}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  final db = await DatabaseInstance.database;
                  await db.produkDao.deleteProduk(produk);
                  Navigator.of(context).pop();
                  _refreshData();
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Menu'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<Produk>>(
          future: _produkFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'Belum ada menu. Silakan tambahkan.',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            final produkList = snapshot.data!;

            return ListView.builder(
              itemCount: produkList.length,
              itemBuilder: (context, index) {
                final produk = produkList[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    title: Text(
                      produk.nama,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_kategoriMap[produk.kategoriId] ?? 'N/A'),
                    trailing: SizedBox(
                      width: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              currencyFormatter.format(produk.harga),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showFormDialog(produk: produk),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteProduk(produk),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
        backgroundColor: Colors.brown[600],
      ),
    );
  }
}
