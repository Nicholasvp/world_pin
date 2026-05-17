import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:world_pin/repositories/config_repository.dart';

// --- Fakes para simular o cliente e as builders do Supabase ---

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final Map<String, dynamic>? mockResponse;
  final bool throwError;

  FakeSupabaseClient({this.mockResponse, this.throwError = false});

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'config') {
      return FakeSupabaseQueryBuilder(mockResponse: mockResponse, throwError: throwError);
    }
    throw UnimplementedError();
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Map<String, dynamic>? mockResponse;
  final bool throwError;

  FakeSupabaseQueryBuilder({this.mockResponse, this.throwError = false});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakePostgrestFilterBuilder(mockResponse: mockResponse, throwError: throwError);
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic>? mockResponse;
  final bool throwError;

  FakePostgrestFilterBuilder({this.mockResponse, this.throwError = false});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> limit(int count, {String? referencedTable}) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder(mockResponse: mockResponse, throwError: throwError);
  }
}

class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Map<String, dynamic>? mockResponse;
  final bool throwError;

  FakePostgrestTransformBuilder({this.mockResponse, this.throwError = false});

  @override
  Future<U> then<U>(
    FutureOr<U> Function(Map<String, dynamic>? value) onValue, {
    Function? onError,
  }) {
    if (throwError) {
      return Future<Map<String, dynamic>?>.error(
        const PostgrestException(message: 'Simulated database error'),
      ).then((value) => onValue(value), onError: onError);
    }
    return Future<Map<String, dynamic>?>.value(mockResponse).then(
      (value) => onValue(value),
      onError: onError,
    );
  }
}

void main() {
  group('ConfigRepository Tests', () {
    test('Retorna o valor correto de limit_free_countries do Supabase', () async {
      // Configura um mock client que retorna 3 países limite
      final mockClient = FakeSupabaseClient(
        mockResponse: {'limit_free_countries': 3},
      );
      final repository = ConfigRepository(client: mockClient);

      final result = await repository.getLimitFreeCountries();

      expect(result, equals(3));
    });

    test('Retorna fallback padrão (5) quando a resposta for nula ou inválida', () async {
      // Configura um mock client que retorna nulo
      final mockClient = FakeSupabaseClient(mockResponse: null);
      final repository = ConfigRepository(client: mockClient);

      final result = await repository.getLimitFreeCountries();

      expect(result, equals(5));
    });

    test('Retorna fallback padrão (5) caso ocorra alguma exceção no Supabase', () async {
      // Configura um mock client que lança uma exceção de banco de dados
      final mockClient = FakeSupabaseClient(throwError: true);
      final repository = ConfigRepository(client: mockClient);

      final result = await repository.getLimitFreeCountries();

      expect(result, equals(5));
    });
  });
}
