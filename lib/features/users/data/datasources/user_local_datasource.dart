import '../models/user_model.dart';

class UserLocalDataSource {
  static final List<UserModel> _users = [];

  List<UserModel> getUsers() {
    if (_users.isEmpty) {
      _initMockData();
    }
    return List.from(_users);
  }

  void addUser(UserModel user) {
    _users.add(user);
  }

  void updateUser(UserModel user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
  }

  void deleteUser(String id) {
    _users.removeWhere((u) => u.id == id);
  }

  void _initMockData() {
    _users.addAll([
      UserModel(
        id: '1',
        name: 'أحمد محمد',
        email: 'ahmed@example.com',
        subscriptionStart: DateTime(2024, 1, 1),
        subscriptionEnd: DateTime(2024, 12, 31),
        isActive: true,
        multiDeviceEnabled: false,
      ),
      UserModel(
        id: '2',
        name: 'سارة علي',
        email: 'sara@example.com',
        subscriptionStart: DateTime(2024, 6, 1),
        subscriptionEnd: DateTime(2024, 6, 30),
        isActive: true,
        multiDeviceEnabled: true,
      ),
      UserModel(
        id: '3',
        name: 'محمد إبراهيم',
        email: 'mohamed@example.com',
        subscriptionStart: DateTime(2024, 3, 1),
        subscriptionEnd: DateTime(2024, 8, 15),
        isActive: false,
        multiDeviceEnabled: false,
      ),
    ]);
  }
}
