import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkoutType {
  strength,
  cardio,
  flexibility,
  hiit,
  yoga,
  pilates,
  crossfit,
  bodyweight,
}

enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  quads,
  hamstrings,
  glutes,
  calves,
  fullBody,
}

enum EquipmentType {
  none,
  dumbbells,
  barbell,
  kettlebell,
  resistanceBands,
  pullupBar,
  bench,
  machine,
  cable,
  medicine_ball,
  foam_roller,
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

class Exercise {
  final String id;
  final String name;
  final String description;
  final List<String> instructions;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final List<EquipmentType> equipment;
  final DifficultyLevel difficulty;
  final String? videoUrl;
  final List<String> imageUrls;
  final String? category;
  final List<String> tags;
  final bool isCompound;
  final int? estimatedCaloriesPerMinute;
  final String? tips;
  final List<String> commonMistakes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.instructions,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    required this.equipment,
    required this.difficulty,
    this.videoUrl,
    this.imageUrls = const [],
    this.category,
    this.tags = const [],
    this.isCompound = false,
    this.estimatedCaloriesPerMinute,
    this.tips,
    this.commonMistakes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Exercise(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      instructions: List<String>.from(data['instructions'] ?? []),
      primaryMuscles: (data['primaryMuscles'] as List<dynamic>?)
          ?.map((muscle) => MuscleGroup.values.byName(muscle))
          .toList() ?? [],
      secondaryMuscles: (data['secondaryMuscles'] as List<dynamic>?)
          ?.map((muscle) => MuscleGroup.values.byName(muscle))
          .toList() ?? [],
      equipment: (data['equipment'] as List<dynamic>?)
          ?.map((eq) => EquipmentType.values.byName(eq))
          .toList() ?? [],
      difficulty: DifficultyLevel.values.byName(data['difficulty'] ?? 'beginner'),
      videoUrl: data['videoUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      category: data['category'],
      tags: List<String>.from(data['tags'] ?? []),
      isCompound: data['isCompound'] ?? false,
      estimatedCaloriesPerMinute: data['estimatedCaloriesPerMinute'],
      tips: data['tips'],
      commonMistakes: List<String>.from(data['commonMistakes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'instructions': instructions,
      'primaryMuscles': primaryMuscles.map((muscle) => muscle.name).toList(),
      'secondaryMuscles': secondaryMuscles.map((muscle) => muscle.name).toList(),
      'equipment': equipment.map((eq) => eq.name).toList(),
      'difficulty': difficulty.name,
      'videoUrl': videoUrl,
      'imageUrls': imageUrls,
      'category': category,
      'tags': tags,
      'isCompound': isCompound,
      'estimatedCaloriesPerMinute': estimatedCaloriesPerMinute,
      'tips': tips,
      'commonMistakes': commonMistakes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class WorkoutExercise {
  final String exerciseId;
  final Exercise? exercise; // Populated when needed
  final int? sets;
  final int? reps;
  final double? weight; // in kg
  final int? duration; // in seconds
  final int? distance; // in meters
  final double? restTime; // in seconds
  final String? notes;
  final int order;

  const WorkoutExercise({
    required this.exerciseId,
    this.exercise,
    this.sets,
    this.reps,
    this.weight,
    this.duration,
    this.distance,
    this.restTime,
    this.notes,
    required this.order,
  });

  factory WorkoutExercise.fromMap(Map<String, dynamic> data) {
    return WorkoutExercise(
      exerciseId: data['exerciseId'] ?? '',
      sets: data['sets'],
      reps: data['reps'],
      weight: data['weight']?.toDouble(),
      duration: data['duration'],
      distance: data['distance'],
      restTime: data['restTime']?.toDouble(),
      notes: data['notes'],
      order: data['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'duration': duration,
      'distance': distance,
      'restTime': restTime,
      'notes': notes,
      'order': order,
    };
  }

  WorkoutExercise copyWith({
    String? exerciseId,
    Exercise? exercise,
    int? sets,
    int? reps,
    double? weight,
    int? duration,
    int? distance,
    double? restTime,
    String? notes,
    int? order,
  }) {
    return WorkoutExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      exercise: exercise ?? this.exercise,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      restTime: restTime ?? this.restTime,
      notes: notes ?? this.notes,
      order: order ?? this.order,
    );
  }
}

class Workout {
  final String id;
  final String name;
  final String? description;
  final WorkoutType type;
  final List<MuscleGroup> targetMuscles;
  final DifficultyLevel difficulty;
  final int estimatedDuration; // in minutes
  final List<WorkoutExercise> exercises;
  final List<EquipmentType> requiredEquipment;
  final String? createdBy; // User ID
  final bool isTemplate;
  final bool isPublic;
  final int? estimatedCalories;
  final List<String> tags;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Workout({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.targetMuscles,
    required this.difficulty,
    required this.estimatedDuration,
    required this.exercises,
    required this.requiredEquipment,
    this.createdBy,
    this.isTemplate = false,
    this.isPublic = false,
    this.estimatedCalories,
    this.tags = const [],
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Workout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Workout(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      type: WorkoutType.values.byName(data['type'] ?? 'strength'),
      targetMuscles: (data['targetMuscles'] as List<dynamic>?)
          ?.map((muscle) => MuscleGroup.values.byName(muscle))
          .toList() ?? [],
      difficulty: DifficultyLevel.values.byName(data['difficulty'] ?? 'beginner'),
      estimatedDuration: data['estimatedDuration'] ?? 0,
      exercises: (data['exercises'] as List<dynamic>?)
          ?.map((exercise) => WorkoutExercise.fromMap(exercise))
          .toList() ?? [],
      requiredEquipment: (data['requiredEquipment'] as List<dynamic>?)
          ?.map((eq) => EquipmentType.values.byName(eq))
          .toList() ?? [],
      createdBy: data['createdBy'],
      isTemplate: data['isTemplate'] ?? false,
      isPublic: data['isPublic'] ?? false,
      estimatedCalories: data['estimatedCalories'],
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'targetMuscles': targetMuscles.map((muscle) => muscle.name).toList(),
      'difficulty': difficulty.name,
      'estimatedDuration': estimatedDuration,
      'exercises': exercises.map((exercise) => exercise.toMap()).toList(),
      'requiredEquipment': requiredEquipment.map((eq) => eq.name).toList(),
      'createdBy': createdBy,
      'isTemplate': isTemplate,
      'isPublic': isPublic,
      'estimatedCalories': estimatedCalories,
      'tags': tags,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Workout copyWith({
    String? name,
    String? description,
    WorkoutType? type,
    List<MuscleGroup>? targetMuscles,
    DifficultyLevel? difficulty,
    int? estimatedDuration,
    List<WorkoutExercise>? exercises,
    List<EquipmentType>? requiredEquipment,
    String? createdBy,
    bool? isTemplate,
    bool? isPublic,
    int? estimatedCalories,
    List<String>? tags,
    String? imageUrl,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      difficulty: difficulty ?? this.difficulty,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      exercises: exercises ?? this.exercises,
      requiredEquipment: requiredEquipment ?? this.requiredEquipment,
      createdBy: createdBy ?? this.createdBy,
      isTemplate: isTemplate ?? this.isTemplate,
      isPublic: isPublic ?? this.isPublic,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WorkoutSession {
  final String id;
  final String workoutId;
  final String userId;
  final Workout? workout; // Populated when needed
  final DateTime startTime;
  final DateTime? endTime;
  final List<CompletedExercise> completedExercises;
  final String? notes;
  final int? caloriesBurned;
  final double? avgHeartRate;
  final double? maxHeartRate;
  final bool isCompleted;
  final DateTime createdAt;

  const WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.userId,
    this.workout,
    required this.startTime,
    this.endTime,
    required this.completedExercises,
    this.notes,
    this.caloriesBurned,
    this.avgHeartRate,
    this.maxHeartRate,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory WorkoutSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return WorkoutSession(
      id: doc.id,
      workoutId: data['workoutId'] ?? '',
      userId: data['userId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null 
          ? (data['endTime'] as Timestamp).toDate() 
          : null,
      completedExercises: (data['completedExercises'] as List<dynamic>?)
          ?.map((exercise) => CompletedExercise.fromMap(exercise))
          .toList() ?? [],
      notes: data['notes'],
      caloriesBurned: data['caloriesBurned'],
      avgHeartRate: data['avgHeartRate']?.toDouble(),
      maxHeartRate: data['maxHeartRate']?.toDouble(),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'workoutId': workoutId,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'completedExercises': completedExercises.map((exercise) => exercise.toMap()).toList(),
      'notes': notes,
      'caloriesBurned': caloriesBurned,
      'avgHeartRate': avgHeartRate,
      'maxHeartRate': maxHeartRate,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }
}

class CompletedExercise {
  final String exerciseId;
  final List<CompletedSet> sets;
  final String? notes;
  final DateTime completedAt;

  const CompletedExercise({
    required this.exerciseId,
    required this.sets,
    this.notes,
    required this.completedAt,
  });

  factory CompletedExercise.fromMap(Map<String, dynamic> data) {
    return CompletedExercise(
      exerciseId: data['exerciseId'] ?? '',
      sets: (data['sets'] as List<dynamic>?)
          ?.map((set) => CompletedSet.fromMap(set))
          .toList() ?? [],
      notes: data['notes'],
      completedAt: (data['completedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sets': sets.map((set) => set.toMap()).toList(),
      'notes': notes,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}

class CompletedSet {
  final int? reps;
  final double? weight; // in kg
  final int? duration; // in seconds
  final int? distance; // in meters
  final bool isCompleted;
  final String? notes;

  const CompletedSet({
    this.reps,
    this.weight,
    this.duration,
    this.distance,
    this.isCompleted = true,
    this.notes,
  });

  factory CompletedSet.fromMap(Map<String, dynamic> data) {
    return CompletedSet(
      reps: data['reps'],
      weight: data['weight']?.toDouble(),
      duration: data['duration'],
      distance: data['distance'],
      isCompleted: data['isCompleted'] ?? true,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
      'duration': duration,
      'distance': distance,
      'isCompleted': isCompleted,
      'notes': notes,
    };
  }
}
