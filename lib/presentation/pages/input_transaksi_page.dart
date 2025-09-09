import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/database_instance.dart';
import '../../data/entities/kategori.dart';
import '../../data/entities/produk.dart';
import '../../data/entities/transaksi.dart';
import '../../data/entities/detail_transaksi.dart';
import '../../data/models/cart_item.dart';
import '../../providers/cart_provider.dart';
import 'manajemen_menu_page.dart';
import '../widgets/payment_receipt_dialog.dart';
import '../widgets/payment_dialog_content.dart';

class InputTransaksiPage extends StatefulWidget {
  final int? editingTransactionId;
  const InputTransaksiPage({super.key, this.editingTransactionId});
  @override
  State<InputTransaksiPage> createState() => _InputTransaksiPageState();
}

class _InputTransaksiPageState extends State<InputTransaksiPage> {
  List<Produk> _produkList = [];
  List<Kategori> _kategoriList = [];
  int? _selectedCategoryId;
  String _selectedLokasi = 'Dalam';
  final _nomorMejaController = TextEditingController();
  final List<String> _lokasiOptions = ['Dalam', 'Luar', 'Bawah'];
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _nomorMejaController.dispose();
    super.dispose();
  }

  Future<void> _initializePage() async {
    await _refreshData();
    if (widget.editingTransactionId != null) {
      await _loadTransactionForEdit(widget.editingTransactionId!);
    }
  }

  Future<void> _loadTransactionForEdit(int trxId) async {
    final db = await DatabaseInstance.database;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final trx = await db.transaksiDao.findTransaksiById(trxId);
    if (trx == null) return;
    final details = await db.detailTransaksiDao.findDetailByTransaksiId(trxId);
    final allProduk = await db.produkDao.findAllProduk();
    final produkMap = {for (var p in allProduk) p.id: p};
    final itemsForCart =
        details.map((detail) {
          return CartItem(
            produk: produkMap[detail.produkId]!,
            kuantitas: detail.kuantitas,
          );
        }).toList();
    cart.loadFromCartItems(itemsForCart);
    setState(() {
      _selectedLokasi = trx.lokasiMeja ?? 'Dalam';
      _nomorMejaController.text = (trx.nomorMeja ?? 0).toString();
    });
  }

  Future<void> _refreshData() async {
    final db = await DatabaseInstance.database;
    final produk = await db.produkDao.findAllProduk();
    final kategori = await db.kategoriDao.findAllKategori();

    const desiredCategoryOrder = ['Makanan', 'Minuman', 'Extra'];
    final kategoriMap = {for (var k in kategori) k.id!: k.nama};

    produk.sort((a, b) {
      final kategoriA = kategoriMap[a.kategoriId] ?? '';
      final kategoriB = kategoriMap[b.kategoriId] ?? '';
      final indexA = desiredCategoryOrder.indexOf(kategoriA);
      final indexB = desiredCategoryOrder.indexOf(kategoriB);
      final categoryComparison = indexA.compareTo(indexB);
      if (categoryComparison != 0) {
        return categoryComparison;
      }
      return a.nama.compareTo(b.nama);
    });

    if (mounted) {
      setState(() {
        _produkList = produk;
        _kategoriList = kategori;
      });
    }
  }

  Future<void> _saveOpenTransaction() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.items.isEmpty) return;
    final db = await DatabaseInstance.database;
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
      waktuTransaksi: DateTime.now(),
      subtotal: cart.subtotal,
      diskon: 0,
      ppnPersentase: cart.isPpnEnabled ? 11.0 : 0.0,
      ppnJumlah: cart.ppnAmount,
      grandTotal: cart.grandTotal,
      status: 'Open',
      lokasiMeja: _selectedLokasi,
      nomorMeja: int.tryParse(_nomorMejaController.text) ?? 0,
      metodePembayaran: '',
      nomorTransaksi: nomorTransaksiValue,
      isSynced: 0,
    );

    // print('====================================================');
    // print('>>> DEBUG: DATA TRANSAKSI "OPEN" YANG AKAN DISIMPAN');
    // print('====================================================');
    // print('ID Transaksi: ${trx.id}');
    // print('Nomor Transaksi: ${trx.nomorTransaksi}');
    // print('Waktu: ${trx.waktuTransaksi}');
    // print('Status: ${trx.status}');
    // print('Subtotal: ${trx.subtotal}');
    // print('PPN Jumlah: ${trx.ppnJumlah}');
    // print('Grand Total: ${trx.grandTotal}');
    // print('Lokasi Meja: ${trx.lokasiMeja}');
    // print('Nomor Meja: ${trx.nomorMeja}');
    // print('Metode Pembayaran: ${trx.metodePembayaran}');
    // print('Is Synced: ${trx.isSynced}');
    // print('====================================================');

    if (widget.editingTransactionId == null) {
      final transactionId = await db.transaksiDao.insertTransaksi(trx);
      if (transactionId == null) return;
      for (var item in cart.items.values) {
        await db.detailTransaksiDao.insertDetailTransaksi(
          DetailTransaksi(
            transaksiId: transactionId,
            produkId: item.produk.id!,
            kuantitas: item.kuantitas,
            hargaSaatTransaksi: item.produk.harga,
          ),
        );
      }
    } else {
      await db.transaksiDao.updateTransaksi(trx);
      await db.detailTransaksiDao.deleteDetailByTransaksiId(
        widget.editingTransactionId!,
      );
      for (var item in cart.items.values) {
        await db.detailTransaksiDao.insertDetailTransaksi(
          DetailTransaksi(
            transaksiId: widget.editingTransactionId!,
            produkId: item.produk.id!,
            kuantitas: item.kuantitas,
            hargaSaatTransaksi: item.produk.harga,
          ),
        );
      }
    }
    cart.clearCart();
    if (mounted) Navigator.of(context).pop();
  }

  void _showCustomPaymentDialog(CartProvider cart) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Payment',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.black.withOpacity(0.5),
          resizeToAvoidBottomInset: false,
          body: Align(
            alignment: const Alignment(0.0, -0.4),
            child: PaymentDialogContent(
              cart: cart,
              onProcessPayment: (paymentMethod, paymentAmount) async {
                final currentContext = context;
                final db = await DatabaseInstance.database;
                int finalTransactionId;
                final List<CartItem> itemsForReceipt =
                    cart.items.values.toList();
                final int subtotalForReceipt = cart.subtotal;
                final int ppnForReceipt = cart.ppnAmount;
                final int totalForReceipt = cart.grandTotal;
                final now = DateTime.now();
                String nomorTransaksiValue;

                if (widget.editingTransactionId == null) {
                  nomorTransaksiValue = await db.transaksiDao
                      .generateNewTransactionNumber(db);
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
                  ppnPersentase: cart.isPpnEnabled ? 11.0 : 0.0,
                  ppnJumlah: ppnForReceipt,
                  grandTotal: totalForReceipt,
                  status: 'Closed',
                  lokasiMeja: _selectedLokasi,
                  nomorMeja: int.tryParse(_nomorMejaController.text) ?? 0,
                  metodePembayaran: paymentMethod,
                  nomorTransaksi: nomorTransaksiValue,
                );

                if (widget.editingTransactionId == null) {
                  final newId = await db.transaksiDao.insertTransaksi(trx);
                  if (newId == null) return;
                  finalTransactionId = newId;
                } else {
                  await db.transaksiDao.updateTransaksi(trx);
                  finalTransactionId = widget.editingTransactionId!;
                  await db.detailTransaksiDao.deleteDetailByTransaksiId(
                    finalTransactionId,
                  );
                }

                for (var item in itemsForReceipt) {
                  await db.detailTransaksiDao.insertDetailTransaksi(
                    DetailTransaksi(
                      transaksiId: finalTransactionId,
                      produkId: item.produk.id!,
                      kuantitas: item.kuantitas,
                      hargaSaatTransaksi: item.produk.harga,
                    ),
                  );
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
                        change: paymentAmount - totalForReceipt,
                        lokasiMeja: _selectedLokasi,
                        nomorMeja: int.tryParse(_nomorMejaController.text) ?? 0,
                        metodePembayaran: paymentMethod,
                      ),
                );

                cart.clearCart();
                if (widget.editingTransactionId != null &&
                    currentContext.mounted) {
                  Navigator.of(currentContext).pop();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(int kategoriId) {
    final namaKategori =
        _kategoriList
            .firstWhere(
              (k) => k.id == kategoriId,
              orElse: () => Kategori(id: 0, nama: ''),
            )
            .nama;
    switch (namaKategori.toLowerCase()) {
      case 'makanan':
        return Colors.orange;
      case 'minuman':
        return Colors.blue;
      case 'extra':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(int kategoriId) {
    final namaKategori =
        _kategoriList
            .firstWhere(
              (k) => k.id == kategoriId,
              orElse: () => Kategori(id: 0, nama: ''),
            )
            .nama;
    switch (namaKategori.toLowerCase()) {
      case 'makanan':
        return Icons.restaurant;
      case 'minuman':
        return Icons.local_drink;
      case 'extra':
        return Icons.add_circle;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final filteredProducts =
        _selectedCategoryId == null
            ? _produkList
            : _produkList
                .where((p) => p.kategoriId == _selectedCategoryId)
                .toList();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          widget.editingTransactionId == null
              ? 'Transaksi Baru'
              : 'Edit Transaksi',
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManajemenMenuPage(),
                ),
              );
              _refreshData();
            },
            tooltip: 'Kelola Menu',
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _buildTableSelector(),
                _buildCategorySelector(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product, cart);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: _buildCartSection()),
        ],
      ),
    );
  }

  Widget _buildTableSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: _selectedLokasi,
              decoration: const InputDecoration(
                labelText: 'Lokasi Meja',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
              ),
              items:
                  _lokasiOptions
                      .map(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedLokasi = newValue!;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: TextField(
              controller: _nomorMejaController,
              decoration: const InputDecoration(
                labelText: 'No. Meja',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final segments = <ButtonSegment<int?>>[
      const ButtonSegment<int?>(value: null, label: Text('Semua')),
      ..._kategoriList.map(
        (k) => ButtonSegment<int?>(value: k.id, label: Text(k.nama)),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
      child: SegmentedButton<int?>(
        segments: segments,
        selected: {_selectedCategoryId},
        onSelectionChanged: (Set<int?> newSelection) {
          setState(() {
            _selectedCategoryId = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildProductCard(Produk product, CartProvider cart) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: _getCategoryColor(product.kategoriId).withOpacity(0.1),
              child: Center(
                child: Icon(
                  _getCategoryIcon(product.kategoriId),
                  size: 40,
                  color: _getCategoryColor(product.kategoriId),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ).copyWith(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(product.harga),
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => cart.removeSingleItem(product.id!),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  tooltip: 'Kurangi',
                  iconSize: 36,
                ),
                Consumer<CartProvider>(
                  builder: (ctx, cartData, _) {
                    final qty = cartData.items[product.id]?.kuantitas ?? 0;
                    return Text(
                      qty.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed: () => cart.addItem(product),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.indigo,
                  ),
                  tooltip: 'Tambah',
                  iconSize: 36,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSection() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Keranjang',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Kosongkan'),
                    onPressed: cart.items.isEmpty ? null : cart.clearCart,
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child:
                    cart.items.isEmpty
                        ? const Center(child: Text('Keranjang masih kosong.'))
                        : ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final item = cart.items.values.toList()[index];
                            return GestureDetector(
                              onDoubleTap:
                                  () => cart.removeSingleItem(item.produk.id!),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getCategoryColor(
                                    item.produk.kategoriId,
                                  ).withOpacity(0.1),
                                  child: Icon(
                                    _getCategoryIcon(item.produk.kategoriId),
                                    color: _getCategoryColor(
                                      item.produk.kategoriId,
                                    ),
                                    size: 20,
                                  ),
                                ),
                                title: Text(item.produk.nama),
                                subtitle: Text(
                                  '${currencyFormatter.format(item.produk.harga)} x ${item.kuantitas}',
                                ),
                                trailing: Text(
                                  currencyFormatter.format(
                                    item.produk.harga * item.kuantitas,
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
              const Divider(),
              _buildTotalSection(cart),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed:
                        cart.items.isEmpty
                            ? null
                            : () {
                              if (_nomorMejaController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Peringatan: Nomor Meja harus diisi!',
                                    ),
                                    duration: Duration(seconds: 1),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                _saveOpenTransaction();
                              }
                            },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.brown.shade400),
                    ),
                    child: Text(
                      widget.editingTransactionId == null
                          ? 'Simpan Pesanan (Bayar Nanti)'
                          : 'Simpan Perubahan',
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.payment),
                    label: const Text('Lanjutkan Pembayaran'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(fontSize: 18),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    onPressed:
                        cart.items.isEmpty
                            ? null
                            : () {
                              if (_nomorMejaController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Peringatan: Nomor Meja harus diisi!',
                                    ),
                                    duration: Duration(seconds: 2),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              } else {
                                _showCustomPaymentDialog(cart);
                              }
                            },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTotalSection(CartProvider cart) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal', style: TextStyle(fontSize: 16)),
            Text(
              currencyFormatter.format(cart.subtotal),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          title: const Text('PPN (10%)', style: TextStyle(fontSize: 16)),
          value: cart.isPpnEnabled,
          onChanged: (value) {
            cart.togglePpn();
          },
          secondary: Text(
            currencyFormatter.format(cart.ppnAmount),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grand Total',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              currencyFormatter.format(cart.grandTotal),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
