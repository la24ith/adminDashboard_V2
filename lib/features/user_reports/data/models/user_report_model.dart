enum SubscriptionStatus { active, expired, expiringSoon }

enum CommitmentStatus { yes, no, pending }

class WeightRecord {
  final DateTime date;
  final double weight;

  WeightRecord({required this.date, required this.weight});
}

class UserReport {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final double currentWeight;
  final double goalWeight;
  final double initialWeight;
  final List<WeightRecord> weightHistory;
  final List<CommitmentStatus> dailyCommitments;
  final bool isAchievedGoal;
  final SubscriptionStatus subscriptionStatus;
  final DateTime subscriptionEndDate;

  UserReport({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    required this.currentWeight,
    required this.goalWeight,
    required this.initialWeight,
    required this.weightHistory,
    required this.dailyCommitments,
    required this.isAchievedGoal,
    required this.subscriptionStatus,
    required this.subscriptionEndDate,
  });

  double get weightLost => initialWeight - currentWeight;
  double get progressPercentage =>
      (weightLost / (initialWeight - goalWeight)) * 100;

  int get commitmentYesCount {
    return dailyCommitments.where((c) => c == CommitmentStatus.yes).length;
  }

  double get commitmentPercentage {
    if (dailyCommitments.isEmpty) return 0;
    return (commitmentYesCount / dailyCommitments.length) * 100;
  }

  String get formattedEndDate {
    return '${subscriptionEndDate.day}/${subscriptionEndDate.month}/${subscriptionEndDate.year}';
  }
}
