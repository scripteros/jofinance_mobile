class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final bool onboardingDone;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.onboardingDone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      onboardingDone: json['onboarding_done'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'onboarding_done': onboardingDone,
    };
  }
}

class Transaction {
  final int id;
  final String description;
  final double amount;
  final String category;
  final String date;
  final String? type;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }
    return Transaction(
      id: parseInt(json['id']),
      description: json['description']?.toString() ?? '',
      amount: parseDouble(json['amount']),
      category: json['category']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      type: json['type']?.toString(),
    );
  }
}

class Goal {
  final int id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double percentage;
  final String category;
  final String status;
  final double monthlyContribution;
  final String? dueDate;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.percentage,
    required this.category,
    required this.status,
    this.monthlyContribution = 0,
    this.dueDate,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }
    return Goal(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      targetAmount: parseDouble(json['target_amount']),
      currentAmount: parseDouble(json['current_amount']),
      percentage: parseDouble(json['percentage']),
      category: json['category']?.toString() ?? 'saving',
      status: json['status']?.toString() ?? 'ativo',
      monthlyContribution: parseDouble(json['monthly_contribution']),
      dueDate: json['target_date']?.toString() ?? json['due_date']?.toString(),
    );
  }
}
