import '../errors/result.dart';

/// Every use case implements this contract.
/// [T] is the return type, [P] is the parameter type.
abstract class UseCase<T, P> {
  Future<Result<T>> call(P params);
}

/// Marker for use cases that take no parameters.
class NoParams {
  const NoParams();
}
