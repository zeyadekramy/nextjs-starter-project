import 'package:cloud_firestore/cloud_firestore.dart';

enum FitnessGoal {
  weightLoss,
  muscleGain,
  maintenance,
  endurance,
  strength,
}

enum ExperienceLevel {
  beginner,
  intermediate,
  advanced,
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive,
}

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Personal Info
  final int? age;
  final String? gender;
  final double? height; // in cm
  final double? weight; // in kg
  final double? targetWeight; // in kg
  
  // Fitness Info
  final FitnessGoal? primaryGoal;
  final List<FitnessGoal> secondaryGoals;
  final ExperienceLevel? experienceLevel;
  final ActivityLevel? activityLevel;
  final List<String> availableEquipment;
  final int? workoutsPerWeek;
  final int? workoutDuration; // in minutes
  
  // Preferences
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String? preferredLanguage;
  final String? timezone;
  
  // Gamification
  final int totalPoints;
  final int currentLevel;
  final int currentStreak;
  final int longestStreak;
  final List<String> achievements;
  
  // Nutrition
  final double? dailyCalorieGoal;
  final double? proteinGoal; // in grams
  final double? carbGoal; // in grams
  final double? fatGoal; // in grams
  final double? waterGoal; // in ml

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.targetWeight,
    this.primaryGoal,
    this.secondaryGoals = const [],
    this.experienceLevel,
    this.activityLevel,
    this.availableEquipment = const [],
    this.workoutsPerWeek,
    this.workoutDuration,
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.preferredLanguage,
    this.timezone,
    this.totalPoints = 0,
    this.currentLevel = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.achievements = const [],
    this.dailyCalorieGoal,
    this.proteinGoal,
    this.carbGoal,
    this.fatGoal,
    this.waterGoal,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      age: data['age'],
      gender: data['gender'],
      height: data['height']?.toDouble(),
      weight: data['weight']?.toDouble(),
      targetWeight: data['targetWeight']?.toDouble(),
      primaryGoal: data['primaryGoal'] != null 
          ? FitnessGoal.values.byName(data['primaryGoal'])
          : null,
      secondaryGoals: (data['secondaryGoals'] as List<dynamic>?)
          ?.map((goal) => FitnessGoal.values.byName(goal))
          .toList() ?? [],
      experienceLevel: data['experienceLevel'] != null
          ? ExperienceLevel.values.byName(data['experienceLevel'])
          : null,
      activityLevel: data['activityLevel'] != null
          ? ActivityLevel.values.byName(data['activityLevel'])
          : null,
      availableEquipment: List<String>.from(data['availableEquipment'] ?? []),
      workoutsPerWeek: data['workoutsPerWeek'],
      workoutDuration: data['workoutDuration'],
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      darkModeEnabled: data['darkModeEnabled'] ?? false,
      preferredLanguage: data['preferredLanguage'],
      timezone: data['timezone'],
      totalPoints: data['totalPoints'] ?? 0,
      currentLevel: data['currentLevel'] ?? 1,
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      achievements: List<String>.from(data['achievements'] ?? []),
      dailyCalorieGoal: data['dailyCalorieGoal']?.toDouble(),
      proteinGoal: data['proteinGoal']?.toDouble(),
      carbGoal: data['carbGoal']?.toDouble(),
      fatGoal: data['fatGoal']?.toDouble(),
      waterGoal: data['waterGoal']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'targetWeight': targetWeight,
      'primaryGoal': primaryGoal?.name,
      'secondaryGoals': secondaryGoals.map((goal) => goal.name).toList(),
      'experienceLevel': experienceLevel?.name,
      'activityLevel': activityLevel?.name,
      'availableEquipment': availableEquipment,
      'workoutsPerWeek': workoutsPerWeek,
      'workoutDuration': workoutDuration,
      'notificationsEnabled': notificationsEnabled,
      'darkModeEnabled': darkModeEnabled,
      'preferredLanguage': preferredLanguage,
      'timezone': timezone,
      'totalPoints': totalPoints,
      'currentLevel': currentLevel,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'achievements': achievements,
      'dailyCalorieGoal': dailyCalorieGoal,
      'proteinGoal': proteinGoal,
      'carbGoal': carbGoal,
      'fatGoal': fatGoal,
      'waterGoal': waterGoal,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? photoURL,
    DateTime? updatedAt,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? targetWeight,
    FitnessGoal? primaryGoal,
    List<FitnessGoal>? secondaryGoals,
    ExperienceLevel? experienceLevel,
    ActivityLevel? activityLevel,
    List<String>? availableEquipment,
    int? workoutsPerWeek,
    int? workoutDuration,
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? preferredLanguage,
    String? timezone,
    int? totalPoints,
    int? currentLevel,
    int? currentStreak,
    int? longestStreak,
    List<String>? achievements,
    double? dailyCalorieGoal,
    double? proteinGoal,
    double? carbGoal,
    double? fatGoal,
    double? waterGoal,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      targetWeight: targetWeight ?? this.targetWeight,
      primaryGoal: primaryGoal ?? this.primaryGoal,
      secondaryGoals: secondaryGoals ?? this.secondaryGoals,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      activityLevel: activityLevel ?? this.activityLevel,
      availableEquipment: availableEquipment ?? this.availableEquipment,
      workoutsPerWeek: workoutsPerWeek ?? this.workoutsPerWeek,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timezone: timezone ?? this.timezone,
      totalPoints: totalPoints ?? this.totalPoints,
      currentLevel: currentLevel ?? this.currentLevel,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      achievements: achievements ?? this.achievements,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbGoal: carbGoal ?? this.carbGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      waterGoal: waterGoal ?? this.waterGoal,
    );
  }

  // Calculate BMI
  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  // Calculate BMR (Basal Metabolic Rate)
  double? get bmr {
    if (age == null || height == null || weight == null || gender == null) {
      return null;
    }
    
    // Mifflin-St Jeor Equation
    if (gender!.toLowerCase() == 'male') {
      return 10 * weight! + 6.25 * height! - 5 * age! + 5;
    } else {
      return 10 * weight! + 6.25 * height! - 5 * age! - 161;
    }
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  double? get tdee {
    if (bmr == null || activityLevel == null) return null;
    
    final multiplier = switch (activityLevel!) {
      ActivityLevel.sedentary => 1.2,
      ActivityLevel.lightlyActive => 1.375,
      ActivityLevel.moderatelyActive => 1.55,
      ActivityLevel.veryActive => 1.725,
      ActivityLevel.extremelyActive => 1.9,
    };
    
    return bmr! * multiplier;
  }
}
