import '../data/models/dashboard_data.dart';
import '../data/models/loan.dart';
class CsvService {
  CsvService({
    Future<dynamic> Function()? documentsDirectoryProvider,
  });
  Future<String> exportDashboardCsv({
    required DashboardData dashboard,
    required List<Loan> loans,
    required String periodLabel,
  }) async {
    throw UnsupportedError(
      'La exportacion CSV aun no esta disponible en esta plataforma.',
    );
  }
}
