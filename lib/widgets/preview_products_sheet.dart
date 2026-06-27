import 'package:flutter/material.dart';
import 'package:voice_shopping_app/models/product.dart';
import 'package:voice_shopping_app/services/db_service.dart';

class PreviewProductsSheet extends StatefulWidget {
  final List<Product> initialProducts;
  final String currency;
  final String Function(String) getTranslation;
  final DbService dbService;

  const PreviewProductsSheet({
    super.key,
    required this.initialProducts,
    required this.currency,
    required this.getTranslation,
    required this.dbService,
  });

  @override
  State<PreviewProductsSheet> createState() => _PreviewProductsSheetState();
}

class _PreviewProductsSheetState extends State<PreviewProductsSheet> {
  late List<Product> _tempList;

  @override
  void initState() {
    super.initState();
    _tempList = List.from(widget.initialProducts);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1F2C34),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.getTranslation('review_title'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: _tempList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        widget.getTranslation('empty'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _tempList.length,
                    itemBuilder: (context, index) {
                      final item = _tempList[index];
                      return Card(
                        color: const Color(0xFF2A3942),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(item.name,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            '${item.price.toStringAsFixed(0)} ${widget.currency} / шт. | ${item.category.isEmpty ? widget.getTranslation('misc') : item.category}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantity > 1) {
                                      item.quantity--;
                                    } else {
                                      _tempList.removeAt(index);
                                    }
                                  });
                                },
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline,
                                    color: Color(0xFF00A884)),
                                onPressed: () {
                                  setState(() {
                                    item.quantity++;
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep,
                                    color: Colors.redAccent),
                                onPressed: () {
                                  setState(() {
                                    _tempList.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: _tempList.isEmpty
                  ? null
                  : () async {
                      for (var p in _tempList) {
                        await widget.dbService.addProduct(p);
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
              child: Text(
                widget.getTranslation('add_all'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
