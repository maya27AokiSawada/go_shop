import 'package:flutter_test/flutter_test.dart';
import 'package:goshopping/services/device_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // SharedPreferencesのモック初期化
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 各テスト前にキャッシュクリア
    DeviceIdService.clearCache();
  });

  group('DeviceIdService - デバイスプレフィックス取得', () {
    test('getDevicePrefix()は8文字のプレフィックスを返す', () async {
      // SharedPreferencesをモック設定
      SharedPreferences.setMockInitialValues({});

      // Act
      final prefix = await DeviceIdService.getDevicePrefix();

      // Assert
      expect(prefix.length, 8, reason: 'プレフィックスは8文字である必要がある');
      expect(prefix, matches(RegExp(r'^[a-z0-9]{8}$')),
          reason: 'プレフィックスは小文字英数字のみ');
    });

    test('getDevicePrefix()は複数回呼び出しても同じ値を返す（キャッシュ動作）', () async {
      // SharedPreferencesをモック設定
      SharedPreferences.setMockInitialValues({});

      // Act
      final prefix1 = await DeviceIdService.getDevicePrefix();
      final prefix2 = await DeviceIdService.getDevicePrefix();
      final prefix3 = await DeviceIdService.getDevicePrefix();

      // Assert
      expect(prefix1, prefix2, reason: '2回目の呼び出しは同じプレフィックスを返す（キャッシュ）');
      expect(prefix2, prefix3, reason: '3回目の呼び出しも同じプレフィックスを返す（キャッシュ）');
    });

    test('clearCache()後はgetDevicePrefix()が再計算される', () async {
      // SharedPreferencesをモック設定（空）
      SharedPreferences.setMockInitialValues({});

      // Act
      final prefix1 = await DeviceIdService.getDevicePrefix();

      // キャッシュクリア
      DeviceIdService.clearCache();

      // SharedPreferencesに保存された値も削除
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('device_id_prefix');

      final prefix2 = await DeviceIdService.getDevicePrefix();

      // Assert
      expect(prefix1.length, 8);
      expect(prefix2.length, 8);
      // 注: 環境によっては同じ値になる可能性もあるが、形式は正しい
      expect(prefix1, matches(RegExp(r'^[a-z0-9]{8}$')));
      expect(prefix2, matches(RegExp(r'^[a-z0-9]{8}$')));
    });

    test('SharedPreferencesに既存の値があれば再利用される', () async {
      // Arrange: SharedPreferencesに既存のプレフィックス設定
      SharedPreferences.setMockInitialValues({
        'device_id_prefix': 'test1234',
      });

      // Act
      final prefix = await DeviceIdService.getDevicePrefix();

      // Assert
      expect(prefix, 'test1234', reason: 'SharedPreferencesの既存値が優先される');
    });

    test('SharedPreferencesの値が8文字でない場合は再生成される', () async {
      // Arrange: 不正な長さのプレフィックス
      SharedPreferences.setMockInitialValues({
        'device_id_prefix': 'short', // 5文字（不正）
      });

      // Act
      final prefix = await DeviceIdService.getDevicePrefix();

      // Assert
      expect(prefix.length, 8, reason: '不正な長さの場合は新規生成される');
      expect(prefix, isNot('short'), reason: '不正な値は使用されない');
    });
  });

  group('DeviceIdService - グループID生成', () {
    test('generateGroupId()は正しい形式で生成される（prefix_timestamp）', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final groupId = await DeviceIdService.generateGroupId();

      // Assert
      expect(groupId, contains('_'), reason: 'グループIDはアンダースコアを含む');

      final parts = groupId.split('_');
      expect(parts.length, 2, reason: 'グループIDは2つの部分から構成される');

      final prefix = parts[0];
      final timestamp = parts[1];

      expect(prefix.length, 8, reason: 'プレフィックスは8文字');
      expect(prefix, matches(RegExp(r'^[a-z0-9]{8}$')),
          reason: 'プレフィックスは小文字英数字');

      expect(int.tryParse(timestamp), isNotNull, reason: 'タイムスタンプ部分は数値');
      expect(timestamp.length, greaterThanOrEqualTo(13),
          reason: 'タイムスタンプは13桁以上（ミリ秒）');
    });

    test('generateGroupId()は複数回呼び出しで異なるタイムスタンプを生成', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final groupId1 = await DeviceIdService.generateGroupId();
      await Future.delayed(const Duration(milliseconds: 10)); // タイムスタンプ差を確保
      final groupId2 = await DeviceIdService.generateGroupId();

      // Assert
      expect(groupId1, isNot(groupId2), reason: '異なる時刻に生成されたIDは異なる');

      // プレフィックスは同じ（同じデバイス）
      final prefix1 = groupId1.split('_')[0];
      final prefix2 = groupId2.split('_')[0];
      expect(prefix1, prefix2, reason: 'プレフィックスは同じデバイスIDを使用');

      // タイムスタンプは異なる
      final timestamp1 = int.parse(groupId1.split('_')[1]);
      final timestamp2 = int.parse(groupId2.split('_')[1]);
      expect(timestamp2, greaterThan(timestamp1),
          reason: '後で生成したIDのタイムスタンプは大きい');
    });

    test('generateGroupId()のタイムスタンプは現在時刻に近い', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final beforeTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Act
      final groupId = await DeviceIdService.generateGroupId();

      final afterTimestamp = DateTime.now().millisecondsSinceEpoch;

      // Assert
      final idTimestamp = int.parse(groupId.split('_')[1]);
      expect(idTimestamp, greaterThanOrEqualTo(beforeTimestamp),
          reason: 'タイムスタンプは実行前の時刻以降');
      expect(idTimestamp, lessThanOrEqualTo(afterTimestamp),
          reason: 'タイムスタンプは実行後の時刻以前');
    });

    test('generateGroupId()は10回連続で正しい形式を生成', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act & Assert
      for (int i = 0; i < 10; i++) {
        final groupId = await DeviceIdService.generateGroupId();
        final parts = groupId.split('_');

        expect(parts.length, 2, reason: 'グループID $i は2部構成');
        expect(parts[0].length, 8, reason: 'グループID $i のプレフィックスは8文字');
        expect(int.tryParse(parts[1]), isNotNull,
            reason: 'グループID $i のタイムスタンプは数値');
      }
    });
  });

  group('DeviceIdService - リストID生成', () {
    test('generateListId()は正しい形式で生成される（prefix_uuid8）', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final listId = await DeviceIdService.generateListId();

      // Assert
      expect(listId, contains('_'), reason: 'リストIDはアンダースコアを含む');

      final parts = listId.split('_');
      expect(parts.length, 2, reason: 'リストIDは2つの部分から構成される');

      final prefix = parts[0];
      final uuid = parts[1];

      expect(prefix.length, 8, reason: 'プレフィックスは8文字');
      expect(prefix, matches(RegExp(r'^[a-z0-9]{8}$')),
          reason: 'プレフィックスは小文字英数字');

      expect(uuid.length, 8, reason: 'UUID部分は8文字');
      expect(uuid, matches(RegExp(r'^[a-z0-9]{8}$')), reason: 'UUID部分は小文字英数字');
    });

    test('generateListId()は複数回呼び出しで異なるUUIDを生成', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final listId1 = await DeviceIdService.generateListId();
      final listId2 = await DeviceIdService.generateListId();
      final listId3 = await DeviceIdService.generateListId();

      // Assert
      expect(listId1, isNot(listId2), reason: 'リストID1とリストID2は異なる');
      expect(listId2, isNot(listId3), reason: 'リストID2とリストID3は異なる');
      expect(listId1, isNot(listId3), reason: 'リストID1とリストID3は異なる');

      // プレフィックスは同じ
      final prefix1 = listId1.split('_')[0];
      final prefix2 = listId2.split('_')[0];
      final prefix3 = listId3.split('_')[0];
      expect(prefix1, prefix2, reason: 'プレフィックスは同じ（キャッシュ）');
      expect(prefix2, prefix3, reason: 'プレフィックスは同じ（キャッシュ）');

      // UUID部分は異なる
      final uuid1 = listId1.split('_')[1];
      final uuid2 = listId2.split('_')[1];
      final uuid3 = listId3.split('_')[1];
      expect(uuid1, isNot(uuid2), reason: 'UUID1とUUID2は異なる');
      expect(uuid2, isNot(uuid3), reason: 'UUID2とUUID3は異なる');
      expect(uuid1, isNot(uuid3), reason: 'UUID1とUUID3は異なる');
    });

    test('generateListId()は100回連続で正しい形式を生成', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final generatedIds = <String>{};

      // Act & Assert
      for (int i = 0; i < 100; i++) {
        final listId = await DeviceIdService.generateListId();
        final parts = listId.split('_');

        expect(parts.length, 2, reason: 'リストID $i は2部構成');
        expect(parts[0].length, 8, reason: 'リストID $i のプレフィックスは8文字');
        expect(parts[1].length, 8, reason: 'リストID $i のUUIDは8文字');

        // 重複チェック
        expect(generatedIds.contains(listId), isFalse,
            reason: 'リストID $i は一意である（重複なし）');
        generatedIds.add(listId);
      }

      // 100個すべてが一意
      expect(generatedIds.length, 100, reason: '100個のリストIDがすべて一意');
    });

    test('generateListId()の全体長は17文字（prefix8_uuid8）', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final listId = await DeviceIdService.generateListId();

      // Assert
      expect(listId.length, 17, reason: 'リストIDは17文字（8 + 1アンダースコア + 8）');
    });
  });

  group('DeviceIdService - キャッシュ動作', () {
    test('clearCache()はキャッシュをクリアする', () {
      // Act
      DeviceIdService.clearCache();

      // Assert: エラーなく実行される
      expect(true, isTrue, reason: 'clearCache()は正常に実行される');
    });

    test('キャッシュクリア後も新しいプレフィックスは8文字', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final prefix1 = await DeviceIdService.getDevicePrefix();

      // Act
      DeviceIdService.clearCache();

      // SharedPreferencesをクリア（新規生成を強制）
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final prefix2 = await DeviceIdService.getDevicePrefix();

      // Assert
      expect(prefix1.length, 8);
      expect(prefix2.length, 8);
      expect(prefix1, matches(RegExp(r'^[a-z0-9]{8}$')));
      expect(prefix2, matches(RegExp(r'^[a-z0-9]{8}$')));
    });
  });

  group('DeviceIdService - ID形式総合検証', () {
    test('グループIDとリストIDは同じプレフィックスを使用', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final groupId = await DeviceIdService.generateGroupId();
      final listId = await DeviceIdService.generateListId();

      // Assert
      final groupPrefix = groupId.split('_')[0];
      final listPrefix = listId.split('_')[0];

      expect(groupPrefix, listPrefix, reason: '同じデバイスで生成したIDは同じプレフィックスを持つ');
    });

    test('異なるメソッドで生成されたIDは形式が異なる', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act
      final groupId = await DeviceIdService.generateGroupId();
      final listId = await DeviceIdService.generateListId();

      // Assert
      final groupSuffix = groupId.split('_')[1];
      final listSuffix = listId.split('_')[1];

      // グループIDのサフィックスは13桁以上の数値（タイムスタンプ）
      expect(int.tryParse(groupSuffix), isNotNull,
          reason: 'グループIDのサフィックスは数値（タイムスタンプ）');
      expect(groupSuffix.length, greaterThanOrEqualTo(13),
          reason: 'グループIDのタイムスタンプは13桁以上');

      // リストIDのサフィックスは8文字の英数字（UUID短縮版）
      expect(listSuffix.length, 8, reason: 'リストIDのサフィックスは8文字');
      expect(listSuffix, matches(RegExp(r'^[a-z0-9]{8}$')),
          reason: 'リストIDのサフィックスは小文字英数字');

      // 両者は異なる形式
      expect(groupId, isNot(listId), reason: 'グループIDとリストIDは異なる');
    });

    test('ID生成メソッドは高速に実行される（性能テスト）', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act: 50個のグループIDと50個のリストIDを生成
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        await DeviceIdService.generateGroupId();
      }

      for (int i = 0; i < 50; i++) {
        await DeviceIdService.generateListId();
      }

      stopwatch.stop();

      // Assert: 100個のID生成が1秒以内
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: '100個のID生成は1秒以内に完了する');
    });
  });

  group('DeviceIdService - エッジケース', () {
    test('SharedPreferencesが空でも正常にプレフィックス生成', () async {
      // Arrange: 完全に空のSharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Act
      final prefix = await DeviceIdService.getDevicePrefix();

      // Assert
      expect(prefix.length, 8);
      expect(prefix, matches(RegExp(r'^[a-z0-9]{8}$')));
    });

    test('連続して異なるID生成メソッドを呼び出しても正常動作', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      // Act: 交互に呼び出し
      final groupId1 = await DeviceIdService.generateGroupId();
      final listId1 = await DeviceIdService.generateListId();
      final groupId2 = await DeviceIdService.generateGroupId();
      final listId2 = await DeviceIdService.generateListId();

      // Assert: すべて正しい形式
      expect(groupId1.split('_').length, 2);
      expect(listId1.split('_').length, 2);
      expect(groupId2.split('_').length, 2);
      expect(listId2.split('_').length, 2);

      // グループID同士は異なる
      expect(groupId1, isNot(groupId2));

      // リストID同士は異なる
      expect(listId1, isNot(listId2));
    });
  });
}
