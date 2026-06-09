import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loja_online_simples_flutter_supabase/main.dart';

void main() {
  testWidgets('Golden test do ProductCard', (WidgetTester tester) async {
    const product = Product(
      id: 'fone-bluetooth',
      name: 'Fone Bluetooth',
      price: 199.90,
      stock: 28,
      icon: 'headphones',
      shortDescription: 'Som de alta qualidade com conexão estável.',
      longDescription: 'Descrição longa do produto para teste.',
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: Center(
            child: SizedBox(
              width: 420,
              child: ProductCard(
                product: product,
                onSelect: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(ProductCard),
      matchesGoldenFile('goldens/product_card.png'),
    );
  });
}
