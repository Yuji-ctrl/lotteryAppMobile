import 'package:flutter/material.dart';
import 'package:openapi/api.dart'
    show ApiException, LotteryResult, LotteryResultDetail;

import '../services/api_service.dart';
import 'exchange_page.dart';

// ⑤ 結果画面
class ResultPage extends StatefulWidget {
  final String resultName;
  final String? resultId;
  final ApiService? apiService;

  const ResultPage({
    super.key,
    required this.resultName,
    this.resultId,
    this.apiService,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late final ApiService _apiService;

  bool _isLoadingHistory = true;
  bool _isLoadingDetail = false;
  String? _historyError;
  String? _detailError;

  List<LotteryResult> _history = const [];
  String? _selectedResultId;
  LotteryResultDetail? _selectedDetail;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('抽選結果')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWinningHeader(),
            const SizedBox(height: 16),
            Expanded(child: _buildHistoryAndDetail()),
            const SizedBox(height: 12),
            const Text(
              'この画面を店舗スタッフに見せてください',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExchangePage()),
                ),
                child: const Text('景品を受け取る'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWinningHeader() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            children: [
              const Text(
                '当たり',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '🎉 ${widget.resultName} 当選 🎉',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryAndDetail() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyError != null && _history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_historyError!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadHistory, child: const Text('再試行')),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return const Center(child: Text('履歴がありません'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '履歴から詳細を確認できます',
          style: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _history.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _history[index];
              final selected = item.resultId == _selectedResultId;
              return ListTile(
                selected: selected,
                title: Text('${item.prizeGrade.value}賞 / ${item.status.value}'),
                subtitle: Text(_formatDate(item.createdAt)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _loadDetail(item.resultId),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailCard(),
      ],
    );
  }

  Widget _buildDetailCard() {
    if (_isLoadingDetail) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_detailError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_detailError!),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _selectedResultId == null
                    ? null
                    : () => _loadDetail(_selectedResultId!),
                child: const Text('詳細を再取得'),
              ),
            ],
          ),
        ),
      );
    }

    final detail = _selectedDetail;
    if (detail == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('履歴を選択すると詳細を表示します'),
        ),
      );
    }

    final prizeName = detail.prizeName?.trim().isNotEmpty == true
        ? detail.prizeName!
        : '${detail.prizeGrade.value}賞';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '結果詳細',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('景品: $prizeName'),
            Text('ステータス: ${detail.status.value}'),
            Text('店舗ID: ${detail.storeId}'),
            if (detail.store != null) Text('店舗名: ${detail.store!.storeName}'),
            Text('結果ID: ${detail.resultId}'),
            Text('抽選日時: ${_formatDate(detail.createdAt)}'),
          ],
        ),
      ),
    );
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });

    try {
      final history = await _apiService.fetchLotteryResults(limit: 20);
      if (!mounted) return;

      String? targetId;
      if (widget.resultId != null &&
          history.any((item) => item.resultId == widget.resultId)) {
        targetId = widget.resultId;
      } else if (history.isNotEmpty) {
        targetId = history.first.resultId;
      }

      setState(() {
        _history = history;
        _selectedResultId = targetId;
      });

      if (targetId != null) {
        await _loadDetail(targetId, showLoading: false);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = ApiService.lotteryResultUserMessageFromException(e);
      setState(() {
        _historyError = message;
      });
      _showErrorSnackBar(message);
    } catch (_) {
      if (!mounted) return;
      const message = '抽選履歴の取得に失敗しました。通信環境を確認して再度お試しください。';
      setState(() {
        _historyError = message;
      });
      _showErrorSnackBar(message);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadDetail(String resultId, {bool showLoading = true}) async {
    setState(() {
      _selectedResultId = resultId;
      if (showLoading) {
        _isLoadingDetail = true;
      }
      _detailError = null;
    });

    try {
      final detail = await _apiService.fetchLotteryResultDetail(
        resultId: resultId,
      );
      if (!mounted) return;
      setState(() {
        _selectedDetail = detail;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = ApiService.lotteryResultUserMessageFromException(e);
      setState(() {
        _detailError = message;
      });
      _showErrorSnackBar(message);
    } catch (_) {
      if (!mounted) return;
      const message = '抽選結果詳細の取得に失敗しました。通信環境を確認して再度お試しください。';
      setState(() {
        _detailError = message;
      });
      _showErrorSnackBar(message);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingDetail = false;
      });
    }
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  void _showErrorSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
