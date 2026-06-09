import 'package:flutter_test/flutter_test.dart';
import 'package:loja_online_simples_flutter_supabase/main.dart';

void main() {
  group('StoreController - cálculos do carrinho', () {
    test('calcula subtotal, frete, impostos e total com carrinho pequeno', () {
      final controller = StoreController();

      controller.cartItems = const <CartItem>[
        CartItem(
          product: Product(
            id: 'fone-bluetooth',
            name: 'Fone Bluetooth',
            price: 199.90,
            stock: 10,
            icon: 'headphones',
            shortDescription: 'Som de alta qualidade.',
            longDescription: 'Produto usado para teste.',
          ),
          quantity: 1,
        ),
      ];

      expect(controller.subtotal, closeTo(199.90, 0.01));
      expect(controller.shipping, closeTo(29.90, 0.01));
      expect(controller.taxes, closeTo(19.99, 0.01));
      expect(controller.total, closeTo(249.79, 0.01));
    });

    test('zera frete quando o subtotal é maior ou igual a 300 reais', () {
      final controller = StoreController();

      controller.cartItems = const <CartItem>[
        CartItem(
          product: Product(
            id: 'smartwatch-fit',
            name: 'Smartwatch Fit',
            price: 349.90,
            stock: 5,
            icon: 'watch',
            shortDescription: 'Relógio inteligente.',
            longDescription: 'Produto usado para teste.',
          ),
          quantity: 1,
        ),
      ];

      expect(controller.subtotal, closeTo(349.90, 0.01));
      expect(controller.shipping, 0);
      expect(controller.taxes, closeTo(34.99, 0.01));
      expect(controller.total, closeTo(384.89, 0.01));
    });
  });
}
