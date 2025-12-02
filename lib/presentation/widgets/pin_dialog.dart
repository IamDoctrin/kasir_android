import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinDialog extends StatefulWidget {
  final String correctPin = '2024'; //Ganti PIN (masih hardcoded)
  final Function() onPinVerified;

  const PinDialog({super.key, required this.onPinVerified});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final _pinController = TextEditingController();
  String? _errorText;

  void _verifyPin() {
    if (_pinController.text == widget.correctPin) {
      Navigator.of(context).pop();
      widget.onPinVerified();
    } else {
      setState(() {
        _errorText = 'PIN salah, coba lagi.';
      });
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Masukkan PIN Untuk Hapus'),
      content: TextField(
        controller: _pinController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 4,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'PIN (4 digit)',
          errorText: _errorText,
        ),
        onChanged: (value) {
          if (_errorText != null) {
            setState(() {
              _errorText = null;
            });
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _verifyPin, child: const Text('Konfirmasi')),
      ],
    );
  }
}
