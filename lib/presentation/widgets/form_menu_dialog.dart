import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/entities/kategori.dart';
import '../../data/entities/produk.dart';

class FormMenuDialog extends StatefulWidget {
  final Produk? produk; // Jika null, berarti mode Tambah. Jika ada, mode Edit.
  final List<Kategori> kategoriList;
  final Function(Produk produk) onSubmit;

  const FormMenuDialog({
    super.key,
    this.produk,
    required this.kategoriList,
    required this.onSubmit,
  });

  @override
  State<FormMenuDialog> createState() => _FormMenuDialogState();
}

class _FormMenuDialogState extends State<FormMenuDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  int? _selectedKategoriId;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.produk?.nama);
    _hargaController = TextEditingController(
      text: widget.produk?.harga.toString(),
    );
    _selectedKategoriId = widget.produk?.kategoriId;

    if (_selectedKategoriId == null && widget.kategoriList.isNotEmpty) {
      _selectedKategoriId = widget.kategoriList.first.id;
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final produkBaru = Produk(
        id: widget.produk?.id,
        nama: _namaController.text,
        harga: int.parse(_hargaController.text),
        kategoriId: _selectedKategoriId!,
      );
      widget.onSubmit(produkBaru);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.produk == null ? 'Tambah Menu Baru' : 'Edit Menu'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Menu'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama menu tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedKategoriId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items:
                    widget.kategoriList.map((kategori) {
                      return DropdownMenuItem(
                        value: kategori.id,
                        child: Text(kategori.nama),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedKategoriId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Pilih kategori';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hargaController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  return null;
                },
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
        ElevatedButton(onPressed: _submitForm, child: const Text('Simpan')),
      ],
    );
  }
}
