import 'package:test/test.dart';
import 'package:core_foundation/core_foundation.dart';

void main() {
  group('Result<T, F>', () {
    test('Success holds value and matches when', () {
      const result = Result<int, VaultFailure>.success(42);

      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.valueOrNull, equals(42));
      expect(result.failureOrNull, isNull);
      expect(result.getOrThrow(), equals(42));

      final value = result.when(
        success: (v) => v * 2,
        error: (f) => -1,
      );
      expect(value, equals(84));
    });

    test('Error holds failure and matches when', () {
      final failure = VaultFailure.invalidMasterPassword();
      final result = Result<int, VaultFailure>.error(failure);

      expect(result.isSuccess, isFalse);
      expect(result.isError, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, equals(failure));
      expect(() => result.getOrThrow(), throwsA(isA<VaultFailure>()));

      final value = result.when(
        success: (v) => 'ok',
        error: (f) => f.type.name,
      );
      expect(value, equals('invalidPassword'));
    });

    test('map transforms success value', () {
      const result = Result<int, NetworkFailure>.success(10);
      final mapped = result.map((v) => 'num_$v');

      expect(mapped.valueOrNull, equals('num_10'));
    });

    test('flatMap chains Results correctly', () {
      const result = Result<int, NetworkFailure>.success(10);
      final chained = result.flatMap((v) => Result.success(v + 5));

      expect(chained.valueOrNull, equals(15));
    });
  });
}
