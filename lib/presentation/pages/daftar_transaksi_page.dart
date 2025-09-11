import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import 'input_transaksi_page.dart';
import '../../data/database_instance.dart';
import '../../data/entities/transaksi.dart';
import 'receipt_preview_page.dart';
import '../widgets/last_sync_widget.dart';

class DaftarTransaksiPage extends StatefulWidget {
  const DaftarTransaksiPage({super.key});

  @override
  State<DaftarTransaksiPage> createState() => _DaftarTransaksiPageState();
}

class _DaftarTransaksiPageState extends State<DaftarTransaksiPage> {
  late Future<List<Transaksi>> _transaksiFuture;
  String _selectedFilter = 'Hari Ini';

  final GlobalKey<LastSyncWidgetState> _syncWidgetKey = GlobalKey();

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    _setFilterToToday();
  }

  void _setFilterToToday() {
    setState(() {
      _selectedFilter = 'Hari Ini';
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
      _transaksiFuture = DatabaseInstance.database.then(
        (db) => db.transaksiDao.findTransactionsForToday(startOfDay, endOfDay),
      );
    });
  }

  void _setFilterToYesterday() {
    setState(() {
      _selectedFilter = 'Kemarin';
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final startOfDay =
          DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
          ).millisecondsSinceEpoch;
      final endOfDay =
          DateTime(
            yesterday.year,
            yesterday.month,
            yesterday.day,
            23,
            59,
            59,
          ).millisecondsSinceEpoch;
      _transaksiFuture = DatabaseInstance.database.then(
        (db) => db.transaksiDao.findTransactionsForToday(startOfDay, endOfDay),
      );
    });
  }

  void _navigateToInputTransaksi({int? transactionId}) async {
    Provider.of<CartProvider>(context, listen: false).clearCart();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                InputTransaksiPage(editingTransactionId: transactionId),
      ),
    );
    _setFilterToToday();
  }

  Future<void> _navigateToPreview(Transaksi transaksi) async {
    final db = await DatabaseInstance.database;
    final details = await db.detailTransaksiDao.findDetailByTransaksiId(
      transaksi.id!,
    );
    final allProduk = await db.produkDao.findAllProduk();
    final produkMap = {for (var p in allProduk) p.id: p};

    final items =
        details.map((detail) {
          return CartItem(
            produk: produkMap[detail.produkId]!,
            kuantitas: detail.kuantitas,
          );
        }).toList();

    final paymentAmount = (transaksi.grandTotal).toDouble();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ReceiptPreviewPage(
                nomorTransaksi: transaksi.nomorTransaksi ?? 'N/A',
                cartItems: items,
                subtotal: transaksi.subtotal,
                ppnAmount: transaksi.ppnJumlah,
                totalAmount: transaksi.grandTotal,
                paymentAmount: paymentAmount,
                change: 0,
                lokasiMeja: transaksi.lokasiMeja ?? '',
                nomorMeja: transaksi.nomorMeja ?? 0,
                metodePembayaran: transaksi.metodePembayaran ?? 'N/A',
              ),
        ),
      );
    }
  }

  void _deleteTransaction(Transaksi transaksi) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Hapus'),
            content: Text(
              'Anda yakin ingin menghapus transaksi #${transaksi.nomorTransaksi ?? transaksi.id}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  final db = await DatabaseInstance.database;
                  await db.detailTransaksiDao.deleteDetailByTransaksiId(
                    transaksi.id!,
                  );
                  await db.transaksiDao.deleteTransaksiById(transaksi.id!);
                  Navigator.of(context).pop();
                  _setFilterToToday();
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Transaksi'),
            LastSyncWidget(key: _syncWidgetKey),
          ],
        ),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);

              messenger.showSnackBar(
                const SnackBar(content: Text('Memulai sinkronisasi...')),
              );

              final result = await ApiService().sinkronkanTransaksiTertunda();

              // Refresh tampilan waktu sinkronisasi
              _syncWidgetKey.currentState?.loadLastSyncTime();

              if (mounted) {
                if (result.failureCount > 0) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${result.failureCount} transaksi gagal disinkronkan, Cek Koneksi internet Anda.',
                      ),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                } else if (result.hasUnsyncedData) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Semua transaksi berhasil disinkronkan.',
                      ),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Tidak ada data baru untuk disinkronkan.'),
                    ),
                  );
                }
              }
              _setFilterToToday();
            },
            tooltip: 'Sinkronkan Data',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('Hari Ini'),
                  selected: _selectedFilter == 'Hari Ini',
                  onSelected: (bool selected) {
                    _setFilterToToday();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Kemarin'),
                  selected: _selectedFilter == 'Kemarin',
                  onSelected: (bool selected) {
                    _setFilterToYesterday();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Transaksi>>(
              future: _transaksiFuture,
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
                      'Tidak ada transaksi.',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final transaksiList = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: transaksiList.length,
                  itemBuilder: (context, index) {
                    final transaksi = transaksiList[index];
                    final bool isOpen = transaksi.status == 'Open';
                    final Color statusColor =
                        isOpen ? Colors.orange : Colors.green;
                    final trxIdToShow =
                        transaksi.nomorTransaksi ??
                        'TRX-${transaksi.id.toString().padLeft(7, '0')}';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10.0,
                          horizontal: 16.0,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(
                            isOpen ? Icons.edit_note : Icons.receipt_long,
                            color: statusColor,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              trxIdToShow,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (!isOpen)
                              Tooltip(
                                message:
                                    transaksi.isSynced == 1
                                        ? 'Sudah disinkronkan'
                                        : 'Menunggu sinkronisasi',
                                child: Icon(
                                  transaksi.isSynced == 1
                                      ? Icons.cloud_done_outlined
                                      : Icons.cloud_upload_outlined,
                                  size: 16,
                                  color:
                                      transaksi.isSynced == 1
                                          ? Colors.green.shade600
                                          : Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${dateFormatter.format(transaksi.waktuTransaksi)} • ${transaksi.lokasiMeja ?? ''} - Meja ${transaksi.nomorMeja ?? ''} • ${transaksi.metodePembayaran ?? ''}',
                        ),
                        trailing: SizedBox(
                          width: 150,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(
                                      transaksi.grandTotal,
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      transaksi.status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isOpen)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _deleteTransaction(transaksi),
                                  tooltip: 'Hapus Transaksi',
                                ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (isOpen) {
                            _navigateToInputTransaksi(
                              transactionId: transaksi.id,
                            );
                          } else {
                            _navigateToPreview(transaksi);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToInputTransaksi(),
        icon: const Icon(Icons.add),
        label: const Text('Transaksi Baru'),
        backgroundColor: Colors.brown[600],
      ),
    );
  }
}
