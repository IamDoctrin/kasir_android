import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/cart_item.dart';
import '../../providers/cart_provider.dart';
import 'input_transaksi_page.dart';
import '../../data/database_instance.dart';
import '../../data/entities/transaksi.dart';
import '../widgets/payment_receipt_dialog.dart';
import '../widgets/transaction_detail_dialog.dart';

class DaftarTransaksiPage extends StatefulWidget {
  const DaftarTransaksiPage({super.key});

  @override
  State<DaftarTransaksiPage> createState() => _DaftarTransaksiPageState();
}

class _DaftarTransaksiPageState extends State<DaftarTransaksiPage> {
  late Future<List<Transaksi>> _transaksiFuture;
  String _selectedFilter = 'Hari Ini';

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

  Future<void> _showTransactionActions(Transaksi transaksi) async {
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

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => TransactionDetailDialog(
              transaksi: transaksi,
              items: items,
              onPrintReceipt: () {
                Navigator.of(context).pop();
                _showReceiptDialog(transaksi, items);
              },
            ),
      );
    }
  }

  Future<void> _showReceiptDialog(
    Transaksi transaksi,
    List<CartItem> items,
  ) async {
    final totalAmountWithPpn = (transaksi.subtotal) + (transaksi.ppnJumlah);

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (context) => ReceiptDialog(
              transactionId: transaksi.id!,
              nomorTransaksi: transaksi.nomorTransaksi ?? 'N/A',
              cartItems: items,
              subtotal: transaksi.subtotal,
              ppnAmount: transaksi.ppnJumlah,
              totalAmount: totalAmountWithPpn,
              paymentAmount: totalAmountWithPpn.toDouble(),
              change: 0,
              lokasiMeja: transaksi.lokasiMeja ?? 'N/A',
              nomorMeja: transaksi.nomorMeja ?? 0,
              metodePembayaran: transaksi.metodePembayaran ?? 'N/A',
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
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
                        title: Text(
                          trxIdToShow,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                            _showTransactionActions(transaksi);
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
