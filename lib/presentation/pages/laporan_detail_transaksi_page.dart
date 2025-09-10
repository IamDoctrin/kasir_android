import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/database_instance.dart';
import '../../data/entities/transaksi.dart';
import '../../data/models/cart_item.dart';

class TransactionWithDetails {
  final Transaksi transaction;
  final List<CartItem> items;

  TransactionWithDetails({required this.transaction, required this.items});
}

class LaporanDetailTransaksiPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const LaporanDetailTransaksiPage({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<LaporanDetailTransaksiPage> createState() =>
      _LaporanDetailTransaksiPageState();
}

class _LaporanDetailTransaksiPageState
    extends State<LaporanDetailTransaksiPage> {
  late Future<List<TransactionWithDetails>> _laporanFuture;
  late DateTime _currentStartDate;
  late DateTime _currentEndDate;
  String? _selectedPaymentMethod;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

  @override
  void initState() {
    super.initState();
    _currentStartDate = widget.startDate;
    _currentEndDate = widget.endDate;
    _loadLaporan();
  }

  void _loadLaporan() {
    setState(() {
      _laporanFuture = _fetchDetailedTransactions();
    });
  }

  Future<List<TransactionWithDetails>> _fetchDetailedTransactions() async {
    final db = await DatabaseInstance.database;
    final startMillis =
        DateTime(
          _currentStartDate.year,
          _currentStartDate.month,
          _currentStartDate.day,
        ).millisecondsSinceEpoch;
    final endMillis =
        DateTime(
          _currentEndDate.year,
          _currentEndDate.month,
          _currentEndDate.day,
          23,
          59,
          59,
        ).millisecondsSinceEpoch;

    final transactions = await db.transaksiDao.findTransaksiByDateRange(
      startMillis,
      endMillis,
    );

    final filteredTransactions =
        _selectedPaymentMethod == null
            ? transactions
            : transactions
                .where((trx) => trx.metodePembayaran == _selectedPaymentMethod)
                .toList();

    final allProduk = await db.produkDao.findAllProduk();
    final produkMap = {for (var p in allProduk) p.id!: p};

    List<TransactionWithDetails> detailedList = [];

    for (var trx in filteredTransactions) {
      final details = await db.detailTransaksiDao.findDetailByTransaksiId(
        trx.id!,
      );
      final items =
          details.map((d) {
            return CartItem(
              produk: produkMap[d.produkId]!,
              kuantitas: d.kuantitas,
            );
          }).toList();
      detailedList.add(TransactionWithDetails(transaction: trx, items: items));
    }
    return detailedList.reversed.toList();
  }

  void _setFilterToToday() {
    final now = DateTime.now();
    _currentStartDate = now;
    _currentEndDate = now;
    _loadLaporan();
  }

  void _setFilterToThisWeek() {
    final now = DateTime.now();
    _currentStartDate = now.subtract(Duration(days: now.weekday - 1));
    _currentEndDate = _currentStartDate.add(const Duration(days: 6));
    _loadLaporan();
  }

  void _setFilterToThisMonth() {
    final now = DateTime.now();
    _currentStartDate = DateTime(now.year, now.month, 1);
    _currentEndDate = DateTime(now.year, now.month + 1, 0);
    _loadLaporan();
  }

  void _onPaymentMethodSelected(String? method) {
    setState(() {
      if (_selectedPaymentMethod == method) {
        _selectedPaymentMethod = null;
      } else {
        _selectedPaymentMethod = method;
      }
    });
    _loadLaporan();
  }

  Future<void> _exportDetailToPdf(
    List<TransactionWithDetails> data,
    int subtotal,
    int totalPpn,
    int grandTotal,
  ) async {
    final doc = pw.Document();
    final periode =
        'Periode: ${DateFormat('dd MMM yyyy').format(_currentStartDate)} - ${DateFormat('dd MMM yyyy').format(_currentEndDate)}';

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/rm_logo.png')).buffer.asUint8List(),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.SizedBox(
                      height: 30,
                      width: 30,
                      child: pw.Image(logoImage),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'Laporan Detail Transaksi',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                pw.Text(periode),
                if (_selectedPaymentMethod != null)
                  pw.Text('Metode Pembayaran: $_selectedPaymentMethod'),
                pw.SizedBox(height: 10),
              ],
            ),
        build: (context) {
          List<pw.Widget> widgets = [
            ...data.map((trxWithDetails) {
              final transaksi = trxWithDetails.transaction;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 15),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      transaksi.nomorTransaksi ?? 'N/A',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      '${dateFormatter.format(transaksi.waktuTransaksi)}',
                    ),
                    pw.Text('Metode: ${transaksi.metodePembayaran}'),
                    pw.Divider(),
                    for (var item in trxWithDetails.items)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('${item.kuantitas}x ${item.produk.nama}'),
                          pw.Text(
                            currencyFormatter.format(
                              item.produk.harga * item.kuantitas,
                            ),
                          ),
                        ],
                      ),
                    pw.Divider(),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text('Subtotal: '),
                              pw.Text(
                                currencyFormatter.format(transaksi.subtotal),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text('PPN: '),
                              pw.Text(
                                currencyFormatter.format(transaksi.ppnJumlah),
                              ),
                            ],
                          ),
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text(
                                'Grand Total: ',
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                currencyFormatter.format(transaksi.grandTotal),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ];

          widgets.add(pw.Divider(height: 20));
          widgets.add(
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Keseluruhan Tanpa PPN: ${currencyFormatter.format(subtotal)}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.Text(
                    'Total Keseluruhan PPN: ${currencyFormatter.format(totalPpn)}',
                    style: pw.TextStyle(fontSize: 16),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Grand Total Keseluruhan: ${currencyFormatter.format(grandTotal)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );

          return widgets;
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Detail Transaksi'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _setFilterToToday,
                  child: const Text('Hari Ini'),
                ),
                ElevatedButton(
                  onPressed: _setFilterToThisWeek,
                  child: const Text('Minggu Ini'),
                ),
                ElevatedButton(
                  onPressed: _setFilterToThisMonth,
                  child: const Text('Bulan Ini'),
                ),
                const VerticalDivider(),
                FilterChip(
                  label: const Text('Cash'),
                  selected: _selectedPaymentMethod == 'Cash',
                  onSelected: (selected) => _onPaymentMethodSelected('Cash'),
                ),
                FilterChip(
                  label: const Text('Transfer'),
                  selected: _selectedPaymentMethod == 'Transfer',
                  onSelected:
                      (selected) => _onPaymentMethodSelected('Transfer'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TransactionWithDetails>>(
              future: _laporanFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada transaksi pada periode ini.'),
                  );
                }
                final laporanList = snapshot.data!;

                final totalSubtotal = laporanList.fold<int>(
                  0,
                  (sum, item) => sum + item.transaction.subtotal,
                );
                final totalPpn = laporanList.fold<int>(
                  0,
                  (sum, item) => sum + item.transaction.ppnJumlah,
                );
                final grandTotal = totalSubtotal + totalPpn;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Ringkasan Detail Laporan',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Periode:'),
                                  Text(
                                    '${DateFormat('dd MMM yyyy').format(_currentStartDate)} - ${DateFormat('dd MMM yyyy').format(_currentEndDate)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Tanpa PPN:'),
                                  Text(
                                    currencyFormatter.format(totalSubtotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total PPN:'),
                                  Text(
                                    currencyFormatter.format(totalPpn),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Grand Total:'),
                                  Text(
                                    currencyFormatter.format(grandTotal),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _exportDetailToPdf(
                                        laporanList,
                                        totalSubtotal,
                                        totalPpn,
                                        grandTotal,
                                      ),
                                  icon: const Icon(Icons.print),
                                  label: const Text('Cetak Laporan'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: laporanList.length,
                        itemBuilder: (context, index) {
                          final trxWithDetails = laporanList[index];
                          final transaksi = trxWithDetails.transaction;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                child: Text((index + 1).toString()),
                              ),
                              title: Text(
                                transaksi.nomorTransaksi ?? 'N/A',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${dateFormatter.format(transaksi.waktuTransaksi)} • ${transaksi.metodePembayaran}',
                              ),
                              trailing: Text(
                                currencyFormatter.format(transaksi.grandTotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              children: [
                                ...trxWithDetails.items.map((item) {
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      '${item.kuantitas}x ${item.produk.nama}',
                                    ),
                                    trailing: Text(
                                      currencyFormatter.format(
                                        item.produk.harga * item.kuantitas,
                                      ),
                                    ),
                                  );
                                }),

                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Subtotal:'),
                                          Text(
                                            currencyFormatter.format(
                                              transaksi.subtotal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('PPN:'),
                                          Text(
                                            currencyFormatter.format(
                                              transaksi.ppnJumlah,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Total:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            currencyFormatter.format(
                                              transaksi.grandTotal,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
