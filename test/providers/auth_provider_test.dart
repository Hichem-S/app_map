import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inventory/providers/auth_provider.dart';

void main() {
  late AuthProvider auth;

  setUp(() => auth = AuthProvider());

  Map<String, dynamic> userWith(String role) => {
        'id': 'u-001',
        'name': 'Test User',
        'email': 'test@iset.tn',
        'role': role,
      };

  group('Initial state', () {
    test('user is null before login', () => expect(auth.user, isNull));
    test('defaults role to technicien when no user loaded', () {
      expect(auth.role, 'technicien');
    });
  });

  group('Admin role', () {
    setUp(() => auth.setUser(userWith('admin')));

    test('isAdmin is true', () => expect(auth.isAdmin, isTrue));
    test('isMagazinier is false', () => expect(auth.isMagazinier, isFalse));
    test('isTechnicien is false', () => expect(auth.isTechnicien, isFalse));

    test('can edit and delete products', () {
      expect(auth.canEditProduct, isTrue);
      expect(auth.canDeleteProduct, isTrue);
    });
    test('can change status', () => expect(auth.canChangeStatus, isTrue));
    test('can view maps', () => expect(auth.canViewMaps, isTrue));
    test('can view reports', () => expect(auth.canViewReports, isTrue));
    test('can manage users', () => expect(auth.canManageUsers, isTrue));
    test('cannot add product (magazinier only)', () => expect(auth.canAddProduct, isFalse));

    test('displayRole returns Administrateur', () {
      expect(auth.displayRole, 'Administrateur');
    });
  });

  group('Magazinier role', () {
    setUp(() => auth.setUser(userWith('magazinier')));

    test('isAdmin is false', () => expect(auth.isAdmin, isFalse));
    test('isMagazinier is true', () => expect(auth.isMagazinier, isTrue));
    test('isTechnicien is false', () => expect(auth.isTechnicien, isFalse));

    test('can add, edit, delete products', () {
      expect(auth.canAddProduct, isTrue);
      expect(auth.canEditProduct, isTrue);
      expect(auth.canDeleteProduct, isTrue);
    });
    test('cannot change status (admin/tech only)', () => expect(auth.canChangeStatus, isFalse));
    test('cannot view maps', () => expect(auth.canViewMaps, isFalse));
    test('cannot view reports', () => expect(auth.canViewReports, isFalse));
    test('cannot manage users', () => expect(auth.canManageUsers, isFalse));

    test('displayRole returns Magazinier', () {
      expect(auth.displayRole, 'Magazinier');
    });
  });

  group('Technicien role', () {
    setUp(() => auth.setUser(userWith('technicien')));

    test('isAdmin is false', () => expect(auth.isAdmin, isFalse));
    test('isMagazinier is false', () => expect(auth.isMagazinier, isFalse));
    test('isTechnicien is true', () => expect(auth.isTechnicien, isTrue));

    test('cannot add, edit or delete products', () {
      expect(auth.canAddProduct, isFalse);
      expect(auth.canEditProduct, isFalse);
      expect(auth.canDeleteProduct, isFalse);
    });
    test('can change status', () => expect(auth.canChangeStatus, isTrue));
    test('can view maps', () => expect(auth.canViewMaps, isTrue));
    test('can view reports', () => expect(auth.canViewReports, isTrue));
    test('cannot manage users', () => expect(auth.canManageUsers, isFalse));

    test('displayRole returns Technicien', () {
      expect(auth.displayRole, 'Technicien');
    });
  });

  group('"user" legacy role treated as technicien', () {
    setUp(() => auth.setUser(userWith('user')));

    test('isTechnicien is true for role=user', () => expect(auth.isTechnicien, isTrue));
    test('can change status', () => expect(auth.canChangeStatus, isTrue));
    test('can view maps', () => expect(auth.canViewMaps, isTrue));
  });

  group('setUser / clear lifecycle', () {
    test('setUser populates user and role', () {
      auth.setUser(userWith('admin'));
      expect(auth.user, isNotNull);
      expect(auth.role, 'admin');
    });

    test('clear resets user to null', () {
      auth.setUser(userWith('admin'));
      auth.clear();
      expect(auth.user, isNull);
    });

    test('after clear, role defaults to technicien', () {
      auth.setUser(userWith('admin'));
      auth.clear();
      expect(auth.role, 'technicien');
    });

    test('setUser notifies listeners', () {
      int calls = 0;
      auth.addListener(() => calls++);
      auth.setUser(userWith('admin'));
      expect(calls, 1);
    });

    test('clear notifies listeners', () {
      int calls = 0;
      auth.setUser(userWith('admin'));
      auth.addListener(() => calls++);
      auth.clear();
      expect(calls, 1);
    });
  });

  group('Unknown role fallback', () {
    setUp(() => auth.setUser(userWith('guest')));

    test('isAdmin is false', () => expect(auth.isAdmin, isFalse));
    test('isMagazinier is false', () => expect(auth.isMagazinier, isFalse));
    test('displayRole returns raw role string', () => expect(auth.displayRole, 'guest'));
  });
}
