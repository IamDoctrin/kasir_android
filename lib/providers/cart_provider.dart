import 'package:flutter/foundation.dart';

import '../data/entities/produk.dart';
import '../data/models/cart_item.dart';

class CartProvider with ChangeNotifier {
  // Menggunakan Map untuk akses cepat berdasarkan ID produk
  final Map<int, CartItem> _items = {};

  // PPN 10%
  static const double _ppnRate = 0.10;
  bool _isPpnEnabled = true;

  // Getters untuk mengakses data dari luar
  Map<int, CartItem> get items => {..._items};
  bool get isPpnEnabled => _isPpnEnabled;

  int get totalItems => _items.length;

  int get subtotal {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.produk.harga * cartItem.kuantitas;
    });
    return total;
  }

  int get ppnAmount {
    if (_isPpnEnabled) {
      return (subtotal * _ppnRate).round();
    }
    return 0;
  }

  int get grandTotal => subtotal + ppnAmount;

  // Method untuk memanipulasi keranjang
  void addItem(Produk produk) {
    if (_items.containsKey(produk.id)) {
      // jika sudah ada, tambah jumlah item
      _items.update(
        produk.id!,
        (existingItem) => CartItem(
          produk: existingItem.produk,
          kuantitas: existingItem.kuantitas + 1,
        ),
      );
    } else {
      // jika belum ada, tambahkan item baru
      _items.putIfAbsent(produk.id!, () => CartItem(produk: produk));
    }
    notifyListeners();
  }

  void removeSingleItem(int produkId) {
    if (!_items.containsKey(produkId)) return;

    if (_items[produkId]!.kuantitas > 1) {
      _items.update(
        produkId,
        (existingItem) => CartItem(
          produk: existingItem.produk,
          kuantitas: existingItem.kuantitas - 1,
        ),
      );
    } else {
      _items.remove(produkId);
    }
    notifyListeners();
  }

  void removeItem(int produkId) {
    _items.remove(produkId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void togglePpn() {
    _isPpnEnabled = !_isPpnEnabled;
    notifyListeners();
  }

  void loadFromCartItems(List<CartItem> items) {
    _items.clear();
    for (var item in items) {
      _items[item.produk.id!] = item;
    }
    notifyListeners();
  }
}
