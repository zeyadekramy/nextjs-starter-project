import 'package:flutter/material.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final String workoutId;
  
  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
      ),
      body: Center(
        child: Text('Workout Detail Screen: $workoutId'),
      ),
    );
  }
}
