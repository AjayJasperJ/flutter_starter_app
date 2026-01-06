
class UserUpdatePasswordRequest {
  final String identifier;
  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;

  UserUpdatePasswordRequest({
    required this.identifier,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmNewPassword,
  });
}
