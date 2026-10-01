import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_servicios/features/requests/domain/latest_search.dart';

void main() {
  test('ignora el resultado obsoleto', () async {
    final a = Completer<String>();
    final b = Completer<String>();

    final results = <String>[];

    final search = LatestSearch<String>(
      fetch: (query) {
        if (query == 'A') {
          return a.future;
        }

        return b.future;
      },
      onData: results.add,
      onError: (error, stack) {},
    );

    // Iniciamos A y después B.
    final futureA = search.run('A');
    final futureB = search.run('B');

    // B termina primero.
    b.complete('B');

    // Esperamos a que termine la ejecución de run('B').
    await futureB;

    expect(results, ['B']);

    // Ahora termina A.
    a.complete('A');

    // Esperamos a que termine la ejecución de run('A').
    await futureA;

    // A es obsoleto y no debe publicarse.
    expect(results, ['B']);
  });

  test('ignora el error obsoleto', () async {
    final a = Completer<String>();
    final b = Completer<String>();

    final results = <String>[];
    final errors = <Object>[];

    final search = LatestSearch<String>(
      fetch: (query) {
        if (query == 'A') {
          return a.future;
        }

        return b.future;
      },
      onData: results.add,
      onError: (error, stack) {
        errors.add(error);
      },
    );

    // Iniciamos A y después B.
    final futureA = search.run('A');
    final futureB = search.run('B');

    // B termina correctamente.
    b.complete('B');

    await futureB;

    expect(results, ['B']);
    expect(errors, isEmpty);

    // A termina después, pero con un error.
    a.completeError(Exception('error de A'));

    await futureA;

    // El error de A también es obsoleto y debe ignorarse.
    expect(results, ['B']);
    expect(errors, isEmpty);
  });
}
