import 'package:flutter/material.dart';
import 'package:openapi/api.dart' show ApiException, Inventory, LotteryDrawResponse, PrizeGrade;
import '../models/kuji_status.dart';
import '../services/api_service.dart';
import '../widgets/app_error_ui.dart';
import 'payment_page.dart';

// ③ くじ詳細画面
class KujiDetailPage extends StatefulWidget {
  final KujiStatus status;
  final ApiService? apiService;

  const KujiDetailPage({
    super.key,
    required this.status,
    this.apiService,
  });

  @override
  State<KujiDetailPage> createState() => _KujiDetailPageState();
}

class _KujiDetailPageState extends State<KujiDetailPage> {
  late final ApiService _apiService;
  bool _isLoadingInventory = true;
  bool _isDrawing = false;
  String? _inventoryError;
  String? _drawError;
  List<Inventory> _inventories = [];

  bool get _isSoldOut {
    if (_inventories.isEmpty) {
      return widget.status.isSoldOut;
    }
    return _inventories.every((item) => item.remainingCount <= 0);
  }

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _loadInventories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.status.kujiName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('スマホからくじを引いて、当たった景品を店頭で受け取れます。'),
            const SizedBox(height: 20),
            if (_inventoryError != null) ...[
              AppErrorBanner(message: _inventoryError!),
              const SizedBox(height: 12),
            ],
            if (_drawError != null) ...[
              AppErrorBanner(message: _drawError!),
              const SizedBox(height: 12),
            ],
            Text('景品一覧 (${widget.status.shopName})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (_isLoadingInventory)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_inventories.isEmpty)
              const ListTile(title: Text('景品情報を取得できませんでした'))
            else
              ..._inventories.map(_inventoryTile),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSoldOut ? Colors.grey : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSoldOut || _isDrawing || _isLoadingInventory ? null : () => _drawKuji(),
                child: Text(_isSoldOut ? '完売しました' : (_isDrawing ? '抽選中...' : 'くじを引く'), 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prizeTile(String name, int count) {
    return ListTile(
      title: Text(name),
      trailing: Text(count <= 0 ? '終了' : '残り $count', 
        style: TextStyle(color: count <= 0 ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  Widget _inventoryTile(Inventory item) {
    final label = '${item.prizeGrade.value}賞 ${item.prizeName}';
    return _prizeTile(label, item.remainingCount);
  }

  Future<void> _loadInventories() async {
    setState(() {
      _isLoadingInventory = true;
      _inventoryError = null;
    });

    try {
      final storeId = await _resolveStoreId();
      final inventories = await _apiService.fetchStoreInventories(storeId: storeId);
      if (!mounted) return;

      setState(() {
        _inventories = inventories;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = ApiService.inventoryUserMessageFromException(e);
      setState(() {
        _inventoryError = message;
      });
      _showErrorSnackBar(message);
    } catch (_) {
      if (!mounted) return;
      const message = '景品在庫の取得に失敗しました。通信環境を確認してください。';
      setState(() {
        _inventoryError = message;
      });
      _showErrorSnackBar(message);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingInventory = false;
      });
    }
  }

  Future<String> _resolveStoreId() async {
    return _apiService.resolveStoreId(
      preferredStoreId: widget.status.storeId,
      shopName: widget.status.shopName,
      latitude: widget.status.latitude,
      longitude: widget.status.longitude,
      searchRadiusMeter: 1000,
    );
  }

  Future<void> _drawKuji() async {
    setState(() {
      _isDrawing = true;
      _drawError = null;
    });

    try {
      final now = DateTime.now().microsecondsSinceEpoch;
      final storeId = await _resolveStoreId();
      final response = await _apiService.drawLottery(
        storeId: storeId,
        latitude: widget.status.latitude,
        longitude: widget.status.longitude,
        paymentId: 'mock-payment-$now',
        idempotencyKey: 'draw-${widget.status.shopName}-$now',
      );
      if (!mounted) return;

      final resultName = _resolveResultName(response);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            kujiName: widget.status.kujiName,
            resultName: resultName,
            resultId: response.resultId,
          ),
        ),
      );

      await _loadInventories();
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = ApiService.userMessageFromException(e);
      setState(() {
        _drawError = message;
      });
      _showErrorSnackBar(message);
    } catch (_) {
      if (!mounted) return;
      const message = '抽選処理に失敗しました。通信環境を確認して再度お試しください。';
      setState(() {
        _drawError = message;
      });
      _showErrorSnackBar(message);
    } finally {
      if (!mounted) return;
      setState(() {
        _isDrawing = false;
      });
    }
  }

  String _resolveResultName(LotteryDrawResponse response) {
    if (response.prizeName != null && response.prizeName!.trim().isNotEmpty) {
      return response.prizeName!;
    }

    switch (response.prizeGrade) {
      case PrizeGrade.A:
        return 'A賞';
      case PrizeGrade.B:
        return 'B賞';
      case PrizeGrade.C:
        return 'C賞';
      case PrizeGrade.D:
        return 'D賞';
      case PrizeGrade.E:
        return 'E賞';
      case PrizeGrade.F:
        return 'F賞';
      default:
        return '抽選結果';
    }
  }

  void _showErrorSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

}
