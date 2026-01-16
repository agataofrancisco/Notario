import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/domain/entities/user.dart';

/// Repositório de utilizadores usando Firestore
class UserFirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referência à coleção de utilizadores
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Criar ou atualizar utilizador
  Future<void> createOrUpdate(User user) async {
    await _usersCollection
        .doc(user.id)
        .set(user.toJson(), SetOptions(merge: true));
  }

  /// Obter utilizador por ID
  Future<User?> getById(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return User.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Obter utilizador por Google ID
  Future<User?> getByGoogleId(String googleId) async {
    final snapshot = await _usersCollection
        .where('googleId', isEqualTo: googleId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return User.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
  }

  /// Obter utilizador por email
  Future<User?> getByEmail(String email) async {
    final snapshot =
        await _usersCollection.where('email', isEqualTo: email).limit(1).get();

    if (snapshot.docs.isEmpty) return null;
    return User.fromJson(snapshot.docs.first.data() as Map<String, dynamic>);
  }

  /// Observar utilizador (Stream)
  Stream<User?> watchUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return User.fromJson(doc.data() as Map<String, dynamic>);
    });
  }

  /// Atualizar timezone do utilizador
  Future<void> updateTimezone(String userId, String timezone) async {
    await _usersCollection.doc(userId).update({
      'timezone': timezone,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Atualizar Google Calendar ID
  Future<void> updateGoogleCalendarId(String userId, String calendarId) async {
    await _usersCollection.doc(userId).update({
      'googleCalendarId': calendarId,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Atualizar Google Refresh Token (encriptado)
  Future<void> updateGoogleRefreshToken(
      String userId, String refreshToken) async {
    await _usersCollection.doc(userId).update({
      'googleRefreshToken': refreshToken,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Deletar utilizador
  Future<void> delete(String userId) async {
    await _usersCollection.doc(userId).delete();
  }
}
