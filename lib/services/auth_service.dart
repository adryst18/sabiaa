import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String?> login(String usuario, String password) async {
    try {
      final result = await _db
          .collection('usuarios')
          .where('usuario', isEqualTo: usuario)
          .where('password', isEqualTo: password)
          .get();

      if (result.docs.isNotEmpty) {
        return result.docs.first['rol']; // alumno o profesor
      } else {
        return null;
      }
    } catch (e) {
      print('Error login: $e');
      return null;
    }
  }
}