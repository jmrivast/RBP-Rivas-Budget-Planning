import '../entities/user_entity.dart';

abstract class IUserRepository {
  Future<List<UserEntity>> getProfiles();
  Future<UserEntity?> getActiveProfile();
  Future<int> createProfile(String username, {String? pin, int pinLength});
  Future<void> switchProfile(int profileId, {String? pin});
  Future<void> setProfilePin(int profileId, {String? pin, int pinLength});
  Future<void> renameProfile(int profileId, String newName);
  Future<void> deleteProfile(int profileId, {String? pin});
  Future<bool> shouldPromptProfileAccess({int sessionHours});
  Future<void> markProfileSession({int sessionHours});
}
