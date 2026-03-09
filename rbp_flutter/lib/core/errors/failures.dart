/// Domain-level failure types.
/// Use cases return these instead of throwing raw exceptions.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error interno.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso no encontrado.']);
}

class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure([super.message = 'Fondos insuficientes.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autenticacion fallida.']);
}

class LicenseFailure extends Failure {
  const LicenseFailure(super.message);
}
