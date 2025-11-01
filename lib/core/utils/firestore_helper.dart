import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  // Safely extract data from DocumentSnapshot
  static Map<String, dynamic> safeExtractData(DocumentSnapshot doc) {
    final data = doc.data();
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data != null) {
      // If it's not a Map<String, dynamic>, try to convert it
      try {
        return Map<String, dynamic>.from(data as Map);
      } catch (e) {
        print('Error converting data to Map<String, dynamic>: $e');
      }
    }
    return {};
  }

  // Safely extract data from QueryDocumentSnapshot
  static Map<String, dynamic> safeExtractQueryData(QueryDocumentSnapshot doc) {
    final data = doc.data();
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data != null) {
      try {
        return Map<String, dynamic>.from(data as Map);
      } catch (e) {
        print('Error converting query data to Map<String, dynamic>: $e');
      }
    }
    return {};
  }

  // Convert a list of documents to models
  static List<T> convertDocsToModels<T>(
    List<QueryDocumentSnapshot> docs,
    T Function(Map<String, dynamic>) fromMap,
  ) {
    return docs.map((doc) {
      final data = safeExtractQueryData(doc);
      return fromMap(data);
    }).toList();
  }
}