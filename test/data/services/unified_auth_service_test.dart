import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:louvorja_piano_mobile/data/services/unified_auth_service.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}
class _MockUserCredential extends Mock implements UserCredential {}
class _MockUser extends Mock implements User {}

void main() {
  late _MockFirebaseAuth auth;
  late UnifiedAuthService service;

  setUp(() {
    auth = _MockFirebaseAuth();
    service = UnifiedAuthService(auth);
  });

  group('UnifiedAuthService (RF-003)', () {
    test('loginWithEmail retorna id token em sucesso', () async {
      final user = _MockUser();
      final credential = _MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'token-123');
      when(() => auth.signInWithEmailAndPassword(
            email: 'a@b.com', password: 'senha1'))
          .thenAnswer((_) async => credential);

      final token = await service.loginWithEmail('a@b.com', 'senha1');

      expect(token, 'token-123');
    });

    test('loginWithEmail retorna null em FirebaseAuthException', () async {
      when(() => auth.signInWithEmailAndPassword(
            email: 'a@b.com', password: 'errada'))
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final token = await service.loginWithEmail('a@b.com', 'errada');

      expect(token, isNull);
    });

    test('registerWithEmail retorna token e seta displayName', () async {
      final user = _MockUser();
      final credential = _MockUserCredential();
      when(() => credential.user).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'token-reg');
      when(() => user.updateDisplayName('Rafael')).thenAnswer((_) async => {});
      when(() => auth.createUserWithEmailAndPassword(
            email: 'novo@b.com', password: 'senha1'))
          .thenAnswer((_) async => credential);

      final token = await service.registerWithEmail(
          'novo@b.com', 'senha1', 'Rafael');

      expect(token, 'token-reg');
      verify(() => user.updateDisplayName('Rafael')).called(1);
    });

    test('currentIdToken retorna null sem usuário logado', () async {
      when(() => auth.currentUser).thenReturn(null);

      expect(await service.currentIdToken(), isNull);
    });

    test('currentIdToken retorna token do usuário logado', () async {
      final user = _MockUser();
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.getIdToken()).thenAnswer((_) async => 'tok');

      expect(await service.currentIdToken(), 'tok');
    });

    test('signOut delega para FirebaseAuth', () async {
      when(() => auth.signOut()).thenAnswer((_) async => {});

      await service.signOut();

      verify(() => auth.signOut()).called(1);
    });
  });
}
