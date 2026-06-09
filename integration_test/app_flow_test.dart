import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loja_online_simples_flutter_supabase/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Fluxo principal: produtos, detalhes, carrinho e checkout',
      (WidgetTester tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('Loja Online Simples'), findsWidgets);

    await tester.tap(find.text('Ver Produtos').first);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Produtos'), findsOneWidget);
    expect(find.text('Selecionar'), findsWidgets);

    await tester.tap(find.text('Selecionar').first);
    await tester.pumpAndSettle();

    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.text('Adicionar ao Carrinho'), findsOneWidget);

    await tester.tap(find.text('Adicionar ao Carrinho'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('Produto adicionado'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Carrinho'), findsOneWidget);
    expect(find.text('Finalizar Pedido'), findsOneWidget);

    await tester.tap(find.text('Finalizar Pedido'));
    await tester.pumpAndSettle();

    expect(find.text('Finalização'), findsOneWidget);
    expect(find.text('Confirmar Pedido'), findsOneWidget);
  });
}
