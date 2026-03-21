import 'package:flutter/material.dart';
import 'result_page.dart';
// ④ 抽選演出画面
class LotteryAnimationPage extends StatefulWidget {
  final String resultName;
  final String? resultId;

  const LotteryAnimationPage({
    super.key,
    required this.resultName,
    this.resultId,
  });

  @override
  State<LotteryAnimationPage> createState() => _LotteryAnimationPageState();
}

class _LotteryAnimationPageState extends State<LotteryAnimationPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultPage(
              resultName: widget.resultName,
              resultId: widget.resultId,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('くじを引いています…', style: TextStyle(fontSize: 20)),
            Text('結果をお待ちください'),
          ],
        ),
      ),
    );
  }
}