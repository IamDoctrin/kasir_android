import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/entities/produk.dart';
import '../../providers/cart_provider.dart';

class ProductPosCard extends StatelessWidget {
  final Produk produk;

  const ProductPosCard({super.key, required this.produk});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama Produk
            Expanded(
              child: Text(
                produk.nama,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Harga
            Text(
              currencyFormatter.format(produk.harga),
              style: TextStyle(color: Colors.green[700], fontSize: 14),
            ),
            const SizedBox(height: 8),
            // Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    cart.removeSingleItem(produk.id!);
                  },
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                ),
                // menampilkan kuantitas dari CartProvider
                Consumer<CartProvider>(
                  builder: (ctx, cartData, _) {
                    final itemInCart = cartData.items[produk.id];
                    return Text(
                      itemInCart?.kuantitas.toString() ?? '0',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () {
                    cart.addItem(produk);
                  },
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
