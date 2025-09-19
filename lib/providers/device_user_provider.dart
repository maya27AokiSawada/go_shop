import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../datastore/device_user_repository.dart';
import '../models/device_user.dart';

final deviceUserProvider = StateNotifierProvider<DeviceUserNotifier, DeviceUser?>((ref) {
  return DeviceUserNotifier(ref);
});

class DeviceUserNotifier extends StateNotifier<DeviceUser?> {
  final Ref _ref;
  DeviceUserNotifier(this._ref) : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final repository = _ref.read(deviceUserRepositoryProvider);
    final user = await repository.getUser();
    state = user;
  }

  Future<void> saveUser(DeviceUser user) async {
    final repository = _ref.read(deviceUserRepositoryProvider);
    await repository.saveUser(user);
    state = user;
  }
}
final deviceUserRepositoryProvider = Provider<DeviceUserRepository>((ref) {
  return DeviceUserRepository();
});  
