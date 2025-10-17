import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ad_service.dart';

/// ニュース・情報表示ページ
class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});

  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final adService = ref.read(adServiceProvider);
    final position = await adService.getCurrentLocation();
    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ニュース・特売情報'),
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade800,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 位置情報表示
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.orange.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        '現在地周辺の情報',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingLocation)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('位置情報を取得中...'),
                      ],
                    )
                  else if (_currentPosition != null)
                    Text(
                      '緯度: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                      '経度: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  else
                    Text(
                      '位置情報が取得できませんでした',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 地域広告ウィジェット
          const LocalNewsAdWidget(),
          
          const SizedBox(height: 16),
          
          // サンプルニュース項目
          _buildNewsCard(
            title: '🛒 買い物のコツ',
            subtitle: 'まとめ買いで節約効果UP',
            description: 'リストを活用して計画的な買い物を心がけましょう。重複購入を避けることで月3,000円の節約も可能です。',
            color: Colors.blue.shade50,
            iconColor: Colors.blue.shade600,
          ),
          
          _buildNewsCard(
            title: '📊 家計管理術',
            subtitle: '支出の見える化で無駄を削減',
            description: 'Go Shopの統計機能を使って、カテゴリ別の支出傾向を把握しましょう。',
            color: Colors.green.shade50,
            iconColor: Colors.green.shade600,
          ),
          
          _buildNewsCard(
            title: '🏪 近隣店舗情報',
            subtitle: 'お得な特売情報をチェック',
            description: '位置情報を許可すると、お近くの店舗の特売情報をお届けします。',
            color: Colors.orange.shade50,
            iconColor: Colors.orange.shade600,
          ),
          
          // 2つ目の広告エリア（下部）
          const SizedBox(height: 16),
          const LocalNewsAdWidget(),
          
          // 追加のコンテンツ
          _buildNewsCard(
            title: '🎯 効率的な買い物ルート',
            subtitle: '店内での移動時間を短縮',
            description: 'カテゴリ別にリストを整理することで、店内での無駄な移動を減らせます。',
            color: Colors.purple.shade50,
            iconColor: Colors.purple.shade600,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNewsCard({
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: iconColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ニュースタブ用のプロバイダー
final newsPageProvider = Provider<NewsPage>((ref) => const NewsPage());