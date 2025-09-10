import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import '../../data/models/cart_item.dart';
import '../widgets/receipt_widget_builder.dart';

class ReceiptPreviewPage extends StatefulWidget {
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

  const ReceiptPreviewPage({
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
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  ReceiptController? _controller;
  bool _isReady = false;

  Future<void> _selectAndPrint() async {
    if (_controller == null) return;

    final device = await FlutterBluetoothPrinter.selectDevice(context);
    if (device != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Mencetak ke ${device.name}...')));
      await _controller!.print(address: device.address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview & Cetak Struk')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Receipt(
                    builder: (context) => buildReceiptContent(widget),
                    onInitialized: (controller) {
                      _controller = controller;
                      controller.paperSize =
                          PaperSize.mm80; // ukuran kertas 80mm
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _isReady = true);
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isReady ? _selectAndPrint : null,
                icon: const Icon(Icons.print_outlined),
                label: const Text('Pilih Printer & Cetak'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
