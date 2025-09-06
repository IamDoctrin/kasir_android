import '../entities/produk.dart';

class CartItem {
  final Produk produk;
  int kuantitas;

  CartItem({required this.produk, this.kuantitas = 1});
}
