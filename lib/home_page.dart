import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'expense_model.dart';
import 'expense_repository.dart';
import 'expense_input.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ExpenseRepository _repository = ExpenseRepository();
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  double totalUang = 0.0; // Variabel untuk menyimpan total uang

  @override
  void initState() {
    super.initState();
    _loadTotalUang();
  }

  // Fungsi untuk menghitung total pengeluaran
  double _calculateTotalExpense(Box<Expense> box) {
    return box.values.fold(0.0, (sum, expense) => sum + (expense.amount ?? 0.0));
  }

  // Fungsi untuk memuat total uang dari Hive
  void _loadTotalUang() async {
    final box = await Hive.openBox('settings');
    setState(() {
      totalUang = box.get('totalUang', defaultValue: 0.0);
    });
  }

  // Fungsi untuk menyimpan total uang ke Hive
  void _saveTotalUang(double amount) async {
    final box = await Hive.openBox('settings');
    box.put('totalUang', amount);
  }

  // Fungsi untuk membuka dialog input total uang
  void _inputTotalUang() {
    final TextEditingController _uangController = TextEditingController();
    bool _isEditingAmount = false;

    // Listener untuk mengubah format input saat mengetik
    _uangController.addListener(() {
      if (_isEditingAmount) return;
      setState(() => _isEditingAmount = true);

      final text = _uangController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(text) ?? 0.0;

      _uangController.value = _uangController.value.copyWith(
        text: _currencyFormatter.format(amount),
        selection: TextSelection.collapsed(offset: _currencyFormatter.format(amount).length),
      );

      setState(() => _isEditingAmount = false);
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Input Total Uang'),
          content: TextField(
            controller: _uangController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Total Uang',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final inputText = _uangController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final inputAmount = double.tryParse(inputText) ?? 0.0;

                if (inputText.isEmpty || inputAmount <= 0) {
                  // Validasi jika input kosong atau kurang dari atau sama dengan 0
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Masukkan total uang yang valid')),
                  );
                  return;
                }

                setState(() {
                  totalUang = inputAmount;
                });
                _saveTotalUang(totalUang);
                Navigator.pop(context);
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Keuangan'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Expense>('expenses').listenable(),
        builder: (context, Box<Expense> box, _) {
          // Menghitung total pengeluaran
          final totalExpense = _calculateTotalExpense(box);
          final remainingUang = totalUang - totalExpense; // Update remaining uang

          return Column(
            children: [
              // Card Gradient untuk menampilkan total uang yang tersisa
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total Uang Tersisa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _currencyFormatter.format(remainingUang), // Format Rupiah untuk uang yang tersisa
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Daftar pengeluaran
              Expanded(
                child: box.isEmpty
                    ? const Center(child: Text('Belum Ada Pengeluaran'))
                    : ListView.builder(
                        itemCount: box.length,
                        itemBuilder: (context, index) {
                          final expense = box.getAt(index);
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.attach_money, color: Colors.green),
                              title: Text(
                                expense?.title ?? '',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${expense?.category} - ${_currencyFormatter.format(expense?.amount ?? 0)}', // Format Rupiah untuk setiap item pengeluaran
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _repository.deleteExpense(index);
                                  setState(() {}); // Update UI setelah pengeluaran dihapus
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        InputExpensePage(expense: expense, index: index),
                                  ),
                                ).then((_) {
                                  setState(() {}); // Update UI setelah kembali dari InputExpensePage
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
              // Dua Tombol untuk Input Total Uang dan Pengeluaran
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _inputTotalUang,
                        icon: Icon(Icons.account_balance_wallet),
                        label: Text('Input Total Uang'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => InputExpensePage()),
                          ).then((_) {
                            setState(() {}); // Update UI setelah menambah pengeluaran
                          });
                        },
                        icon: Icon(Icons.add_shopping_cart),
                        label: Text('Input Pengeluaran'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}