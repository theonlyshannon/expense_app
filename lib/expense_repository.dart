import 'package:hive/hive.dart';
import 'expense_model.dart';

class ExpenseRepository {
  final Box<Expense> expenseBox = Hive.box<Expense>('expenses');

  void addExpense(Expense expense) {
    expenseBox.add(expense);
  }

  void deleteExpense(int index) {
    expenseBox.deleteAt(index);
  }

  void updateExpense(int index, Expense expense) {
    expenseBox.putAt(index, expense);
  }

  List<Expense> getExpenses() {
    return expenseBox.values.toList();
  }
}
