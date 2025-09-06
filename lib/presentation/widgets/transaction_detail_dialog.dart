import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/entities/transaksi.dart';
import '../../data/models/cart_item.dart';

class TransactionDetailDialog extends StatelessWidget {
  final Transaksi transaksi;
  final List<CartItem> items;
  final VoidCallback onPrintReceipt;

  const TransactionDetailDialog({
    super.key,
    required this.transaksi,
    required this.items,
    required this.onPrintReceipt,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return AlertDialog(
      title: Text('Detail Transaksi #${transaksi.nomorTransaksi}'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              dense: true,
              leading: const Icon(Icons.table_restaurant_outlined, size: 20),
              title: Text(
                '${transaksi.lokasiMeja ?? ''} - Meja ${transaksi.nomorMeja ?? ''}',
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.payment_outlined, size: 20),
              title: Text(transaksi.metodePembayaran ?? 'N/A'),
            ),
            const Divider(),

            // Daftar Item
            Expanded(
              child:
                  items.isEmpty
                      ? const Center(
                        child: Text('Tidak ada item dalam transaksi ini.'),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (ctx, index) {
                          final item = items[index];
                          return ListTile(
                            title: Text(item.produk.nama),
                            subtitle: Text(
                              '${item.kuantitas} x ${currencyFormatter.format(item.produk.harga)}',
                            ),
                            trailing: Text(
                              currencyFormatter.format(
                                item.produk.harga * item.kuantitas,
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const Divider(),
            // Rincian Total
            _buildSummaryRow(
              'Subtotal',
              currencyFormatter.format(transaksi.subtotal),
            ),
            _buildSummaryRow(
              'PPN (10%)',
              currencyFormatter.format(transaksi.ppnJumlah),
            ),
            const Divider(thickness: 1.5),
            _buildSummaryRow(
              'Grand Total',
              currencyFormatter.format(
                transaksi.subtotal + transaksi.ppnJumlah,
              ),
              isTotal: true,
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
          label: const Text('Cetak Ulang'),
          onPressed: onPrintReceipt,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final style = TextStyle(
      fontSize: isTotal ? 16 : 14,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
