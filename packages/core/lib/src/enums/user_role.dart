enum UserRole {
  // TODO: permitir que o Admin defina staff/admin sem edição manual no Firestore.
  customer('customer'),
  staff('staff'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  bool get canAccessTableService {
    return this == UserRole.staff || this == UserRole.admin;
  }

  bool get canAccessDineIn => canAccessTableService;

  static UserRole fromString(String? value) {
    if (value == 'client') return UserRole.customer;

    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.customer,
    );
  }
}
