import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await Supabase.initialize(
    url: 'https://wynervrcdrltbwtyjilm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5bmVydnJjZHJsdGJ3dHlqaWxtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk4MTA5OTYsImV4cCI6MjA5NTM4Njk5Nn0.Y5xUKGREwbZdpBWDSsiUHMgx7LNBENOZR-yE2mBIjYc',
  );

  runApp(const GeekStoreApp());
}

/// ============================================================================
/// 1. CONFIGURAÇÃO PRINCIPAL DO APLICATIVO
/// ============================================================================
class GeekStoreApp extends StatelessWidget {
  const GeekStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geek & Gamer Store',
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(),
      home: const LandingPage(),
    );
  }

  /// Constrói o tema visual do aplicativo
  /// Constrói o tema visual do aplicativo
  ThemeData _buildAppTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        primary: Colors.deepPurpleAccent,
        secondary: Colors.amber,
        surface: Colors.grey[50]!,
        error: Colors.redAccent,
      ),
      useMaterial3: true, // <--- ALTERADO AQUI
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

/// ============================================================================
/// 2. MODELOS DE DADOS (DATA MODELS)
/// ============================================================================

/// Modelo que representa um produto no catálogo
class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String thumbnail;
  final String shortDescription;
  final String longDescription;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.thumbnail,
    required this.shortDescription,
    required this.longDescription,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      thumbnail: json['thumbnail']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '', 
      longDescription: json['long_description']?.toString() ?? '',
    );
  }
}


class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;
}

/// Modelo para armazenar os dados de endereço do usuário
class Address {
  String street;
  String cep;

  Address({required this.street, required this.cep});

  bool get isValid => street.isNotEmpty && cep.isNotEmpty && cep.length >= 8;
}

/// ============================================================================
/// 3. GERENCIAMENTO DE ESTADO E REGRAS DE NEGÓCIO (CONTROLLER)
/// ============================================================================
class StoreController {
  // Padrão Singleton para acesso global facilitado no projeto didático
  static final StoreController instance = StoreController._internal();
  StoreController._internal();

  // Lista de produtos carregados do JSON
  List<Product> catalog = [];
  
  // Lista de produtos filtrados para a tela de pesquisa
  List<Product> filteredCatalog = [];

  // Carrinho de compras (Mapeia o ID do produto para o CartItem)
  Map<String, CartItem> cart = {};

  // Configurações de taxas da loja
  final double taxRate = 0.08; // 8% de imposto
  final double minimumForFreeShipping = 150.00; // Desafio 2: Frete grátis >= 150
  final double defaultShippingCost = 19.90;

  /// Retorna o valor subtotal dos itens no carrinho
  double get cartSubtotal {
    double total = 0;
    for (var item in cart.values) {
      total += item.subtotal;
    }
    return total;
  }

  /// Retorna o valor do frete baseado na regra de negócio
  double get shippingCost {
    if (cart.isEmpty) return 0.0;
    return (cartSubtotal >= minimumForFreeShipping) ? 0.0 : defaultShippingCost;
  }

  /// Retorna o valor dos impostos calculados
  double get taxesAmount => cartSubtotal * taxRate;

  /// Retorna o valor total a ser pago (Subtotal + Frete + Impostos)
  double get grandTotal => cartSubtotal + shippingCost + taxesAmount;

  /// Adiciona um produto ao carrinho ou atualiza a quantidade
  String addToCart(Product product, int quantityToAdd) {
    if (cart.containsKey(product.id)) {
      int newQty = cart[product.id]!.quantity + quantityToAdd;
      if (newQty > product.stock) {
        return 'Estoque insuficiente. Restam apenas ${product.stock} unidades.';
      }
      cart[product.id]!.quantity = newQty;
    } else {
      if (quantityToAdd > product.stock) {
        return 'Estoque insuficiente para a quantidade desejada.';
      }
      cart[product.id] = CartItem(product: product, quantity: quantityToAdd);
    }
    return 'Item adicionado ao carrinho com sucesso!';
  }

  /// Atualiza a quantidade de um item no carrinho (botões + e -)
  void updateCartQuantity(String productId, int newQuantity) {
    if (!cart.containsKey(productId)) return;
    
    if (newQuantity <= 0) {
      cart.remove(productId);
    } else {
      // Valida limite de estoque
      if (newQuantity <= cart[productId]!.product.stock) {
        cart[productId]!.quantity = newQuantity;
      }
    }
  }

  /// Limpa todos os itens do carrinho
  void clearCart() {
    cart.clear();
  }

  /// Filtra o catálogo com base em um termo de pesquisa
  void filterCatalog(String query) {
    if (query.isEmpty) {
      filteredCatalog = List.from(catalog);
    } else {
      filteredCatalog = catalog
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }
}

/// ============================================================================
/// 4. WIDGETS PERSONALIZADOS E REUTILIZÁVEIS (COMPONENTES DA UI)
/// ============================================================================

/// Um campo de texto padronizado para formulários
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

/// Um botão principal com ícone
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.all(16),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      onPressed: onPressed,
    );
  }
}

/// Widget que exibe a imagem do produto de forma segura
class ProductNetworkImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;

  const ProductNetworkImage({
    super.key,
    required this.url,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: height, width: width,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: height, width: width,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }
}

/// ============================================================================
/// 5. TELAS DO APLICATIVO (PAGES)
/// ============================================================================

/// PASSO 1: PÁGINA INICIAL (LANDING PAGE)
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }


  Future<void> _loadCatalog() async {
    try {
      print('Iniciando busca no Supabase...'); // <--- ADICIONE ISTO
      
      final List<Map<String, dynamic>> response = await Supabase.instance.client
          .from('products')
          .select();
      
      print('Dados recebidos: ${response.length} itens encontrados.'); 

      StoreController.instance.catalog = response
          .map((item) => Product.fromJson(item))
          .toList();
      
      StoreController.instance.filterCatalog('');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('ERRO NO SUPABASE: $e'); 
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geek & Gamer Store 🎮'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            tooltip: 'Ver Inventário',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
          )
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando itens do servidor...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports, size: 100, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Player 1, Ready?',
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Equipe seu setup com os melhores periféricos, actions figures e itens da cultura pop.\nFaça o upgrade do seu inventário!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Explorar Catálogo de Loot',
              icon: Icons.rocket_launch,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsPage())),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.all(16),
              ),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Acessar Meu Inventário', style: TextStyle(fontSize: 16)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
            ),
          ],
        ),
      ),
    );
  }
}

/// PASSO 2: PÁGINA DE PRODUTOS (COM BUSCA)
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Restaura a lista completa toda vez que abre a página
    StoreController.instance.filterCatalog('');
  }

  void _onSearchChanged(String query) {
    setState(() {
      StoreController.instance.filterCatalog(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = StoreController.instance.filteredCatalog;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loot Disponível'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage())),
          )
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar equipamentos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Lista de Produtos
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('Nenhum item encontrado na sua busca.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(context, products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ProductNetworkImage(url: product.thumbnail, width: 100, height: 100),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.shortDescription,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'R\$ ${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.stock > 0 ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.stock > 0 ? 'Estoque: ${product.stock}' : 'Esgotado',
                            style: TextStyle(
                              color: product.stock > 0 ? Colors.green[800] : Colors.red[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PASSO 3: DETALHES DO PRODUTO
class ProductDetailsPage extends StatelessWidget {
  final Product product;
  const ProductDetailsPage({super.key, required this.product});

  void _handleAddToCart(BuildContext context) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item fora de estoque no momento!'), backgroundColor: Colors.red),
      );
      return;
    }

    final message = StoreController.instance.addToCart(product, 1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: message.contains('sucesso') ? Colors.green : Colors.orange,
        action: SnackBarAction(
          label: 'VER CARRINHO',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Inspecionar Item')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem de Destaque
            SizedBox(
              width: double.infinity,
              height: 300,
              child: ProductNetworkImage(url: product.thumbnail, width: double.infinity, height: 300),
            ),
            
            // Corpo de Informações
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cod: ${product.id}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      Icon(Icons.share, color: Colors.grey[500]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Preço e Estoque
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Preço unitário', style: TextStyle(color: Colors.grey)),
                            Text(
                              'R\$ ${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Disponibilidade', style: TextStyle(color: Colors.grey)),
                            Text(
                              '${product.stock} em estoque',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Especificações do Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    product.longDescription,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar travado no rodapé para o botão de compra
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PrimaryButton(
            label: 'Adicionar ao Inventário',
            icon: Icons.add_shopping_cart,
            onPressed: () => _handleAddToCart(context),
          ),
        ),
      ),
    );
  }
}

/// PASSO 4 E DESAFIOS 2 e 3: CARRINHO E FORMULÁRIO DE CHECKOUT
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores do endereço de faturamento
  final _billingStreetCtrl = TextEditingController();
  final _billingCepCtrl = TextEditingController();

  // Controladores do endereço de entrega (Desafio 3 - Campos separados)
  final _shippingStreetCtrl = TextEditingController();
  final _shippingCepCtrl = TextEditingController();

  // Estado para controlar se o endereço de entrega é igual ao de faturamento
  bool _sameAddress = false;

  void _refreshCart() {
    setState(() {}); // Força reconstrução da tela quando quantidades mudam
  }

  @override
  void dispose() {
    _billingStreetCtrl.dispose();
    _billingCepCtrl.dispose();
    _shippingStreetCtrl.dispose();
    _shippingCepCtrl.dispose();
    super.dispose();
  }

  void _processCheckout() {
    if (StoreController.instance.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seu inventário está vazio!')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Geração de ID de Pedido Didático
      final orderId = 'GEEK-${DateTime.now().year}${DateTime.now().month}-${Random().nextInt(99999).toString().padLeft(5, '0')}';
      
      final totalValue = StoreController.instance.grandTotal;

      // Navegação para Tela de Confirmação (Desafio 4)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationPage(
            orderId: orderId,
            billingStreet: _billingStreetCtrl.text,
            billingCep: _billingCepCtrl.text,
            shippingStreet: _sameAddress ? _billingStreetCtrl.text : _shippingStreetCtrl.text,
            shippingCep: _sameAddress ? _billingCepCtrl.text : _shippingCepCtrl.text,
            totalValue: totalValue,
          ),
        ),
      );

      // Limpa o estado global após finalizar a compra
      StoreController.instance.clearCart();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os erros no formulário de endereço.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = StoreController.instance.cart.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Inventário (Carrinho)'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Descartar tudo',
              onPressed: () {
                StoreController.instance.clearCart();
                _refreshCart();
              },
            )
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart()
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildCartList(cartItems),
                  const SizedBox(height: 24),
                  _buildAddressForms(),
                  const SizedBox(height: 24),
                  _buildOrderSummary(),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Confirmar Missão (Checkout)',
                    icon: Icons.check_circle_outline,
                    onPressed: _processCheckout,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_shopping_cart, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Seu inventário de loot está vazio.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar para a Loja'),
          )
        ],
      ),
    );
  }

  Widget _buildCartList(List<CartItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Itens Selecionados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ProductNetworkImage(url: item.product.thumbnail, width: 60, height: 60),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('R\$ ${item.product.price.toStringAsFixed(2)} unid.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          StoreController.instance.updateCartQuantity(item.product.id, item.quantity - 1);
                          _refreshCart();
                        },
                      ),
                      Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () {
                          if (item.quantity < item.product.stock) {
                            StoreController.instance.updateCartQuantity(item.product.id, item.quantity + 1);
                            _refreshCart();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limite de estoque atingido.')));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAddressForms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dados de Faturamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _billingStreetCtrl,
          label: 'Endereço Completo (Cobrança)',
          icon: Icons.location_on,
          validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
        ),
        CustomTextField(
          controller: _billingCepCtrl,
          label: 'CEP de Cobrança (Apenas números)',
          icon: Icons.markunread_mailbox,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Campo obrigatório';
            if (value.length < 8) return 'CEP inválido';
            return null;
          },
        ),
        
        CheckboxListTile(
          title: const Text('Entregar no mesmo endereço de cobrança'),
          contentPadding: EdgeInsets.zero,
          value: _sameAddress,
          onChanged: (bool? value) {
            setState(() {
              _sameAddress = value ?? false;
              if (_sameAddress) {
                // Sincroniza os textos se marcado
                _shippingStreetCtrl.text = _billingStreetCtrl.text;
                _shippingCepCtrl.text = _billingCepCtrl.text;
              } else {
                _shippingStreetCtrl.clear();
                _shippingCepCtrl.clear();
              }
            });
          },
        ),

        if (!_sameAddress) ...[
          const Divider(),
          const SizedBox(height: 8),
          const Text('Dados de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _shippingStreetCtrl,
            label: 'Endereço Completo (Entrega)',
            icon: Icons.local_shipping,
            validator: (value) => value == null || value.isEmpty ? 'Campo obrigatório' : null,
          ),
          CustomTextField(
            controller: _shippingCepCtrl,
            label: 'CEP de Entrega',
            icon: Icons.map,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Campo obrigatório';
              if (value.length < 8) return 'CEP inválido';
              return null;
            },
          ),
        ]
      ],
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = StoreController.instance.cartSubtotal;
    final shipping = StoreController.instance.shippingCost;
    final taxes = StoreController.instance.taxesAmount;
    final total = StoreController.instance.grandTotal;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo do Pedido', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildSummaryRow('Subtotal dos Itens:', subtotal),
            _buildSummaryRow(
              'Frete (Transportadora):', 
              shipping, 
              isFree: shipping == 0,
            ),
            if (shipping == 0)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Text('*Você ganhou frete grátis (Compras acima de R\$ 150)!', style: TextStyle(color: Colors.green, fontSize: 12)),
              ),
            _buildSummaryRow('Taxas e Impostos (8%):', taxes),
            const Divider(thickness: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL GERAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text(
                  'R\$ ${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            isFree ? 'GRÁTIS' : 'R\$ ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: isFree ? FontWeight.bold : FontWeight.normal,
              color: isFree ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// DESAFIO 4: TELA DE CONFIRMAÇÃO DE PEDIDO
/// ============================================================================
class OrderConfirmationPage extends StatelessWidget {
  final String orderId;
  final String billingStreet;
  final String billingCep;
  final String shippingStreet;
  final String shippingCep;
  final double totalValue;

  const OrderConfirmationPage({
    super.key,
    required this.orderId,
    required this.billingStreet,
    required this.billingCep,
    required this.shippingStreet,
    required this.shippingCep,
    required this.totalValue,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missão Concluída! 🏆'),
        automaticallyImplyLeading: false, // Força a navegação apenas pelo botão principal
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.verified, size: 120, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Transação Registrada na Base de Dados!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'O loot já está sendo preparado para o envio. Em breve você receberá o código de rastreamento de teletransporte.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Comprovante Digital', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    _buildReceiptRow('Código de Rastreio:', orderId, isBold: true),
                    const SizedBox(height: 12),
                    
                    const Text('Endereço de Cobrança:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text('$billingStreet\nCEP: $billingCep', style: const TextStyle(height: 1.4)),
                    const SizedBox(height: 12),
                    
                    const Text('Endereço de Entrega:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text('$shippingStreet\nCEP: $shippingCep', style: const TextStyle(height: 1.4)),
                    const Divider(),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valor Descontado:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          'R\$ ${totalValue.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            PrimaryButton(
              label: 'Voltar ao Menu Principal',
              icon: Icons.home,
              onPressed: () {
                // Limpa a pilha de telas e volta para a LandingPage (a primeira tela)
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}