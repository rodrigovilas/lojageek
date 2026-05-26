# Geek & Gamer Store — Loja Online Simples

Projeto didático desenvolvido para dispositivos móveis, inspirado na apostila **Loja Online Simples com Flutter e Dart**.

* **Aluno:** Rodrigo Almeida Vilas Bôas  
* **Turma:** 3º DS - A (Desenvolvimento de Sistemas)  
* **Instituição:** Escola Técnica Estadual Juscelino Kubitschek de Oliveira  
* **Localidade:** Diadema / SP  

---

## Sobre a Loja Geek & Gamer

A **Geek & Gamer Store** é um aplicativo de e-commerce totalmente funcional projetada na aula de Programação Mobile do Professor Dr. Alexandre Garcez Vieira
A interface e a identidade visual deste projeto foram completamente customizadas e transformadas para atender ao público entusiasta da cultura pop, jogos e tecnologia. Nele, o fluxo básico de compra foi adaptado para simular a aquisição de periféricos, colecionáveis e equipamentos de hardware como se fossem "loots" e upgrades para o inventário do usuário.

O aplicativo centraliza a sua lógica de negócios e as regras financeiras em um gerenciador de estado centralizado em memória baseado no padrão de projeto *Singleton* (`StoreController`). Isso garante uma experiência de uso fluida e reativa, onde todas as interações do carrinho, validações de estoque e cálculos de taxas modificam a interface de forma instantânea.

---

## O que o App Demonstra

- **Página Inicial (Menu Principal):** Uma tela de boas-vindas temática ("Player 1, Ready?") projetada com atalhos de navegação simplificada para o catálogo de itens e para o inventário (carrinho) do usuário.
- **Página de Produtos (Catálogo de Loot):** Renderização dinâmica dos produtos em formato de cards, contendo fotos dos produtos (carregadas via rede com tratamento de falhas), preços, descrições resumidas e um indicador em tempo real da quantidade física disponível no estoque. Conta também com uma barra de pesquisa dinâmica integrada para filtragem instantânea de itens por texto.
- **Página de Detalhes do Produto:** Espaço dedicado para inspeção profunda do item. Exibe o código identificador (ID único), preço unitário de destaque, estoque atualizado e especificações técnicas de longa descrição. Apresenta o botão para inserção do item no inventário e retorno rápido à loja.
- **Gerenciamento de Inventário (Carrinho de Compras):**
  - Exibição organizada contendo ID, nome do produto e preço unitário.
  - Botões para incrementar ou decrementar as quantidades de cada item de forma visual.
  - **Cálculo de Regras de Negócio em Tempo Real:** Processamento automatizado de subtotal, aplicação de impostos locais à taxa de 8% e gerenciamento de custo de frete.
- **Sistema de Validação de Estoque:** Mecanismo rigoroso de proteção de dados que impede que as solicitações ultrapassem o estoque físico real disponível no banco do aplicativo, disparando notificações de erro contextuais (`SnackBars`).
- **Cancelamento e Limpeza:** Mecanismo para esvaziar integralmente o carrinho através de um único comando, zerando todas as variáveis, somatórios e liberando o espaço ocupado na memória.
- **Finalização de Pedido e Checkout:** Formulário de endereço com validação estruturada em tempo real (utilizando chaves de validação `FormKey`). Exige de forma separada os dados de CEP e endereço tanto para faturamento (cobrança) quanto para a entrega logística (com opção de cópia rápida via caixa de seleção).
- **Geração de Comprovante de Transação:** Tela dedicada exclusiva para a confirmação de encerramento da missão de compra. Apresenta um recibo digital contendo o detalhamento de custos finais, os endereços utilizados e um código gerado aleatoriamente para o rastreio do pedido (`GEEK-ANO-RANDOM`).
- **Inventário em Arquivo Externo:** Consumo de dados estruturados em formato de catálogo dinâmico de produtos a partir do arquivo isolado `assets/products.json`.

---

## Estrutura Principal

```text
lib/main.dart             Código-fonte completo do aplicativo (Configuração, Models, Controller e UI)
assets/products.json      Inventário externo de produtos em formato JSON (Catálogo de Itens)
pubspec.yaml              Configuração do ecossistema e mapeamento de recursos do Flutter
