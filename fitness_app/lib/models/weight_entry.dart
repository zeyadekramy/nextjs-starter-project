import 'package:cloud_firestore/cloud_firestore.dart';

class WeightEntry {
  final DateTime date;
  final double weight;
  final String? note;

  const WeightEntry({
    required this.date,
    required this.weight,
    this.note,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'weight': weight,
      'note': note,
    };
  }

  static WeightEntry fromFirestore(Map<String, dynamic> data) {
    return WeightEntry(
      date: (data['date'] as Timestamp).toDate(),
      weight: data['weight'] as double,
      note: data['note'] as String?,
    );
  }
}
