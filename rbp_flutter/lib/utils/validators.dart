String? validateRequired(String? value, {String field = 'Campo'}) {
  if (value == null || value.trim().isEmpty) {
    return '$field es obligatorio';
  }
  return null;
}

String? validatePositiveNumber(String? value, {String field = 'Monto'}) {
  final text = value?.trim() ?? '';
  final parsed = double.tryParse(text);
  if (parsed == null || parsed <= 0) {
    return '$field debe ser mayor que 0';
  }
  return null;
}

String? validateDayOfMonth(String? value, {String field = 'Dia'}) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed < 0 || parsed > 31) {
    return '$field debe estar entre 0 y 31';
  }
  return null;
}

String? validateIsoDate(String? value, {String field = 'Fecha'}) {
  final text = value?.trim() ?? '';
  if (text.length != 10) {
    return '$field debe usar formato YYYY-MM-DD';
  }
  try {
    DateTime.parse(text);
  } catch (_) {
    return '$field invalida';
  }
  return null;
}
