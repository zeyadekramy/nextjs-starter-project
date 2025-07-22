import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/workout_stats.dart';
import '../models/weight_entry.dart';
import '../models/workout.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

// Workout Stats Provider
final workoutStatsProvider = StreamProvider<WorkoutStats>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = ref.watch(authStateProvider).value?.uid;
  
  if (userId == null) return Stream.value(
    const WorkoutStats(
      workoutsCompleted: 0,
      currentStreak: 0,
      caloriesBurned: 0,
      totalWorkoutTime: Duration.zero,
      weeklyActivedays: 0,
      averageWorkoutDuration: 0,
    ),
  );

  return firestoreService.getWorkoutStats(userId);
});

// Weight Entries Provider
final weightEntriesProvider = StreamProvider<List<WeightEntry>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = ref.watch(authStateProvider).value?.uid;
  
  if (userId == null) return Stream.value([]);

  return firestoreService.getWeightEntries(userId);
});

// Today's Workout Provider
final todaysWorkoutProvider = FutureProvider((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final userId = ref.watch(authStateProvider).value?.uid;
  
  if (userId == null) return null;

  final workoutData = await firestoreService.getTodaysWorkout(userId);
  if (workoutData == null) return null;
  
  return Workout.fromFirestore(workoutData as DocumentSnapshot<Map<String, dynamic>>);
});

// Date Formatters
// Active Workout Provider
final activeWorkoutProvider = StateProvider<Workout?>((ref) => null);

// Workout Progress Provider
final workoutProgressProvider = StateProvider<double>((ref) => 0.0);

final dateFormatters = {
  'short': DateFormat('MMM d'),
  'medium': DateFormat('MMM d, yyyy'),
  'time': DateFormat('HH:mm'),
  'weekday': DateFormat('EEEE'),
};

// Animation Durations
class AnimationDurations {
  static const card = Duration(milliseconds: 300);
  static const chart = Duration(milliseconds: 800);
  static const stats = Duration(milliseconds: 500);
}
