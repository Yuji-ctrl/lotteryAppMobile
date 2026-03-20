import 'package:flutter/material.dart';
import '../../models/kuji_status.dart';
import '../detail_page.dart';

class ListTab extends StatefulWidget {
  final List<KujiStatus> shops;
  final VoidCallback onRefresh;

  const ListTab({super.key, required this.shops, required this.onRefresh});

  @override
  State<ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<ListTab> {
  String _searchQuery = '';
  bool _hideSoldOut = false;
  String _sortBy = 'name'; // 'name' or 'kuji'

  @override
  Widget build(BuildContext context) {
    // フィルター＆検索
    var filteredShops = widget.shops.where((shop) {
      if (_hideSoldOut && shop.isSoldOut) return false;
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return shop.shopName.toLowerCase().contains(q) ||
          shop.kujiName.toLowerCase().contains(q);
    }).toList();

    // ソート
    filteredShops.sort((a, b) {
      if (_sortBy == 'name') {
        return a.shopName.compareTo(b.shopName);
      } else {
        return a.kujiName.compareTo(b.kujiName);
      }
    });

    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: ListView.builder(
            itemCount: filteredShops.length,
            itemBuilder: (context, index) {
              final shop = filteredShops[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                color: shop.isSoldOut ? Colors.grey[300] : Colors.white,
                child: ListTile(
                  title: Text(
                    shop.shopName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '開催中：${shop.kujiName}${shop.isSoldOut ? " (完売)" : ""}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: shop.isSoldOut
                        ? null
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    KujiDetailPage(status: shop),
                              ),
                            );
                            widget.onRefresh();
                          },
                    child: Text(shop.isSoldOut ? '完売' : 'くじを見る'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: '店舗名・くじ名で検索',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FilterChip(
                        label: const Text('完売を非表示'),
                        selected: _hideSoldOut,
                        onSelected: (val) {
                          setState(() => _hideSoldOut = val);
                        },
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('並び替え：'),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _sortBy,
                            isDense: true,
                            items: const [
                              DropdownMenuItem(
                                value: 'name',
                                child: Text('店舗名'),
                              ),
                              DropdownMenuItem(
                                value: 'kuji',
                                child: Text('くじ名'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _sortBy = val);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
