import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database_instance.dart';
import '../../data/models/sales_report_item.dart';

class _ReportData {
  final List<SalesReportItem> items;
  final int totalPenjualan;
  _ReportData({required this.items, required this.totalPenjualan});
}

class LaporanPenjualanPage extends StatefulWidget {
  const LaporanPenjualanPage({super.key});

  @override
  State<LaporanPenjualanPage> createState() => _LaporanPenjualanPageState();
}

class _LaporanPenjualanPageState extends State<LaporanPenjualanPage> {
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  Future<_ReportData>? _reportFuture;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormatter = DateFormat('dd-MM-yyyy');

  @override
  void initState() {
    super.initState();
    _setFilterToToday();
  }

  void _generateReport() {
    setState(() {
      _reportFuture = _calculateReport();
    });
  }

  Future<_ReportData> _calculateReport() async {
    final db = await DatabaseInstance.database;
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

    const sql = '''
      SELECT
        P.nama AS namaProduk,
        SUM(DT.kuantitas) as totalKuantitas,
        SUM(DT.kuantitas * DT.harga_saat_transaksi) as totalPendapatan
      FROM DetailTransaksi AS DT
      INNER JOIN Produk AS P ON P.id = DT.produk_id
      INNER JOIN Transaksi AS T ON T.id = DT.transaksi_id
      WHERE T.status = 'Closed' AND T.waktu_transaksi BETWEEN ? AND ?
      GROUP BY P.nama
      ORDER BY totalPendapatan DESC
    ''';

    final result = await db.database.rawQuery(sql, [startMillis, endMillis]);

    final reportList =
        result.map((row) {
          return SalesReportItem(
            namaProduk: row['namaProduk'] as String,
            totalKuantitas: (row['totalKuantitas'] as num).toInt(),
            totalPendapatan: (row['totalPendapatan'] as num).toInt(),
          );
        }).toList();

    final totalPendapatan = reportList.fold<int>(
      0,
      (sum, item) => sum + item.totalPendapatan,
    );

    return _ReportData(items: reportList, totalPenjualan: totalPendapatan);
  }

  Future<void> _exportToPdf(List<SalesReportItem> data, int total) async {
    final doc = pw.Document();
    final periode =
        'Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Laporan Penjualan - Gulai Kambiang Kakek',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.Text(periode),
              pw.SizedBox(height: 10),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              headers: [
                'No',
                'Nama Menu',
                'Jumlah Terjual',
                'Total Pendapatan',
              ],
              data: List<List<String>>.generate(
                data.length,
                (index) => [
                  (index + 1).toString(),
                  data[index].namaProduk,
                  '${data[index].totalKuantitas} Porsi',
                  currencyFormatter.format(data[index].totalPendapatan),
                ],
              ),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {3: pw.Alignment.centerRight},
            ),
            pw.Divider(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'TOTAL PENJUALAN: ',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                pw.Text(
                  currencyFormatter.format(total),
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> _exportToExcel(List<SalesReportItem> data, int total) async {
    final excel = Excel.createExcel();
    final sheet = excel['Laporan Penjualan'];
    sheet.appendRow([
      TextCellValue('Laporan Penjualan - Gulai Kambiang Kakek'),
    ]);
    sheet.appendRow([
      TextCellValue(
        'Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
      ),
    ]);
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue('No'),
      TextCellValue('Nama Menu'),
      TextCellValue('Jumlah Terjual'),
      TextCellValue('Total Pendapatan'),
    ]);
    for (var i = 0; i < data.length; i++) {
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(data[i].namaProduk),
        IntCellValue(data[i].totalKuantitas),
        IntCellValue(data[i].totalPendapatan),
      ]);
    }
    sheet.appendRow([]);
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue(''),
      TextCellValue('TOTAL PENJUALAN'),
      IntCellValue(total),
    ]);
    final fileBytes = excel.save();
    if (fileBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'laporan_penjualan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Berikut adalah laporan penjualan.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengekspor file: $e')));
      }
    }
  }

  void _setFilterToToday() {
    final now = DateTime.now();
    _startDate = now;
    _endDate = now;
    _generateReport();
  }

  void _setFilterToThisWeek() {
    final now = DateTime.now();
    _startDate = now.subtract(Duration(days: now.weekday - 1));
    _endDate = _startDate.add(const Duration(days: 6));
    _generateReport();
  }

  void _setFilterToThisMonth() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
    _generateReport();
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

    await Future.delayed(const Duration(milliseconds: 100));
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
    _generateReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: Colors.brown[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Pilih Tanggal'),
                      onPressed: _selectCustomDateRange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<_ReportData>(
                future: _reportFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.items.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada data penjualan pada periode ini.'),
                    );
                  }

                  final reportData = snapshot.data!;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LAPORAN PENJUALAN',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Periode: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed:
                                () => _exportToPdf(
                                  reportData.items,
                                  reportData.totalPenjualan,
                                ),
                            icon: const Icon(Icons.print),
                            label: const Text('PDF'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red[400],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed:
                                () => _exportToExcel(
                                  reportData.items,
                                  reportData.totalPenjualan,
                                ),
                            icon: const Icon(Icons.table_chart),
                            label: const Text('Excel'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Colors.brown[100],
                            ),
                            columns: const [
                              DataColumn(label: Text('No')),
                              DataColumn(label: Text('Nama Menu')),
                              DataColumn(label: Text('Jml Terjual')),
                              DataColumn(label: Text('Total'), numeric: true),
                            ],
                            rows: List<DataRow>.generate(
                              reportData.items.length,
                              (index) {
                                final item = reportData.items[index];
                                return DataRow(
                                  cells: [
                                    DataCell(Text((index + 1).toString())),
                                    DataCell(Text(item.namaProduk)),
                                    DataCell(
                                      Text('${item.totalKuantitas} Porsi'),
                                    ),
                                    DataCell(
                                      Text(
                                        currencyFormatter.format(
                                          item.totalPendapatan,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )..add(
                              DataRow(
                                cells: [
                                  const DataCell(Text('')),
                                  const DataCell(Text('')),
                                  const DataCell(
                                    Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(
                                        reportData.totalPenjualan,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
