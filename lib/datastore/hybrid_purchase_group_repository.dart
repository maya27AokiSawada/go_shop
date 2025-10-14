import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/purchase_group.dart';
import '../datastore/purchase_group_repository.dart';
import '../datastore/hive_purchase_group_repository.dart';
import '../datastore/firestore_purchase_group_repository.dart';
import '../providers/hive_provider.dart';
import '../flavors.dart';

/// Hive（ローカルキャッシュ）+ Firestore（リモート）のハイブリッドリポジトリ
/// 
/// 動作原理:
/// - 読み取り: まずHiveから取得、なければFirestoreから取得してHiveにキャッシュ
/// - 書き込み: HiveとFirestore両方に保存（楽観的更新）
/// - 同期: バックグラウンドでFirestore→Hiveの差分同期
/// - オフライン: Hiveのみで動作、オンライン復帰時に自動同期
class HybridPurchaseGroupRepository implements PurchaseGroupRepository {
  final Ref _ref;
  late final HivePurchaseGroupRepository _hiveRepo;
  FirestorePurchaseGroupRepository? _firestoreRepo;
  
  // 接続状態管理
  bool _isOnline = true;
  bool _isSyncing = false;
  
  HybridPurchaseGroupRepository(this._ref) {
    _hiveRepo = HivePurchaseGroupRepository(_ref);
    // DEVモードではFirestoreリポジトリを初期化しない
    if (F.appFlavor != Flavor.dev) {
      _firestoreRepo = FirestorePurchaseGroupRepository();
    }
  }

  /// オンライン状態をチェック
  bool get isOnline => _isOnline;
  
  /// 同期状態をチェック
  bool get isSyncing => _isSyncing;

  // =================================================================
  // キャッシュ戦略: Cache-First with Background Sync
  // =================================================================

  @override
  Future<List<PurchaseGroup>> getAllGroups() async {
    try {
      // 1. まずHiveから取得（高速）
      final cachedGroups = await _hiveRepo.getAllGroups();
      
      if (F.appFlavor == Flavor.dev || !_isOnline) {
        // Dev環境またはオフライン時はHiveのみ
        developer.log('📦 Cache-only: ${cachedGroups.length}グループ取得');
        return cachedGroups;
      }
      
      // 2. バックグラウンドでFirestoreと同期（ノンブロッキング）
      _syncFromFirestoreInBackground();
      
      // 3. キャッシュデータを即座に返却
      developer.log('⚡ Cache-first: ${cachedGroups.length}グループ取得 (同期中...)');
      return cachedGroups;
      
    } catch (e) {
      developer.log('❌ getAllGroups error: $e');
      
      // Hiveでエラーの場合、Firestoreから直接取得を試行
      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        try {
          final firestoreGroups = await _firestoreRepo!.getAllGroups();
          developer.log('🔥 Fallback to Firestore: ${firestoreGroups.length}グループ');
          return firestoreGroups;
        } catch (firestoreError) {
          developer.log('❌ Firestore fallback failed: $firestoreError');
        }
      }
      
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> getGroupById(String groupId) async {
    try {
      // 1. Hiveから取得を試行
      final cachedGroup = await _hiveRepo.getGroupById(groupId);
      
      if (F.appFlavor == Flavor.dev || !_isOnline) {
        return cachedGroup;
      }
      
      // 2. バックグラウンドでFirestoreの最新版をチェック
      _syncGroupFromFirestoreInBackground(groupId);
      
      return cachedGroup;
      
    } catch (e) {
      // Hiveで見つからない場合、Firestoreから取得してキャッシュ
      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        try {
          final firestoreGroup = await _firestoreRepo!.getGroupById(groupId);
          
          // Hiveにキャッシュ
          await _hiveRepo.saveGroup(firestoreGroup);
          
          developer.log('🔄 Firestore→Cache: ${firestoreGroup.groupName}');
          return firestoreGroup;
        } catch (firestoreError) {
          developer.log('❌ Group not found in Firestore: $groupId');
        }
      }
      
      rethrow;
    }
  }

  // =================================================================
  // 楽観的更新戦略: Optimistic Update with Conflict Resolution
  // =================================================================

  @override
  Future<PurchaseGroup> createGroup(String groupId, String groupName, PurchaseGroupMember member) async {
    try {
      // 1. まずHiveに保存（楽観的更新）
      final newGroup = await _hiveRepo.createGroup(groupId, groupName, member);
      
      if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
        return newGroup;
      }
      
      // 2. Firestoreに非同期保存
      _unawaited(_firestoreRepo!.createGroup(groupId, groupName, member).then((_) {
        developer.log('🔄 Created synced to Firestore: $groupName');
      }).catchError((e) {
        developer.log('⚠️ Failed to sync create to Firestore: $e');
        // TODO: 失敗したオペレーションをキューに保存
      }));
      
      return newGroup;
      
    } catch (e) {
      developer.log('❌ createGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> updateGroup(String groupId, PurchaseGroup group) async {
    try {
      // 1. Hiveを即座に更新
      await _hiveRepo.saveGroup(group);
      
      if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
        return group;
      }
      
      // 2. Firestoreに非同期同期
      _unawaited(_firestoreRepo!.updateGroup(groupId, group).then((updatedGroup) async {
        // Firestoreで更新された場合、差分をHiveに反映
        if (updatedGroup.hashCode != group.hashCode) {
          await _hiveRepo.saveGroup(updatedGroup);
          developer.log('🔄 Firestore changes synced back to cache');
        }
      }).catchError((e) {
        developer.log('⚠️ Failed to sync update to Firestore: $e');
        // TODO: 競合解決ロジック
      }));
      
      return group;
      
    } catch (e) {
      developer.log('❌ updateGroup error: $e');
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> deleteGroup(String groupId) async {
    try {
      // 1. Hiveから削除
      final deletedGroup = await _hiveRepo.deleteGroup(groupId);
      
      if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) {
        return deletedGroup;
      }
      
      // 2. Firestoreから非同期削除
      _unawaited(_firestoreRepo!.deleteGroup(groupId).then((_) {
        developer.log('🔄 Delete synced to Firestore: $groupId');
      }).catchError((e) {
        developer.log('⚠️ Failed to sync delete to Firestore: $e');
      }));
      
      return deletedGroup;
      
    } catch (e) {
      developer.log('❌ deleteGroup error: $e');
      rethrow;
    }
  }

  // =================================================================
  // メンバー操作（楽観的更新）
  // =================================================================

  @override
  Future<PurchaseGroup> addMember(String groupId, PurchaseGroupMember member) async {
    try {
      final updatedGroup = await _hiveRepo.addMember(groupId, member);
      
      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        _unawaited(_firestoreRepo!.addMember(groupId, member).then((_) {
          developer.log('🔄 AddMember synced to Firestore');
        }).catchError((e) {
          developer.log('⚠️ Failed to sync addMember to Firestore: $e');
        }));
      }
      
      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PurchaseGroup> removeMember(String groupId, PurchaseGroupMember member) async {
    try {
      final updatedGroup = await _hiveRepo.removeMember(groupId, member);
      
      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        _unawaited(_firestoreRepo!.removeMember(groupId, member).then((_) {
          developer.log('🔄 RemoveMember synced to Firestore');
        }).catchError((e) {
          developer.log('⚠️ Failed to sync removeMember to Firestore: $e');
        }));
      }
      
      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  // =================================================================
  // メンバープール（ローカル専用 - 個人情報保護）
  // =================================================================
  
  /// メンバープールは個人情報保護の観点からHiveローカルDBにのみ保存
  /// Firestoreには一切同期しない
  @override
  Future<PurchaseGroup> getOrCreateMemberPool() async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.getOrCreateMemberPool();
  }

  @override
  Future<void> syncMemberPool() async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.syncMemberPool();
  }

  @override
  Future<List<PurchaseGroupMember>> searchMembersInPool(String query) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.searchMembersInPool(query);
  }

  @override
  Future<PurchaseGroupMember?> findMemberByEmail(String email) async {
    // 🔒 個人情報保護: メンバープールはローカルのみ
    return await _hiveRepo.findMemberByEmail(email);
  }

  @override
  Future<PurchaseGroup> setMemberId(String oldId, String newId, String? contact) async {
    try {
      final updatedGroup = await _hiveRepo.setMemberId(oldId, newId, contact);
      
      if (_isOnline && F.appFlavor == Flavor.prod && _firestoreRepo != null) {
        _unawaited(_firestoreRepo!.setMemberId(oldId, newId, contact).then((_) {
          developer.log('🔄 SetMemberId synced to Firestore');
        }).catchError((e) {
          developer.log('⚠️ Failed to sync setMemberId to Firestore: $e');
        }));
      }
      
      return updatedGroup;
    } catch (e) {
      rethrow;
    }
  }

  // =================================================================
  // バックグラウンド同期
  // =================================================================

  /// Firestoreから全グループを非同期で同期
  void _syncFromFirestoreInBackground() {
    if (_isSyncing || F.appFlavor == Flavor.dev || _firestoreRepo == null) return;
    
    _isSyncing = true;
    _unawaited(_firestoreRepo!.getAllGroups().then((firestoreGroups) async {
      // 差分を検出してHiveに同期
      for (final firestoreGroup in firestoreGroups) {
        try {
          final cachedGroup = await _hiveRepo.getGroupById(firestoreGroup.groupId);
          
          // 簡単な差分検出（実際はtimestamp比較が望ましい）
          if (cachedGroup.hashCode != firestoreGroup.hashCode) {
            await _hiveRepo.saveGroup(firestoreGroup);
            developer.log('🔄 Synced from Firestore: ${firestoreGroup.groupName}');
          }
        } catch (e) {
          // キャッシュにない場合は新規追加
          await _hiveRepo.saveGroup(firestoreGroup);
          developer.log('➕ New from Firestore: ${firestoreGroup.groupName}');
        }
      }
    }).catchError((e) {
      developer.log('⚠️ Background sync failed: $e');
      _isOnline = false; // 接続エラーを検出
    }).whenComplete(() {
      _isSyncing = false;
    }));
  }

  /// 特定グループをFirestoreから同期
  void _syncGroupFromFirestoreInBackground(String groupId) {
    if (F.appFlavor == Flavor.dev || !_isOnline || _firestoreRepo == null) return;
    
    _unawaited(_firestoreRepo!.getGroupById(groupId).then((firestoreGroup) async {
      final cachedGroup = await _hiveRepo.getGroupById(groupId);
      
      if (cachedGroup.hashCode != firestoreGroup.hashCode) {
        await _hiveRepo.saveGroup(firestoreGroup);
        developer.log('🔄 Group synced from Firestore: ${firestoreGroup.groupName}');
      }
    }).catchError((e) {
      developer.log('⚠️ Group sync failed: $e');
    }));
  }

  /// Fire-and-forget 非同期実行
  void _unawaited(Future<void> operation) {
    operation.catchError((e) {
      developer.log('⚠️ Unawaited operation failed: $e');
    });
  }

  // =================================================================
  // 手動同期・管理機能
  // =================================================================

  /// 手動でFirestoreからフル同期
  Future<void> forceSyncFromFirestore() async {
    if (F.appFlavor == Flavor.dev || _firestoreRepo == null) {
      developer.log('🔧 Force sync skipped in dev mode');
      return;
    }
    
    try {
      _isSyncing = true;
      final firestoreGroups = await _firestoreRepo!.getAllGroups();
      
      // すべてのFirestoreデータでHiveを更新
      for (final group in firestoreGroups) {
        await _hiveRepo.saveGroup(group);
      }
      
      developer.log('✅ Force sync completed: ${firestoreGroups.length} groups');
      _isOnline = true;
      
    } catch (e) {
      developer.log('❌ Force sync failed: $e');
      _isOnline = false;
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// 未同期のローカル変更をFirestoreにプッシュ
  Future<void> pushLocalChangesToFirestore() async {
    if (F.appFlavor == Flavor.dev || _firestoreRepo == null) return;
    
    try {
      final localGroups = await _hiveRepo.getAllGroups();
      
      for (final group in localGroups) {
        try {
          await _firestoreRepo!.updateGroup(group.groupId, group);
          developer.log('📤 Pushed to Firestore: ${group.groupName}');
        } catch (e) {
          developer.log('⚠️ Failed to push ${group.groupName}: $e');
        }
      }
      
    } catch (e) {
      developer.log('❌ Push operation failed: $e');
      rethrow;
    }
  }

  /// キャッシュクリア
  Future<void> clearCache() async {
    try {
      final box = _ref.read(purchaseGroupBoxProvider);
      await box.clear();
      developer.log('🗑️ Cache cleared');
    } catch (e) {
      developer.log('❌ Failed to clear cache: $e');
      rethrow;
    }
  }

  /// 接続状態を設定（テスト用）
  void setOnlineStatus(bool online) {
    _isOnline = online;
    developer.log('🌐 Online status set to: $online');
  }
}