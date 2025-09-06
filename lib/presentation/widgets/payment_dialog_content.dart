import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'currency_input_formatter.dart';
import '../../providers/cart_provider.dart';

class PaymentDialogContent extends StatefulWidget {
  final CartProvider cart;
  final Function(String paymentMethod, double paymentAmount) onProcessPayment;

  const PaymentDialogContent({
    super.key,
    required this.cart,
    required this.onProcessPayment,
  });

  @override
  State<PaymentDialogContent> createState() => _PaymentDialogContentState();
}

class _PaymentDialogContentState extends State<PaymentDialogContent> {
  final _paymentController = TextEditingController();
  double _change = 0.0;
  String _selectedPaymentMethod = 'Cash';

  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _paymentController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final cleanString = _paymentController.text.replaceAll('.', '');
    final paymentAmount = double.tryParse(cleanString) ?? 0.0;
    setState(() {
      _change = paymentAmount - widget.cart.grandTotal;
    });
  }

  void _setQuickCash(double amount) {
    _paymentController.text = NumberFormat.decimalPattern(
      'id_ID',
    ).format(amount);
  }

  void _process() {
    final cleanString = _paymentController.text.replaceAll('.', '');
    final paymentAmount = double.tryParse(cleanString) ?? 0.0;
    widget.onProcessPayment(_selectedPaymentMethod, paymentAmount);
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.cart.grandTotal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pembayaran',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'Cash',
                              label: Text('Cash'),
                              icon: Icon(Icons.money),
                            ),
                            ButtonSegment(
                              value: 'Transfer',
                              label: Text('Transfer'),
                              icon: Icon(Icons.qr_code),
                            ),
                          ],
                          selected: {_selectedPaymentMethod},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _selectedPaymentMethod = newSelection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          'Total Belanja:',
                          formatCurrency.format(totalAmount),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _paymentController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Bayar',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          'Kembalian:',
                          formatCurrency.format(_change < 0 ? 0 : _change),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      children: [
                        const Text("Uang Pas/Cepat"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children:
                              [
                                    totalAmount.toDouble(),
                                    ...[
                                      20000,
                                      50000,
                                      100000,
                                      150000,
                                      200000,
                                    ].where((a) => a > totalAmount),
                                  ]
                                  .map(
                                    (amount) => ElevatedButton(
                                      onPressed:
                                          () =>
                                              _setQuickCash(amount.toDouble()),
                                      child: Text(
                                        NumberFormat.decimalPattern(
                                          'id_ID',
                                        ).format(amount),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed:
                        (_change >= 0 && _paymentController.text.isNotEmpty)
                            ? _process
                            : null,
                    child: const Text('Proses & Cetak Struk'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
