import '../data/models/dashboard_data.dart';
import '../data/models/debt.dart';
import '../data/models/loan.dart';
import '../data/models/personal_debt.dart';
class PdfService {
  PdfService({
    Future<dynamic> Function()? documentsDirectoryProvider,
  });
  Future<String> generateDashboardReport({
    required DashboardData dashboard,
    required List<Loan> loans,
    required List<Debt> debts,
    required List<PersonalDebt> personalDebts,
    required String periodLabel,
  }) async {
    throw UnsupportedError(
      'La exportacion PDF aun no esta disponible en esta plataforma.',
    );
  }
}
