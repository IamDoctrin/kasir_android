import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/database_instance.dart';
import '../../data/entities/detail_transaksi.dart';
import '../../data/entities/transaksi.dart';
import '../../data/models/cart_item.dart';
import '../../providers/cart_provider.dart';
import 'currency_input_formatter.dart';

class PaymentDialog extends StatefulWidget {
  final CartProvider cart;
  final VoidCallback onTransactionSuccess;
  final int? editingTransactionId;
  final String lokasiMeja;
  final int nomorMeja;

  const PaymentDialog({
    super.key,
    required this.cart,
    required this.onTransactionSuccess,
    this.editingTransactionId,
    required this.lokasiMeja,
    required this.nomorMeja,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _paymentController = TextEditingController();
  double _change = 0.0;
  String _selectedPaymentMethod = 'Cash';

  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _paymentController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final cleanString = _paymentController.text.replaceAll('.', '');
    final paymentAmount = double.tryParse(cleanString) ?? 0.0;
    setState(() {
      _change = paymentAmount - widget.cart.grandTotal;
    });
  }

  void _setQuickCash(double amount) {
    _paymentController.text = NumberFormat.decimalPattern(
      'id_ID',
    ).format(amount);
  }

  Future<void> _processPayment() async {
    final cleanString = _paymentController.text.replaceAll('.', '');
    final paymentAmount = double.tryParse(cleanString) ?? 0.0;

    if (paymentAmount < widget.cart.grandTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah pembayaran tidak cukup!')),
      );
      return;
    }

    final currentContext = context;
    final db = await DatabaseInstance.database;
    int finalTransactionId;

    final List<CartItem> itemsForReceipt = widget.cart.items.values.toList();
    final int subtotalForReceipt = widget.cart.subtotal;
    final int ppnForReceipt = widget.cart.ppnAmount;
    final int totalForReceipt = widget.cart.grandTotal;

    final now = DateTime.now();
    String nomorTransaksiValue;

    if (widget.editingTransactionId == null) {
      nomorTransaksiValue = await db.transaksiDao.generateNewTransactionNumber(
        db,
      );
    } else {
      final existingTrx = await db.transaksiDao.findTransaksiById(
        widget.editingTransactionId!,
      );
      nomorTransaksiValue = existingTrx?.nomorTransaksi ?? '';
    }

    final trx = Transaksi(
      id: widget.editingTransactionId,
      waktuTransaksi: now,
      subtotal: subtotalForReceipt,
      diskon: 0,
      ppnPersentase: widget.cart.isPpnEnabled ? 11.0 : 0.0,
      ppnJumlah: ppnForReceipt,
      grandTotal: subtotalForReceipt,
      status: 'Closed',
      lokasiMeja: widget.lokasiMeja,
      nomorMeja: widget.nomorMeja,
      metodePembayaran: _selectedPaymentMethod,
      nomorTransaksi: nomorTransaksiValue,
    );

    if (widget.editingTransactionId == null) {
      final newId = await db.transaksiDao.insertTransaksi(trx);
      if (newId == null) return;
      finalTransactionId = newId;
    } else {
      await db.transaksiDao.updateTransaksi(trx);
      finalTransactionId = widget.editingTransactionId!;
      await db.detailTransaksiDao.deleteDetailByTransaksiId(finalTransactionId);
    }

    for (var item in itemsForReceipt) {
      final detail = DetailTransaksi(
        transaksiId: finalTransactionId,
        produkId: item.produk.id!,
        kuantitas: item.kuantitas,
        hargaSaatTransaksi: item.produk.harga,
      );
      await db.detailTransaksiDao.insertDetailTransaksi(detail);
    }

    if (!currentContext.mounted) return;

    Navigator.of(currentContext).pop();

    await showDialog(
      context: currentContext,
      builder:
          (context) => ReceiptDialog(
            transactionId: finalTransactionId,
            nomorTransaksi: nomorTransaksiValue,
            cartItems: itemsForReceipt,
            subtotal: subtotalForReceipt,
            ppnAmount: ppnForReceipt,
            totalAmount: totalForReceipt,
            paymentAmount: paymentAmount,
            change: _change,
            lokasiMeja: widget.lokasiMeja,
            nomorMeja: widget.nomorMeja,
            metodePembayaran: _selectedPaymentMethod,
          ),
    );

    widget.onTransactionSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.cart.grandTotal;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Pembayaran'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: 400,
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'Cash',
                          label: Text('Cash'),
                          icon: Icon(Icons.money),
                        ),
                        ButtonSegment(
                          value: 'Transfer',
                          label: Text('Transfer'),
                          icon: Icon(Icons.qr_code),
                        ),
                      ],
                      selected: {_selectedPaymentMethod},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedPaymentMethod = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      'Total Belanja:',
                      formatCurrency.format(totalAmount),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _paymentController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Bayar',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow(
                      'Kembalian:',
                      formatCurrency.format(_change < 0 ? 0 : _change),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    const Text("Uang Pas/Cepat"),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children:
                          [
                                totalAmount.toDouble(),
                                ...[
                                  50000,
                                  100000,
                                  150000,
                                  200000,
                                ].where((a) => a > totalAmount),
                              ]
                              .map(
                                (amount) => ElevatedButton(
                                  onPressed:
                                      () => _setQuickCash(amount.toDouble()),
                                  child: Text(
                                    NumberFormat.decimalPattern(
                                      'id_ID',
                                    ).format(amount),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed:
              (_change >= 0 && _paymentController.text.isNotEmpty)
                  ? _processPayment
                  : null,
          child: const Text('Proses & Cetak Struk'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class ReceiptDialog extends StatelessWidget {
  final int transactionId;
  final String nomorTransaksi;
  final List<CartItem> cartItems;
  final int subtotal;
  final int ppnAmount;
  final int totalAmount;
  final double paymentAmount;
  final double change;
  final String lokasiMeja;
  final int nomorMeja;
  final String metodePembayaran;

  const ReceiptDialog({
    super.key,
    required this.transactionId,
    required this.nomorTransaksi,
    required this.cartItems,
    required this.subtotal,
    required this.ppnAmount,
    required this.totalAmount,
    required this.paymentAmount,
    required this.change,
    required this.lokasiMeja,
    required this.nomorMeja,
    required this.metodePembayaran,
  });

  Future<void> _printReceipt(BuildContext context) async {
    // Lebar 80mm, tinggi tak terbatas (karena kertas gulung), dengan margin 5mm di setiap sisi.
    final pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 5 * PdfPageFormat.mm,
    );

    final doc = pw.Document();

    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/rm_logo.png')).buffer.asUint8List(),
    );

    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.SizedBox(
                  width: 150, // ukuran logo
                  height: 60,
                  child: pw.Image(logoImage),
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Center(
                child: pw.Text(
                  'JL Lintas Padang - Solok, Lubuk Selasih',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'HP: 0813 6345 4213',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Text(
                'No. Transaksi: $nomorTransaksi',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Tanggal: ${formatter.format(now)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Meja: $lokasiMeja - $nomorMeja',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                'Pembayaran: $metodePembayaran',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),
              for (var item in cartItems)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${item.kuantitas}x ${item.produk.nama}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      pw.Text(
                        formatCurrency.format(
                          item.produk.harga * item.kuantitas,
                        ),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              pw.Divider(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    formatCurrency.format(subtotal),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PPN (10%)', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    formatCurrency.format(ppnAmount),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Divider(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    formatCurrency.format(totalAmount),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    formatCurrency.format(paymentAmount),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembali', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    formatCurrency.format(change),
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'Terima kasih!',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transaksi Berhasil'),
      content: Text('Transaksi #$nomorTransaksi telah berhasil disimpan.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('Cetak Struk'),
          onPressed: () => _printReceipt(context),
        ),
      ],
    );
  }
}
