// lib/utils/firestore_converter.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore データ変換ユーティリティ
/// Timestamp → DateTime 変換などを提供
class FirestoreConverter {
  /// Firestore Timestamp を ISO8601 文字列に再帰的に変換
  ///
  /// Firestore から取得した Map に含まれる Timestamp を、
  /// PurchaseGroup.fromJson() などで扱える ISO8601 文字列に変換します。
  ///
  /// - Map 内の Timestamp フィールド → ISO8601 文字列
  /// - ネストされた Map も再帰的に処理
  /// - List 内の Timestamp も変換
  static Map<String, dynamic> convertTimestamps(Map<String, dynamic> data) {
    final converted = <String, dynamic>{};

    data.forEach((key, value) {
      if (value is Timestamp) {
        // Timestamp → ISO8601文字列
        converted[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        // ネストされたMapを再帰的に変換
        converted[key] = convertTimestamps(Map<String, dynamic>.from(value));
      } else if (value is List) {
        // Listの要素も変換
        converted[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map) {
            return convertTimestamps(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    });

    return converted;
  }

  /// DateTime を Firestore Timestamp に変換
  static Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }

  /// Firestore Timestamp を DateTime に変換
  static DateTime? timestampToDateTime(Timestamp? timestamp) {
    return timestamp?.toDate();
  }
}
