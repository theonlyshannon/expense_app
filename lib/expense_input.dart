import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'expense_model.dart';
import 'expense_repository.dart';
import 'package:intl/intl.dart';

class InputExpensePage extends StatefulWidget {
  final Expense? expense;
  final int? index;

  const InputExpensePage({super.key, this.expense, this.index});

  @override
  _InputExpensePageState createState() => _InputExpensePageState();
}

class _InputExpensePageState extends State<InputExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final ExpenseRepository _repository = ExpenseRepository();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String _selectedCategory = 'Lainnya'; // Default sesuai dengan opsi yang ada
  DateTime _selectedDate = DateTime.now();
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isEditingAmount = false;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleController.text = widget.expense!.title;
      _amountController.text = _currencyFormatter.format(widget.expense!.amount); // Format Rupiah
      _selectedCategory = widget.expense!.category;
      _selectedDate = widget.expense!.date;
    }

    // Listener untuk mengubah format input saat mengetik
    _amountController.addListener(() {
      if (_isEditingAmount) return;
      setState(() => _isEditingAmount = true);

      final text = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(text) ?? 0.0;

      _amountController.value = _amountController.value.copyWith(
        text: _currencyFormatter.format(amount),
        selection: TextSelection.collapsed(offset: _currencyFormatter.format(amount).length),
      );

      setState(() => _isEditingAmount = false);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text;
      final amount = double.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final category = _selectedCategory;

      final expense = Expense()
        ..id = widget.expense?.id ?? UniqueKey().toString()
        ..title = title
        ..amount = amount
        ..category = category
        ..date = _selectedDate; // Tanggal tetap disimpan, jika diperlukan

      if (widget.expense == null) {
        _repository.addExpense(expense);
      } else {
        _repository.updateExpense(widget.index!, expense);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Tambah Pengeluaran' : 'Edit Pengeluaran'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input untuk Judul Pengeluaran
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Judul Pengeluaran',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan judul';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Input untuk Jumlah Pengeluaran
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Jumlah Pengeluaran',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan jumlah';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Dropdown Kategori Pengeluaran
                  DropdownButtonFormField(
                    value: _selectedCategory,
                    items: ['Makan', 'Transportasi', 'Subscription', 'Lainnya']
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveExpense,
                      icon: Icon(Icons.save),
                      label: Text(widget.expense == null ? 'Simpan' : 'Perbarui'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        textStyle: TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}