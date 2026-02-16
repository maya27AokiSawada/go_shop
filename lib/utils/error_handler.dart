import '../utils/app_logger.dart';

/// 統一されたエラーハンドリング
class ErrorHandler {
  /// 非同期処理のエラーハンドリング
  ///
  /// 使用例:
  /// ```dart
  /// final result = await ErrorHandler.handleAsync(
  ///   operation: () => someAsyncOperation(),
  ///   context: 'FEATURE_NAME:methodName',
  ///   defaultValue: null,
  /// );
  /// ```
  static Future<T?> handleAsync<T>({
    required Future<T> Function() operation,
    required String context,
    T? defaultValue,
    bool throwOnError = false,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      AppLogger.error('❌ [$context] エラー: $e');
      AppLogger.debug('スタックトレース: $stackTrace');

      // カスタムエラーハンドラーがあれば実行
      onError?.call(e, stackTrace);

      if (throwOnError) {
        rethrow;
      }
      return defaultValue;
    }
  }

  /// 同期処理のエラーハンドリング
  ///
  /// 使用例:
  /// ```dart
  /// final result = ErrorHandler.handleSync(
  ///   operation: () => someSyncOperation(),
  ///   context: 'FEATURE_NAME:methodName',
  ///   defaultValue: false,
  /// );
  /// ```
  static T? handleSync<T>({
    required T Function() operation,
    required String context,
    T? defaultValue,
    bool throwOnError = false,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      AppLogger.error('❌ [$context] エラー: $e');
      AppLogger.debug('スタックトレース: $stackTrace');

      // カスタムエラーハンドラーがあれば実行
      onError?.call(e, stackTrace);

      if (throwOnError) {
        rethrow;
      }
      return defaultValue;
    }
  }

  /// 非同期処理を実行し、成功/失敗を返す
  /// エラーの詳細は不要で、成否だけ知りたい場合に使用
  ///
  /// 使用例:
  /// ```dart
  /// final success = await ErrorHandler.tryAsync(
  ///   operation: () => riskyOperation(),
  ///   context: 'FEATURE_NAME:methodName',
  /// );
  /// if (success) {
  ///   // 成功時の処理
  /// }
  /// ```
  static Future<bool> tryAsync({
    required Future<void> Function() operation,
    required String context,
  }) async {
    try {
      await operation();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('❌ [$context] エラー: $e');
      AppLogger.debug('スタックトレース: $stackTrace');
      return false;
    }
  }

  /// 複数の非同期処理を並列実行し、全ての結果を返す
  /// 一部が失敗しても他の処理は継続される
  ///
  /// 使用例:
  /// ```dart
  /// final results = await ErrorHandler.handleMultiple([
  ///   () => operation1(),
  ///   () => operation2(),
  ///   () => operation3(),
  /// ], context: 'BATCH_OPERATION');
  /// ```
  static Future<List<T?>> handleMultiple<T>(
    List<Future<T> Function()> operations, {
    required String context,
  }) async {
    final results = <T?>[];

    for (int i = 0; i < operations.length; i++) {
      final result = await handleAsync(
        operation: operations[i],
        context: '$context[$i]',
        defaultValue: null,
      );
      results.add(result);
    }

    return results;
  }

  /// エラーオブジェクトから人間が読めるメッセージを抽出
  ///
  /// 使用例:
  /// ```dart
  /// catch (e) {
  ///   final message = ErrorHandler.getErrorMessage(e);
  ///   showSnackBar(message);
  /// }
  /// ```
  static String getErrorMessage(Object error) {
    // Exceptionの場合、メッセージを抽出
    if (error is Exception) {
      final errorString = error.toString();
      // "Exception: メッセージ" の形式から "メッセージ" を抽出
      if (errorString.startsWith('Exception: ')) {
        return errorString.substring(11); // "Exception: " の長さ = 11
      }
      // "Exception" だけの場合
      return '予期しないエラーが発生しました';
    }

    // その他のエラー型
    return error.toString();
  }
}
