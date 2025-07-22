class WorkoutStats {
  final int workoutsCompleted;
  final int currentStreak;
  final int caloriesBurned;
  final Duration totalWorkoutTime;
  final int weeklyActivedays;
  final double averageWorkoutDuration;

  const WorkoutStats({
    required this.workoutsCompleted,
    required this.currentStreak,
    required this.caloriesBurned,
    required this.totalWorkoutTime,
    required this.weeklyActivedays,
    required this.averageWorkoutDuration,
  });
}
