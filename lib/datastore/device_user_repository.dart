import 'package:go_shopping/models/device_user.dart';
import 'package:hive/hive.dart';

class DeviceUserRepository {
  static const String _boxName = 'device_user';

  Future<Box<DeviceUser>> _openBox() async {
    return await Hive.openBox<DeviceUser>(_boxName);
  }

  Future<DeviceUser?> getUser() async {
    final box = await _openBox();
    return box.get('current_user');
  }

  Future<void> saveUser(DeviceUser user) async {
    final box = await _openBox();
    await box.put('current_user', user);
  }
}
