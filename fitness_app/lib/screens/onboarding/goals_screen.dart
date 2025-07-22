import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Step 1: Basic Info
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  String? _selectedGender;

  // Step 2: Fitness Goals
  FitnessGoal? _primaryGoal;
  final Set<FitnessGoal> _secondaryGoals = {};

  // Step 3: Experience & Activity
  ExperienceLevel? _experienceLevel;
  ActivityLevel? _activityLevel;
  int? _workoutsPerWeek;
  int? _workoutDuration;

  // Step 4: Equipment
  final Set<String> _availableEquipment = {};

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final userProfile = UserProfile(
        id: user.uid,
        email: user.email!,
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        targetWeight: double.tryParse(_targetWeightController.text),
        primaryGoal: _primaryGoal,
        secondaryGoals: _secondaryGoals.toList(),
        experienceLevel: _experienceLevel,
        activityLevel: _activityLevel,
        workoutsPerWeek: _workoutsPerWeek,
        workoutDuration: _workoutDuration,
        availableEquipment: _availableEquipment.toList(),
      );

      await ref.read(firestoreServiceProvider).updateUserProfile(userProfile);
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _completeOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _ageController.text.isNotEmpty &&
               _heightController.text.isNotEmpty &&
               _weightController.text.isNotEmpty &&
               _selectedGender != null;
      case 1:
        return _primaryGoal != null;
      case 2:
        return _experienceLevel != null &&
               _activityLevel != null &&
               _workoutsPerWeek != null &&
               _workoutDuration != null;
      case 3:
        return true; // Equipment is optional
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildCurrentStep(),
            ),
          ),
          
          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Previous'),
                    ),
                  ),
                
                if (_currentStep > 0) const SizedBox(width: 16),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed() && !_isLoading ? _nextStep : null,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_currentStep == 3 ? 'Complete' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildGoalsStep();
      case 2:
        return _buildExperienceStep();
      case 3:
        return _buildEquipmentStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Help us personalize your experience',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        
        // Age
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            suffixText: 'years',
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Gender
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: const InputDecoration(
            labelText: 'Gender',
          ),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) {
            setState(() => _selectedGender = value);
          },
        ),
        
        const SizedBox(height: 16),
        
        // Height
        TextFormField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Height',
            suffixText: 'cm',
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Current Weight
        TextFormField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Current Weight',
            suffixText: 'kg',
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Target Weight
        TextFormField(
          controller: _targetWeightController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Weight (Optional)',
            suffixText: 'kg',
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fitness Goals',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'What do you want to achieve?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        
        Text(
          'Primary Goal',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        ...FitnessGoal.values.map((goal) => Card(
          child: RadioListTile<FitnessGoal>(
            title: Text(_getGoalTitle(goal)),
            subtitle: Text(_getGoalDescription(goal)),
            value: goal,
            groupValue: _primaryGoal,
            onChanged: (value) {
              setState(() => _primaryGoal = value);
            },
          ),
        )),
        
        const SizedBox(height: 24),
        
        Text(
          'Secondary Goals (Optional)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        ...FitnessGoal.values.where((goal) => goal != _primaryGoal).map((goal) => Card(
          child: CheckboxListTile(
            title: Text(_getGoalTitle(goal)),
            subtitle: Text(_getGoalDescription(goal)),
            value: _secondaryGoals.contains(goal),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _secondaryGoals.add(goal);
                } else {
                  _secondaryGoals.remove(goal);
                }
              });
            },
          ),
        )),
      ],
    );
  }

  Widget _buildExperienceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Experience & Activity',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your fitness background',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        
        // Experience Level
        Text(
          'Experience Level',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        ...ExperienceLevel.values.map((level) => Card(
          child: RadioListTile<ExperienceLevel>(
            title: Text(_getExperienceTitle(level)),
            subtitle: Text(_getExperienceDescription(level)),
            value: level,
            groupValue: _experienceLevel,
            onChanged: (value) {
              setState(() => _experienceLevel = value);
            },
          ),
        )),
        
        const SizedBox(height: 24),
        
        // Activity Level
        Text(
          'Activity Level',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        ...ActivityLevel.values.map((level) => Card(
          child: RadioListTile<ActivityLevel>(
            title: Text(_getActivityTitle(level)),
            subtitle: Text(_getActivityDescription(level)),
            value: level,
            groupValue: _activityLevel,
            onChanged: (value) {
              setState(() => _activityLevel = value);
            },
          ),
        )),
        
        const SizedBox(height: 24),
        
        // Workouts per week
        Text(
          'How many times per week do you want to work out?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final days = index + 1;
            return ChoiceChip(
              label: Text('$days ${days == 1 ? 'day' : 'days'}'),
              selected: _workoutsPerWeek == days,
              onSelected: (selected) {
                setState(() => _workoutsPerWeek = selected ? days : null);
              },
            );
          }),
        ),
        
        const SizedBox(height: 24),
        
        // Workout duration
        Text(
          'How long do you want each workout to be?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          children: [15, 30, 45, 60, 90].map((minutes) => ChoiceChip(
            label: Text('$minutes min'),
            selected: _workoutDuration == minutes,
            onSelected: (selected) {
              setState(() => _workoutDuration = selected ? minutes : null);
            },
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipmentStep() {
    final equipment = [
      'Dumbbells',
      'Barbell',
      'Kettlebell',
      'Resistance Bands',
      'Pull-up Bar',
      'Bench',
      'Gym Machine',
      'Cable Machine',
      'Medicine Ball',
      'Foam Roller',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Equipment',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Select the equipment you have access to',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        
        ...equipment.map((item) => Card(
          child: CheckboxListTile(
            title: Text(item),
            value: _availableEquipment.contains(item),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _availableEquipment.add(item);
                } else {
                  _availableEquipment.remove(item);
                }
              });
            },
          ),
        )),
        
        const SizedBox(height: 16),
        
        Card(
          child: CheckboxListTile(
            title: const Text('No Equipment (Bodyweight Only)'),
            value: _availableEquipment.contains('None'),
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _availableEquipment.clear();
                  _availableEquipment.add('None');
                } else {
                  _availableEquipment.remove('None');
                }
              });
            },
          ),
        ),
      ],
    );
  }

  String _getGoalTitle(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Weight Loss';
      case FitnessGoal.muscleGain:
        return 'Muscle Gain';
      case FitnessGoal.maintenance:
        return 'Maintenance';
      case FitnessGoal.endurance:
        return 'Endurance';
      case FitnessGoal.strength:
        return 'Strength';
    }
  }

  String _getGoalDescription(FitnessGoal goal) {
    switch (goal) {
      case FitnessGoal.weightLoss:
        return 'Burn fat and lose weight';
      case FitnessGoal.muscleGain:
        return 'Build muscle mass and size';
      case FitnessGoal.maintenance:
        return 'Maintain current fitness level';
      case FitnessGoal.endurance:
        return 'Improve cardiovascular fitness';
      case FitnessGoal.strength:
        return 'Increase overall strength';
    }
  }

  String _getExperienceTitle(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }

  String _getExperienceDescription(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.beginner:
        return 'New to fitness or returning after a break';
      case ExperienceLevel.intermediate:
        return '6+ months of consistent training';
      case ExperienceLevel.advanced:
        return '2+ years of consistent training';
    }
  }

  String _getActivityTitle(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  String _getActivityDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise';
      case ActivityLevel.lightlyActive:
        return 'Light exercise 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise, physical job';
    }
  }
}
