import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared_preferences_provider.dart';
import '../services/grit_api_service.dart';
import '../data/models/social_models.dart';
import '../data/models/challenge.dart';
import 'gamification_provider.dart';
import 'dao_providers.dart';

const _tokenPrefKey = 'grit_social_token';
const _userIdPrefKey = 'grit_social_user_id';
const _firstNamePrefKey = 'grit_social_first_name';
const _lastNamePrefKey = 'grit_social_last_name';
const _emailPrefKey = 'grit_social_email';

class SocialAuthState {
  final String? token;
  final SocialUser? user;

  const SocialAuthState({this.token, this.user});

  bool get isLoggedIn => token != null && user != null;
}

class SocialAuthNotifier extends Notifier<SocialAuthState> {
  @override
  SocialAuthState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final token = prefs.getString(_tokenPrefKey);
    final userId = prefs.getInt(_userIdPrefKey);
    final firstName = prefs.getString(_firstNamePrefKey);
    final lastName = prefs.getString(_lastNamePrefKey);
    final email = prefs.getString(_emailPrefKey);

    if (token == null || userId == null || firstName == null || lastName == null || email == null) {
      return const SocialAuthState();
    }
    return SocialAuthState(
      token: token,
      user: SocialUser(id: userId, firstName: firstName, lastName: lastName, email: email),
    );
  }

  Future<void> _persist(String token, SocialUser user) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_tokenPrefKey, token);
    await prefs.setInt(_userIdPrefKey, user.id);
    await prefs.setString(_firstNamePrefKey, user.firstName);
    await prefs.setString(_lastNamePrefKey, user.lastName);
    await prefs.setString(_emailPrefKey, user.email);
    state = SocialAuthState(token: token, user: user);
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    final result = await const GritApiService().register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobileNumber: mobileNumber,
      password: password,
    );
    await _persist(result.token, result.user);
  }

  Future<void> login({required String identifier, required String password}) async {
    final result = await const GritApiService().login(identifier: identifier, password: password);
    await _persist(result.token, result.user);
  }

  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_tokenPrefKey);
    await prefs.remove(_userIdPrefKey);
    await prefs.remove(_firstNamePrefKey);
    await prefs.remove(_lastNamePrefKey);
    await prefs.remove(_emailPrefKey);
    state = const SocialAuthState();
  }
}

final socialAuthProvider = NotifierProvider<SocialAuthNotifier, SocialAuthState>(SocialAuthNotifier.new);

final _apiProvider = Provider<GritApiService>((ref) {
  final auth = ref.watch(socialAuthProvider);
  return GritApiService(token: auth.token);
});

final feedProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) async {
  final api = ref.watch(_apiProvider);
  return api.getFeed();
});

final friendsProvider = FutureProvider.autoDispose<List<SocialUser>>((ref) async {
  final api = ref.watch(_apiProvider);
  return api.getFriends();
});

/// Pushes this device's real local gamification stats to the backend, then
/// fetches the ranked leaderboard of self + accepted friends.
final leaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final api = ref.watch(_apiProvider);
  final summary = await ref.watch(gamificationProvider.future);

  await api.syncStats(
    gritScore: summary.gritScore,
    streak: summary.stats.currentStreak,
    totalVolumeKg: summary.stats.totalVolumeKg,
    totalWorkouts: summary.stats.totalWorkouts,
  );

  return api.getLeaderboard();
});

final friendRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>((ref) async {
  final api = ref.watch(_apiProvider);
  return api.getFriendRequests();
});

/// Computes this device's real progress for a single active challenge from
/// local workout data, pushes it to the backend, and returns the updated
/// challenge (with everyone's progress).
Future<Challenge> _syncOneChallengeProgress(Ref ref, Challenge challenge) async {
  final api = ref.read(_apiProvider);
  final sessionsDao = ref.read(sessionsDaoProvider);
  final stats = await sessionsDao.getStatsForPeriod(
    challenge.startDate.toIso8601String(),
    challenge.endDate.toIso8601String(),
  );

  final progress = switch (challenge.goalType) {
    ChallengeGoalType.workoutCount => (stats['count'] as int).toDouble(),
    ChallengeGoalType.volumeKg => stats['volume'] as double,
  };

  return api.syncChallengeProgress(challenge.id, progress);
}

/// My joined challenges, with progress freshly synced from local data.
final myChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final api = ref.watch(_apiProvider);
  final challenges = await api.getMyChallenges();

  final synced = <Challenge>[];
  for (final challenge in challenges) {
    if (challenge.isActive) {
      synced.add(await _syncOneChallengeProgress(ref, challenge));
    } else {
      synced.add(challenge);
    }
  }
  return synced;
});

final availableChallengesProvider = FutureProvider.autoDispose<List<Challenge>>((ref) async {
  final api = ref.watch(_apiProvider);
  return api.getAvailableChallenges();
});

class SocialActions {
  final Ref ref;
  SocialActions(this.ref);

  GritApiService get _api => ref.read(_apiProvider);

  Future<void> createPost(String content) async {
    await _api.createPost(content);
    ref.invalidate(feedProvider);
  }

  Future<void> deletePost(int postId) async {
    await _api.deletePost(postId);
    ref.invalidate(feedProvider);
  }

  Future<void> toggleLike(int postId) async {
    await _api.toggleLike(postId);
    ref.invalidate(feedProvider);
  }

  Future<List<PostComment>> getComments(int postId) => _api.getComments(postId);

  Future<void> addComment(int postId, String content) async {
    await _api.addComment(postId, content);
    ref.invalidate(feedProvider);
  }

  Future<void> sendFriendRequest(String email) async {
    await _api.sendFriendRequest(email);
  }

  Future<void> acceptFriendRequest(int requestId) async {
    await _api.acceptFriendRequest(requestId);
    ref.invalidate(friendsProvider);
    ref.invalidate(friendRequestsProvider);
  }

  Future<void> declineFriendRequest(int requestId) async {
    await _api.declineFriendRequest(requestId);
    ref.invalidate(friendRequestsProvider);
  }

  Future<void> createChallenge({
    required String title,
    required ChallengeGoalType goalType,
    required double goalTarget,
    required int durationDays,
  }) async {
    await _api.createChallenge(title: title, goalType: goalType, goalTarget: goalTarget, durationDays: durationDays);
    ref.invalidate(myChallengesProvider);
  }

  Future<void> joinChallenge(int challengeId) async {
    await _api.joinChallenge(challengeId);
    ref.invalidate(myChallengesProvider);
    ref.invalidate(availableChallengesProvider);
  }
}

final socialActionsProvider = Provider((ref) => SocialActions(ref));
