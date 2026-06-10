import '../models/user_model.dart';

class UserLocalDataSource {
  static final List<UserModel> _users = [];

  List<UserModel> getUsers() {
    if (_users.isEmpty) {}
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

  void deleteUser(int id) {
    _users.removeWhere((u) => u.id == id);
  }
}
