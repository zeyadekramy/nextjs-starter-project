import 'package:cloud_firestore/cloud_firestore.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack,
}

enum NutrientType {
  calories,
  protein,
  carbs,
  fat,
  fiber,
  sugar,
  sodium,
  cholesterol,
  vitaminA,
  vitaminC,
  calcium,
  iron,
}

class Food {
  final String id;
  final String name;
  final String? brand;
  final String? barcode;
  final double servingSize; // in grams
  final String servingUnit;
  final Map<NutrientType, double> nutrients; // per serving
  final List<String> categories;
  final String? imageUrl;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Food({
    required this.id,
    required this.name,
    this.brand,
    this.barcode,
    required this.servingSize,
    required this.servingUnit,
    required this.nutrients,
    this.categories = const [],
    this.imageUrl,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Food.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final nutrientsMap = <NutrientType, double>{};
    if (data['nutrients'] != null) {
      (data['nutrients'] as Map<String, dynamic>).forEach((key, value) {
        try {
          final nutrientType = NutrientType.values.byName(key);
          nutrientsMap[nutrientType] = (value as num).toDouble();
        } catch (e) {
          // Skip unknown nutrient types
        }
      });
    }
    
    return Food(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'],
      barcode: data['barcode'],
      servingSize: (data['servingSize'] as num?)?.toDouble() ?? 100.0,
      servingUnit: data['servingUnit'] ?? 'g',
      nutrients: nutrientsMap,
      categories: List<String>.from(data['categories'] ?? []),
      imageUrl: data['imageUrl'],
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final nutrientsMap = <String, double>{};
    nutrients.forEach((key, value) {
      nutrientsMap[key.name] = value;
    });
    
    return {
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'nutrients': nutrientsMap,
      'categories': categories,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  double getCaloriesPer100g() {
    final calories = nutrients[NutrientType.calories] ?? 0;
    return (calories / servingSize) * 100;
  }

  double getProteinPer100g() {
    final protein = nutrients[NutrientType.protein] ?? 0;
    return (protein / servingSize) * 100;
  }

  double getCarbsPer100g() {
    final carbs = nutrients[NutrientType.carbs] ?? 0;
    return (carbs / servingSize) * 100;
  }

  double getFatPer100g() {
    final fat = nutrients[NutrientType.fat] ?? 0;
    return (fat / servingSize) * 100;
  }
}

class FoodEntry {
  final String foodId;
  final Food? food; // Populated when needed
  final double quantity; // in grams or serving units
  final String unit;
  final MealType mealType;
  final DateTime consumedAt;
  final String? notes;

  const FoodEntry({
    required this.foodId,
    this.food,
    required this.quantity,
    required this.unit,
    required this.mealType,
    required this.consumedAt,
    this.notes,
  });

  factory FoodEntry.fromMap(Map<String, dynamic> data) {
    return FoodEntry(
      foodId: data['foodId'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? 'g',
      mealType: MealType.values.byName(data['mealType'] ?? 'snack'),
      consumedAt: (data['consumedAt'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'quantity': quantity,
      'unit': unit,
      'mealType': mealType.name,
      'consumedAt': Timestamp.fromDate(consumedAt),
      'notes': notes,
    };
  }

  // Calculate nutrients for this entry
  Map<NutrientType, double> calculateNutrients() {
    if (food == null) return {};
    
    final multiplier = unit == 'serving' 
        ? quantity 
        : quantity / food!.servingSize;
    
    final result = <NutrientType, double>{};
    food!.nutrients.forEach((nutrient, value) {
      result[nutrient] = value * multiplier;
    });
    
    return result;
  }
}

class DailyNutrition {
  final String id;
  final String userId;
  final DateTime date;
  final List<FoodEntry> foodEntries;
  final double waterIntake; // in ml
  final Map<NutrientType, double> goals;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyNutrition({
    required this.id,
    required this.userId,
    required this.date,
    required this.foodEntries,
    this.waterIntake = 0.0,
    this.goals = const {},
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyNutrition.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final goalsMap = <NutrientType, double>{};
    if (data['goals'] != null) {
      (data['goals'] as Map<String, dynamic>).forEach((key, value) {
        try {
          final nutrientType = NutrientType.values.byName(key);
          goalsMap[nutrientType] = (value as num).toDouble();
        } catch (e) {
          // Skip unknown nutrient types
        }
      });
    }
    
    return DailyNutrition(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      foodEntries: (data['foodEntries'] as List<dynamic>?)
          ?.map((entry) => FoodEntry.fromMap(entry))
          .toList() ?? [],
      waterIntake: (data['waterIntake'] as num?)?.toDouble() ?? 0.0,
      goals: goalsMap,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final goalsMap = <String, double>{};
    goals.forEach((key, value) {
      goalsMap[key.name] = value;
    });
    
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'foodEntries': foodEntries.map((entry) => entry.toMap()).toList(),
      'waterIntake': waterIntake,
      'goals': goalsMap,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Calculate total nutrients consumed
  Map<NutrientType, double> getTotalNutrients() {
    final totals = <NutrientType, double>{};
    
    for (final entry in foodEntries) {
      final entryNutrients = entry.calculateNutrients();
      entryNutrients.forEach((nutrient, value) {
        totals[nutrient] = (totals[nutrient] ?? 0) + value;
      });
    }
    
    return totals;
  }

  // Get nutrients by meal type
  Map<MealType, Map<NutrientType, double>> getNutrientsByMeal() {
    final result = <MealType, Map<NutrientType, double>>{};
    
    for (final mealType in MealType.values) {
      result[mealType] = <NutrientType, double>{};
    }
    
    for (final entry in foodEntries) {
      final entryNutrients = entry.calculateNutrients();
      entryNutrients.forEach((nutrient, value) {
        result[entry.mealType]![nutrient] = 
            (result[entry.mealType]![nutrient] ?? 0) + value;
      });
    }
    
    return result;
  }

  // Calculate progress towards goals
  Map<NutrientType, double> getGoalProgress() {
    final totals = getTotalNutrients();
    final progress = <NutrientType, double>{};
    
    goals.forEach((nutrient, goal) {
      final consumed = totals[nutrient] ?? 0;
      progress[nutrient] = goal > 0 ? (consumed / goal) : 0;
    });
    
    return progress;
  }

  double get totalCalories => getTotalNutrients()[NutrientType.calories] ?? 0;
  double get totalProtein => getTotalNutrients()[NutrientType.protein] ?? 0;
  double get totalCarbs => getTotalNutrients()[NutrientType.carbs] ?? 0;
  double get totalFat => getTotalNutrients()[NutrientType.fat] ?? 0;
}

class Recipe {
  final String id;
  final String name;
  final String description;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final int servings;
  final int prepTime; // in minutes
  final int cookTime; // in minutes
  final DifficultyLevel difficulty;
  final List<String> tags;
  final String? imageUrl;
  final String? createdBy;
  final bool isPublic;
  final Map<NutrientType, double> nutritionPerServing;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.servings,
    required this.prepTime,
    required this.cookTime,
    required this.difficulty,
    this.tags = const [],
    this.imageUrl,
    this.createdBy,
    this.isPublic = false,
    this.nutritionPerServing = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    final nutritionMap = <NutrientType, double>{};
    if (data['nutritionPerServing'] != null) {
      (data['nutritionPerServing'] as Map<String, dynamic>).forEach((key, value) {
        try {
          final nutrientType = NutrientType.values.byName(key);
          nutritionMap[nutrientType] = (value as num).toDouble();
        } catch (e) {
          // Skip unknown nutrient types
        }
      });
    }
    
    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ingredients: (data['ingredients'] as List<dynamic>?)
          ?.map((ingredient) => RecipeIngredient.fromMap(ingredient))
          .toList() ?? [],
      instructions: List<String>.from(data['instructions'] ?? []),
      servings: data['servings'] ?? 1,
      prepTime: data['prepTime'] ?? 0,
      cookTime: data['cookTime'] ?? 0,
      difficulty: DifficultyLevel.values.byName(data['difficulty'] ?? 'beginner'),
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'],
      isPublic: data['isPublic'] ?? false,
      nutritionPerServing: nutritionMap,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final nutritionMap = <String, double>{};
    nutritionPerServing.forEach((key, value) {
      nutritionMap[key.name] = value;
    });
    
    return {
      'name': name,
      'description': description,
      'ingredients': ingredients.map((ingredient) => ingredient.toMap()).toList(),
      'instructions': instructions,
      'servings': servings,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'difficulty': difficulty.name,
      'tags': tags,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'isPublic': isPublic,
      'nutritionPerServing': nutritionMap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  int get totalTime => prepTime + cookTime;
}

class RecipeIngredient {
  final String foodId;
  final Food? food; // Populated when needed
  final double quantity;
  final String unit;
  final String? notes;

  const RecipeIngredient({
    required this.foodId,
    this.food,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> data) {
    return RecipeIngredient(
      foodId: data['foodId'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? 'g',
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'foodId': foodId,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
    };
  }
}

enum DifficultyLevel {
  beginner,
  intermediate,
  advanced,
}
