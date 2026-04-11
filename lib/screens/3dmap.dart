import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const ProductMapApp());
}

class ProductMapApp extends StatelessWidget {
  const ProductMapApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3D Product Map',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1419),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1419),
          elevation: 0,
        ),
      ),
      home: const Product3DMapScreen(),
    );
  }
}

class Product {
  final String id;
  final String name;
  final int quantity;
  final StockStatus status;
  final Offset position3D; // x, y coordinates for 3D positioning
  final double height; // Represents quantity visually

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.status,
    required this.position3D,
    required this.height,
  });
}

enum StockStatus {
  inStock,
  lowStock,
  outOfStock,
}

extension StockStatusExt on StockStatus {
  Color get color {
    switch (this) {
      case StockStatus.inStock:
        return const Color(0xFF10B981); // Green
      case StockStatus.lowStock:
        return const Color(0xFFFA8500); // Orange
      case StockStatus.outOfStock:
        return const Color(0xFFEF4444); // Red
    }
  }

  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }
}

class Product3DMapScreen extends StatefulWidget {
  const Product3DMapScreen({Key? key}) : super(key: key);

  @override
  State<Product3DMapScreen> createState() => _Product3DMapScreenState();
}

class _Product3DMapScreenState extends State<Product3DMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  String selectedFilter = 'All Products';

  final List<Product> allProducts = [
    Product(
      id: 'WM-001',
      name: 'Wireless Mouse',
      quantity: 45,
      status: StockStatus.inStock,
      position3D: const Offset(0.2, 0.3),
      height: 0.4,
    ),
    Product(
      id: 'UC-003',
      name: 'USB-C Cable',
      quantity: 120,
      status: StockStatus.inStock,
      position3D: const Offset(0.4, 0.5),
      height: 0.8,
    ),
    Product(
      id: 'LS-002',
      name: 'Laptop Stand',
      quantity: 8,
      status: StockStatus.lowStock,
      position3D: const Offset(0.6, 0.2),
      height: 0.35,
    ),
    Product(
      id: 'MN-004',
      name: 'Monitor 27"',
      quantity: 0,
      status: StockStatus.outOfStock,
      position3D: const Offset(0.75, 0.4),
      height: 0.0,
    ),
    Product(
      id: 'OC-005',
      name: 'Office Chair',
      quantity: 15,
      status: StockStatus.inStock,
      position3D: const Offset(0.25, 0.7),
      height: 0.5,
    ),
    Product(
      id: 'WC-007',
      name: 'Webcam HD',
      quantity: 32,
      status: StockStatus.inStock,
      position3D: const Offset(0.5, 0.75),
      height: 0.6,
    ),
    Product(
      id: 'KB-006',
      name: 'Mechanical Keyboard',
      quantity: 5,
      status: StockStatus.lowStock,
      position3D: const Offset(0.8, 0.6),
      height: 0.25,
    ),
    Product(
      id: 'SD-008',
      name: 'Standing Desk',
      quantity: 3,
      status: StockStatus.lowStock,
      position3D: const Offset(0.65, 0.8),
      height: 0.15,
    ),
  ];

  late List<Product> filteredProducts;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    filteredProducts = allProducts;
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _filterProducts(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == 'All Products') {
        filteredProducts = allProducts;
      } else {
        filteredProducts =
            allProducts.where((p) => p.status.label == filter).toList();
      }
    });
  }

  Color _getStatusColor(StockStatus status) => status.color;

  @override
  Widget build(BuildContext context) {
    final inStockCount =
        allProducts.where((p) => p.status == StockStatus.inStock).length;
    final lowStockCount =
        allProducts.where((p) => p.status == StockStatus.lowStock).length;
    final outOfStockCount =
        allProducts.where((p) => p.status == StockStatus.outOfStock).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1419),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3D Product Map',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '${allProducts.length} products - Interactive view',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _rotationController.reset();
              _rotationController.forward();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: const Color(0xFF0F1419),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All Products',
                    isSelected: selectedFilter == 'All Products',
                    onTap: () => _filterProducts('All Products'),
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'In Stock',
                    isSelected: selectedFilter == 'In Stock',
                    onTap: () => _filterProducts('In Stock'),
                    color: const Color(0xFF10B981),
                    count: inStockCount,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Low Stock',
                    isSelected: selectedFilter == 'Low Stock',
                    onTap: () => _filterProducts('Low Stock'),
                    color: const Color(0xFFFA8500),
                    count: lowStockCount,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Out of Stock',
                    isSelected: selectedFilter == 'Out of Stock',
                    onTap: () => _filterProducts('Out of Stock'),
                    color: const Color(0xFFEF4444),
                    count: outOfStockCount,
                  ),
                ],
              ),
            ),
          ),
          // 3D Product Map Visualization
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF1A1E2E),
              child: Stack(
                children: [
                  // Background grid pattern
                  CustomPaint(
                    painter: GridPainter(),
                    size: Size.infinite,
                  ),
                  // 3D Visualization
                  AnimatedBuilder(
                    animation: _rotationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: Product3DPainter(
                          products: filteredProducts,
                          rotation: _rotationController.value * 2 * math.pi,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0F1419),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legend',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LegendItem(
                      color: const Color(0xFF10B981),
                      label: 'In Stock',
                    ),
                    const SizedBox(height: 6),
                    _LegendItem(
                      color: const Color(0xFFFA8500),
                      label: 'Low Stock',
                    ),
                    const SizedBox(height: 6),
                    _LegendItem(
                      color: const Color(0xFFEF4444),
                      label: 'Out of Stock',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Box height = quantity',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // Stats box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[800]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _StatBox(
                        count: '$inStockCount',
                        label: 'In Stock',
                        color: const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 8),
                      _StatBox(
                        count: '$lowStockCount',
                        label: 'Low Stock',
                        color: const Color(0xFFFA8500),
                      ),
                      const SizedBox(height: 8),
                      _StatBox(
                        count: '$outOfStockCount',
                        label: 'Out of Stock',
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Products List
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0F1419),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 12),
                    child: Text(
                      'All Products',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        final isLeftColumn = index % 2 == 0;

                        if (!isLeftColumn &&
                            index == filteredProducts.length - 1) {
                          // Last item alone on right column
                          return const SizedBox.shrink();
                        }

                        if (isLeftColumn) {
                          final rightIndex = index + 1;
                          final hasRight = rightIndex < filteredProducts.length;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _ProductCard(
                                    product: product,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: hasRight
                                      ? _ProductCard(
                                          product: filteredProducts[rightIndex],
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          );
                        }

                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    const spacing = 60.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class Product3DPainter extends CustomPainter {
  final List<Product> products;
  final double rotation;

  Product3DPainter({
    required this.products,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Sort products by depth for proper rendering order
    final sortedProducts = List<Product>.from(products)
      ..sort((a, b) => a.position3D.dy.compareTo(b.position3D.dy));

    for (final product in sortedProducts) {
      // Calculate 3D position with rotation
      final angle = rotation + (product.position3D.dx * 2 * math.pi);
      final distance = 150.0;

      final x3D = math.cos(angle) * distance;
      final y3D = product.position3D.dy * size.height - centerY / 2;

      // Isometric projection
      final screenX = centerX + (x3D * 0.7);
      final screenY =
          centerY + (y3D * 0.4) - (product.height * size.height * 0.3);

      // Draw 3D box
      _drawProduct3DBox(
        canvas,
        Offset(screenX, screenY),
        product.height * size.height * 0.25,
        product.status.color,
      );
    }
  }

  void _drawProduct3DBox(
    Canvas canvas,
    Offset position,
    double height,
    Color color,
  ) {
    const boxWidth = 40.0;
    const boxDepth = 40.0;

    // Front face
    final frontPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final frontRect = Rect.fromLTWH(
      position.dx - boxWidth / 2,
      position.dy - height,
      boxWidth,
      height,
    );

    canvas.drawRect(frontRect, frontPaint);

    // Top face (isometric)
    final topPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final topPath = Path();
    topPath.moveTo(position.dx - boxWidth / 2, position.dy - height);
    topPath.lineTo(position.dx - boxWidth / 2 + 15, position.dy - height - 15);
    topPath.lineTo(position.dx + boxWidth / 2 + 15, position.dy - height - 15);
    topPath.lineTo(position.dx + boxWidth / 2, position.dy - height);
    topPath.close();

    canvas.drawPath(topPath, topPaint);

    // Side face (isometric)
    final sidePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final sidePath = Path();
    sidePath.moveTo(position.dx + boxWidth / 2, position.dy - height);
    sidePath.lineTo(position.dx + boxWidth / 2 + 15, position.dy - height - 15);
    sidePath.lineTo(position.dx + boxWidth / 2 + 15, position.dy - 15);
    sidePath.lineTo(position.dx + boxWidth / 2, position.dy);
    sidePath.close();

    canvas.drawPath(sidePath, sidePaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(frontRect, borderPaint);
  }

  @override
  bool shouldRepaint(Product3DPainter oldDelegate) =>
      rotation != oldDelegate.rotation || products != oldDelegate.products;
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final int? count;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFF1A1E2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[700]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[500],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _StatBox({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: product.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.id,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              Text(
                '${product.quantity} units',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
