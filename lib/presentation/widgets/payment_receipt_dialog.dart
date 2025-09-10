import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:intl/intl.dart';
import '../../data/models/cart_item.dart';

class ReceiptDialog extends StatefulWidget {
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

  @override
  State<ReceiptDialog> createState() => _ReceiptDialogState();
}

class _ReceiptDialogState extends State<ReceiptDialog> {
  ReceiptController? receiptController;

  Future<void> _selectAndPrint() async {
    final device = await FlutterBluetoothPrinter.selectDevice(context);

    if (device != null) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mencetak ke ${device.name}...')),
        );
        receiptController?.print(address: device.address);
      });
    }
  }

  Widget _buildReceipt() {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    const smallStyle = TextStyle(fontSize: 18, color: Colors.black);
    const normalStyle = TextStyle(fontSize: 22, color: Colors.black);
    const boldStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Gulai Kambiang Kakek',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Center(
            child: Text('JL Lintas Padang - Solok', style: smallStyle),
          ),
          const Center(child: Text('HP: 0813 6345 4213', style: smallStyle)),
          const Divider(height: 24, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('No: ${widget.nomorTransaksi}', style: normalStyle),
              Text(formatter.format(now), style: normalStyle),
            ],
          ),
          const Divider(height: 24, color: Colors.black),
          for (var item in widget.cartItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.kuantitas}x ${item.produk.nama}',
                      style: normalStyle,
                    ),
                  ),
                  Text(
                    formatCurrency.format(item.produk.harga * item.kuantitas),
                    style: normalStyle,
                  ),
                ],
              ),
            ),
          const Divider(height: 24, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: normalStyle),
              Text(formatCurrency.format(widget.subtotal), style: normalStyle),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('PPN (11%)', style: normalStyle),
              Text(formatCurrency.format(widget.ppnAmount), style: normalStyle),
            ],
          ),
          const Divider(height: 24, thickness: 2, color: Colors.black),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: boldStyle),
              Text(formatCurrency.format(widget.totalAmount), style: boldStyle),
            ],
          ),
          const Divider(height: 24, thickness: 1, color: Colors.black54),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bayar', style: normalStyle),
              Text(
                formatCurrency.format(widget.paymentAmount),
                style: normalStyle,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kembali', style: normalStyle),
              Text(formatCurrency.format(widget.change), style: normalStyle),
            ],
          ),
          const SizedBox(height: 24),
          const Center(child: Text('Terima Kasih!', style: boldStyle)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transaksi Berhasil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transaksi #${widget.nomorTransaksi} telah berhasil disimpan.',
            ),
            SizedBox(
              width: 0,
              height: 0,
              child: Receipt(
                builder: (context) => _buildReceipt(),
                onInitialized: (controller) {
                  if (!mounted) return;
                  controller.paperSize = PaperSize.mm80; //ukuran kertas 80mm
                  setState(() {
                    this.receiptController = controller;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('Cetak Struk'),
          onPressed: receiptController != null ? _selectAndPrint : null,
        ),
      ],
    );
  }
}
