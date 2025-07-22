import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../models/workout.dart';
import '../models/nutrition.dart';
import '../models/weight_entry.dart';
import '../models/workout_stats.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _workouts => _firestore.collection('workouts');
  CollectionReference get _exercises => _firestore.collection('exercises');
  CollectionReference get _workoutSessions => _firestore.collection('workoutSessions');
  CollectionReference get _foods => _firestore.collection('foods');
  CollectionReference get _dailyNutrition => _firestore.collection('dailyNutrition');
  CollectionReference get _recipes => _firestore.collection('recipes');
  CollectionReference get _weightEntries => _firestore.collection('weightEntries');

  // Workout Stats Methods
  Stream<WorkoutStats> getWorkoutStats(String userId) {
    return _workoutSessions
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs;
      
      // Calculate stats
      final workoutsCompleted = docs.length;
      var totalCalories = 0;
      var totalDuration = Duration.zero;
      final activeDays = <DateTime>{};
      
      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalCalories += (data['caloriesBurned'] as num).toInt();
        totalDuration += Duration(minutes: (data['duration'] as num).toInt());
        activeDays.add((data['date'] as Timestamp).toDate());
      }
      
      // Calculate streak
      var currentStreak = 0;
      final today = DateTime.now();
      var checkDate = today;
      
      while (activeDays.contains(checkDate)) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      
      return WorkoutStats(
        workoutsCompleted: workoutsCompleted,
        currentStreak: currentStreak,
        caloriesBurned: totalCalories,
        totalWorkoutTime: totalDuration,
        weeklyActivedays: activeDays.where((date) =>
          date.isAfter(today.subtract(const Duration(days: 7)))).length,
        averageWorkoutDuration: totalDuration.inMinutes / workoutsCompleted,
      );
    });
  }

  // Weight Tracking Methods
  Stream<List<WeightEntry>> getWeightEntries(String userId) {
    return _weightEntries
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeightEntry.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addWeightEntry(String userId, WeightEntry entry) {
    return _weightEntries.add({
      'userId': userId,
      ...entry.toFirestore(),
    });
  }

  // Today's Workout Methods
  Future<Map<String, dynamic>?> getTodaysWorkout(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _workouts
        .where('userId', isEqualTo: userId)
        .where('scheduledDate', isGreaterThanOrEqualTo: startOfDay)
        .where('scheduledDate', isLessThan: endOfDay)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data() as Map<String, dynamic>;
  }

  // User Profile Operations
  Future<void> createUserProfile(UserProfile userProfile) async {
    await _users.doc(userProfile.id).set(userProfile.toFirestore());
  }

  Future<void> updateUserProfile(UserProfile userProfile) async {
    await _users.doc(userProfile.id).update(
      userProfile.copyWith(updatedAt: DateTime.now()).toFirestore(),
    );
  }

  Stream<UserProfile?> getUserProfile(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  Future<UserProfile?> getUserProfileOnce(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  // Workout Operations
  Future<String> createWorkout(Workout workout) async {
    final docRef = await _workouts.add(workout.toFirestore());
    return docRef.id;
  }

  Future<void> updateWorkout(Workout workout) async {
    await _workouts.doc(workout.id).update(
      workout.copyWith(updatedAt: DateTime.now()).toFirestore(),
    );
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _workouts.doc(workoutId).delete();
  }

  Stream<List<Workout>> getUserWorkouts(String userId) {
    return _workouts
        .where('createdBy', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Workout.fromFirestore(doc))
            .toList());
  }

  Stream<List<Workout>> getPublicWorkouts({
    WorkoutType? type,
    DifficultyLevel? difficulty,
    List<EquipmentType>? equipment,
    int limit = 20,
  }) {
    Query query = _workouts.where('isPublic', isEqualTo: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    if (equipment != null && equipment.isNotEmpty) {
      query = query.where('requiredEquipment', 
          arrayContainsAny: equipment.map((e) => e.name).toList());
    }

    return query
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Workout.fromFirestore(doc))
            .toList());
  }

  Future<Workout?> getWorkout(String workoutId) async {
    final doc = await _workouts.doc(workoutId).get();
    if (!doc.exists) return null;
    return Workout.fromFirestore(doc);
  }

  // Exercise Operations
  Future<String> createExercise(Exercise exercise) async {
    final docRef = await _exercises.add(exercise.toFirestore());
    return docRef.id;
  }

  Future<void> updateExercise(Exercise exercise) async {
    await _exercises.doc(exercise.id).update(
      exercise.copyWith(updatedAt: DateTime.now()).toFirestore(),
    );
  }

  Stream<List<Exercise>> getExercises({
    List<MuscleGroup>? muscleGroups,
    List<EquipmentType>? equipment,
    DifficultyLevel? difficulty,
    String? searchQuery,
    int limit = 50,
  }) {
    Query query = _exercises.orderBy('name');

    if (muscleGroups != null && muscleGroups.isNotEmpty) {
      query = query.where('primaryMuscles', 
          arrayContainsAny: muscleGroups.map((m) => m.name).toList());
    }

    if (equipment != null && equipment.isNotEmpty) {
      query = query.where('equipment', 
          arrayContainsAny: equipment.map((e) => e.name).toList());
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    return query
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          var exercises = snapshot.docs
              .map((doc) => Exercise.fromFirestore(doc))
              .toList();

          // Apply search filter if provided
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final lowercaseQuery = searchQuery.toLowerCase();
            exercises = exercises.where((exercise) =>
                exercise.name.toLowerCase().contains(lowercaseQuery) ||
                exercise.description.toLowerCase().contains(lowercaseQuery) ||
                exercise.tags.any((tag) => 
                    tag.toLowerCase().contains(lowercaseQuery))).toList();
          }

          return exercises;
        });
  }

  Future<Exercise?> getExercise(String exerciseId) async {
    final doc = await _exercises.doc(exerciseId).get();
    if (!doc.exists) return null;
    return Exercise.fromFirestore(doc);
  }

  // Workout Session Operations
  Future<String> createWorkoutSession(WorkoutSession session) async {
    final docRef = await _workoutSessions.add(session.toFirestore());
    return docRef.id;
  }

  Future<void> updateWorkoutSession(WorkoutSession session) async {
    await _workoutSessions.doc(session.id).update(session.toFirestore());
  }

  Stream<List<WorkoutSession>> getUserWorkoutSessions(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) {
    Query query = _workoutSessions
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true);

    if (startDate != null) {
      query = query.where('startTime', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('startTime', isLessThanOrEqualTo: endDate);
    }

    return query
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutSession.fromFirestore(doc))
            .toList());
  }

  // Food Operations
  Future<String> createFood(Food food) async {
    final docRef = await _foods.add(food.toFirestore());
    return docRef.id;
  }

  Stream<List<Food>> searchFoods(String query, {int limit = 20}) {
    return _foods
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Food.fromFirestore(doc))
            .toList());
  }

  Future<Food?> getFood(String foodId) async {
    final doc = await _foods.doc(foodId).get();
    if (!doc.exists) return null;
    return Food.fromFirestore(doc);
  }

  Future<Food?> getFoodByBarcode(String barcode) async {
    final query = await _foods.where('barcode', isEqualTo: barcode).get();
    if (query.docs.isEmpty) return null;
    return Food.fromFirestore(query.docs.first);
  }

  // Daily Nutrition Operations
  Future<void> saveDailyNutrition(DailyNutrition nutrition) async {
    final docId = '${nutrition.userId}_${_formatDate(nutrition.date)}';
    await _dailyNutrition.doc(docId).set(nutrition.toFirestore());
  }

  Stream<DailyNutrition?> getDailyNutrition(String userId, DateTime date) {
    final docId = '${userId}_${_formatDate(date)}';
    return _dailyNutrition.doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DailyNutrition.fromFirestore(doc);
    });
  }

  Stream<List<DailyNutrition>> getNutritionHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) {
    Query query = _dailyNutrition
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate);
    }

    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate);
    }

    return query
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DailyNutrition.fromFirestore(doc))
            .toList());
  }

  // Recipe Operations
  Future<String> createRecipe(Recipe recipe) async {
    final docRef = await _recipes.add(recipe.toFirestore());
    return docRef.id;
  }

  Future<void> updateRecipe(Recipe recipe) async {
    await _recipes.doc(recipe.id).update(
      recipe.copyWith(updatedAt: DateTime.now()).toFirestore(),
    );
  }

  Stream<List<Recipe>> getUserRecipes(String userId) {
    return _recipes
        .where('createdBy', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Recipe.fromFirestore(doc))
            .toList());
  }

  Stream<List<Recipe>> getPublicRecipes({
    List<String>? tags,
    DifficultyLevel? difficulty,
    int? maxPrepTime,
    String? searchQuery,
    int limit = 20,
  }) {
    Query query = _recipes.where('isPublic', isEqualTo: true);

    if (tags != null && tags.isNotEmpty) {
      query = query.where('tags', arrayContainsAny: tags);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    if (maxPrepTime != null) {
      query = query.where('prepTime', isLessThanOrEqualTo: maxPrepTime);
    }

    return query
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          var recipes = snapshot.docs
              .map((doc) => Recipe.fromFirestore(doc))
              .toList();

          // Apply search filter if provided
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final lowercaseQuery = searchQuery.toLowerCase();
            recipes = recipes.where((recipe) =>
                recipe.name.toLowerCase().contains(lowercaseQuery) ||
                recipe.description.toLowerCase().contains(lowercaseQuery) ||
                recipe.tags.any((tag) => 
                    tag.toLowerCase().contains(lowercaseQuery))).toList();
          }

          return recipes;
        });
  }

  // Utility Methods
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Batch Operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    final batch = _firestore.batch();
    
    for (final operation in operations) {
      final type = operation['type'] as String;
      final collection = operation['collection'] as String;
      final docId = operation['docId'] as String?;
      final data = operation['data'] as Map<String, dynamic>;

      final docRef = docId != null
          ? _firestore.collection(collection).doc(docId)
          : _firestore.collection(collection).doc();

      switch (type) {
        case 'set':
          batch.set(docRef, data);
          break;
        case 'update':
          batch.update(docRef, data);
          break;
        case 'delete':
          batch.delete(docRef);
          break;
      }
    }

    await batch.commit();
  }
}
