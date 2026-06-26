// lib/features/users/domain/usecases/toggle_screenshot.dart

import 'package:dartz/dartz.dart';
import '../repositories/user_repository.dart';

class ToggleScreenshot {
  final UserRepository repository;

  ToggleScreenshot(this.repository);

  Future<Either<Failure, void>> call(int userId, bool currentStatus) {
    return repository.toggleScreenshot(userId, currentStatus);
  }
}
