import 'package:flutter_test/flutter_test.dart';
import 'package:loja_online_simples_flutter_supabase/main.dart';

void main() {
  group('Product.fromMap', () {
    test('converte corretamente um registro vindo do Supabase', () {
      final product = Product.fromMap(<String, dynamic>{
        'id': 'fone-bluetooth',
        'name': 'Fone Bluetooth',
        'price': 199.90,
        'stock': 28,
        'icon': 'headphones',
        'short_description': 'Som de alta qualidade com conexão estável.',
        'long_description': 'Descrição longa do produto para teste.',
      });

      expect(product.id, 'fone-bluetooth');
      expect(product.name, 'Fone Bluetooth');
      expect(product.price, closeTo(199.90, 0.01));
      expect(product.stock, 28);
      expect(product.icon, 'headphones');
    });
  });
}
