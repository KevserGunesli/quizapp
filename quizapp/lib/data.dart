import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> uploadQuestionsToFirebase() async {
  for (final sector in data.entries) {
    uloadQuestionsForAField(sector.key, sector.value);
  }
}

Future<void> uloadQuestionsForAField(String field, dynamic data) async {
  FirebaseFirestore.instance.collection('ListofQuestions').doc(field).set(data);
}

final data = {
  "Mathematics": {
    "questions": [
      {
        "question": "What is 2 + 2?",
        "options": ["3", "4", "5", "6"],
        "answer": "4",
      },
      {
        "question": "What is the square root of 16?",
        "options": ["2", "3", "4", "5"],
        "answer": "4",
      },
    ],
  },
  "Science": {
    "questions": [
      {
        "question": "What planet is known as the Red Planet?",
        "options": ["Earth", "Mars", "Jupiter", "Saturn"],
        "answer": "Mars",
      },
      {
        "question": "What is H2O commonly known as?",
        "options": ["Oxygen", "Hydrogen", "Water", "Carbon Dioxide"],
        "answer": "Water",
      },
    ],
  },
};
