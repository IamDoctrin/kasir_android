import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../pages/receipt_preview_page.dart';

Widget buildReceiptContent(ReceiptPreviewPage widget) {
  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final now = DateTime.now();
  final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');

  const regularSize = 24.0;
  const mediumSize = 25.0;

  const regular = TextStyle(fontSize: regularSize, color: Colors.black);
  const medium = TextStyle(fontSize: mediumSize, color: Colors.black);
  const mediumBold = TextStyle(
    fontSize: mediumSize,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  return Container(
    color: Colors.white,
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/rm_logo.png',
          width: 300,
          height: 200,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 1),
        const Text('JL Lintas Padang - Solok Selasih', style: regular),
        const Text('HP: 0813 6345 4213', style: regular),
        const Divider(color: Colors.black, height: 24),
        Table(
          columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
          children: [
            TableRow(
              children: [
                Text('No: ${widget.nomorTransaksi}', style: regular),
                Text(
                  formatter.format(now),
                  style: regular,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            TableRow(
              children: [
                Text(
                  'Meja: ${widget.lokasiMeja} - ${widget.nomorMeja}',
                  style: regular,
                ),
                Text(
                  widget.metodePembayaran,
                  style: regular,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const TableRow(
              children: [
                Divider(color: Colors.black, height: 24),
                Divider(color: Colors.black, height: 24),
              ],
            ),
            for (var item in widget.cartItems)
              TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.produk.nama,
                            style: regular,
                            softWrap: true,
                            maxLines: 2,
                          ),
                          Text(
                            '  ${item.kuantitas} x ${formatCurrency.format(item.produk.harga)}',
                            style: medium,
                            softWrap: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.bottom,
                    child: Text(
                      formatCurrency.format(item.produk.harga * item.kuantitas),
                      style: medium,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            const TableRow(
              children: [
                Divider(color: Colors.black, height: 24),
                Divider(color: Colors.black, height: 24),
              ],
            ),
            TableRow(
              children: [
                const Text('Subtotal', style: medium),
                Text(
                  formatCurrency.format(widget.subtotal),
                  style: medium,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            TableRow(
              children: [
                const Text('PPN (10%)', style: medium),
                Text(
                  formatCurrency.format(widget.ppnAmount),
                  style: medium,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            const TableRow(
              children: [
                Divider(color: Colors.black, height: 24, thickness: 1.5),
                Divider(color: Colors.black, height: 24, thickness: 1.5),
              ],
            ),
            TableRow(
              children: [
                const Text('TOTAL', style: mediumBold),
                Text(
                  formatCurrency.format(widget.totalAmount),
                  style: mediumBold,
                  textAlign: TextAlign.right,
                ),
              ],
            ),

            const TableRow(
              children: [
                Divider(height: 24, thickness: 1, color: Colors.black54),
                Divider(height: 24, thickness: 1, color: Colors.black54),
              ],
            ),
            TableRow(
              children: [
                const Text('Bayar', style: medium),
                Text(
                  formatCurrency.format(widget.paymentAmount),
                  style: medium,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
            TableRow(
              children: [
                const Text('Kembali', style: medium),
                Text(
                  formatCurrency.format(widget.change),
                  style: medium,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('--------------------', style: mediumBold),
        const Text('--- Terima Kasih ---', style: mediumBold),
        const Text('--------------------', style: mediumBold),
      ],
    ),
  );
}
