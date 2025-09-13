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

class _DaftarTransaksiPageState extends State<DaftarTransaksiPage>
    with WidgetsBindingObserver {
  late Future<List<Transaksi>> _transaksiFuture;

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

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
    WidgetsBinding.instance.addObserver(this);
    _setFilterToToday();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _runFilter();
      _syncWidgetKey.currentState?.loadLastSyncTime();
    }
  }

  void _runFilter() {
    setState(() {
      final startMillis =
          DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
          ).millisecondsSinceEpoch;
      final endMillis =
          DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            23,
            59,
            59,
          ).millisecondsSinceEpoch;
      _transaksiFuture = DatabaseInstance.database.then(
        (db) =>
            db.transaksiDao.findTransaksiByDateRange(startMillis, endMillis),
      );
    });
  }

  void _setFilterToToday() {
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _runFilter();
  }

  void _setFilterToYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    _startDate = yesterday;
    _endDate = yesterday;
    _runFilter();
  }

  void _setFilterToThisWeek() {
    final now = DateTime.now();
    _startDate = now.subtract(Duration(days: now.weekday - 1));
    _endDate = _startDate.add(const Duration(days: 6));
    _runFilter();
  }

  void _setFilterToThisMonth() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _runFilter();
  }

  void _setFilterToLastMonth() {
    final now = DateTime.now();
    final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    _endDate = firstDayOfCurrentMonth.subtract(const Duration(days: 1));
    _startDate = DateTime(_endDate.year, _endDate.month, 1);
    _runFilter();
  }

  Future<void> _selectCustomDateRange() async {
    final pickedStartDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'TANGGAL AWAL',
    );

    if (pickedStartDate == null) return;
    if (!mounted) return;

    final pickedEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: pickedStartDate,
      lastDate: DateTime.now(),
      helpText: 'TANGGAL AKHIR',
    );

    if (pickedEndDate == null) return;

    setState(() {
      _startDate = pickedStartDate;
      _endDate = pickedEndDate;
    });
    _runFilter();
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
    final produkMap = {for (var p in allProduk) p.id!: p};

    final items =
        details.map((detail) {
          return CartItem(
            produk: produkMap[detail.produkId]!,
            kuantitas: detail.kuantitas,
          );
        }).toList();

    final paymentAmount =
        (transaksi.jumlahBayar ?? transaksi.grandTotal).toDouble();
    final changeAmount = (transaksi.jumlahKembali ?? 0).toDouble();

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
                change: changeAmount,
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
            content: Text('Anda yakin ingin menghapus transaksi ini?'),
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
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                const SnackBar(content: Text('Mengunduh data dari server...')),
              );

              final resultMessage =
                  await ApiService().ambilDanSimpanTransaksiDariWeb();

              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(resultMessage),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              _setFilterToToday();
            },
            tooltip: 'Download Data dari Server',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);

              messenger.showSnackBar(
                const SnackBar(content: Text('Memulai sinkronisasi...')),
              );

              final result = await ApiService().sinkronkanTransaksiTertunda();

              _syncWidgetKey.currentState?.loadLastSyncTime();

              if (mounted) {
                if (result.failureCount > 0) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        '${result.failureCount} transaksi gagal disinkronkan.',
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
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _setFilterToToday,
                  child: const Text('Hari Ini'),
                ),
                ElevatedButton(
                  onPressed: _setFilterToYesterday,
                  child: const Text('Kemarin'),
                ),
                ElevatedButton(
                  onPressed: _setFilterToThisWeek,
                  child: const Text('Minggu Ini'),
                ),
                ElevatedButton(
                  onPressed: _setFilterToThisMonth,
                  child: const Text('Bulan Ini'),
                ),
                ElevatedButton(
                  onPressed: _setFilterToLastMonth,
                  child: const Text('Bulan Lalu'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Pilih Tanggal'),
                  onPressed: _selectCustomDateRange,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 4.0,
            ),
            child: Text(
              'Menampilkan periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const Divider(height: 1),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tidak ada transaksi pada periode ini.',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '(${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
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

                    String displayTitle;
                    if (isOpen) {
                      if (transaksi.lokasiMeja == 'Bungkus') {
                        displayTitle = 'PESANAN BUNGKUS';
                      } else {
                        displayTitle =
                            'PESANAN Meja ${transaksi.lokasiMeja ?? ''} No. ${transaksi.nomorMeja ?? ''}'
                                .trim();
                      }
                    } else {
                      displayTitle =
                          transaksi.nomorTransaksi ??
                          'TRX-${transaksi.id.toString().padLeft(7, '0')}';
                    }

                    String subtitleText;
                    if (transaksi.lokasiMeja == 'Bungkus') {
                      subtitleText =
                          '${dateFormatter.format(transaksi.waktuTransaksi)} • Bungkus • ${transaksi.metodePembayaran ?? ''}';
                    } else {
                      subtitleText =
                          '${dateFormatter.format(transaksi.waktuTransaksi)} • ${transaksi.lokasiMeja ?? ''} - Meja ${transaksi.nomorMeja ?? ''} • ${transaksi.metodePembayaran ?? ''}';
                    }

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
                              displayTitle,
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
                          subtitleText.replaceAll(' • •', ' •').trim(),
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
