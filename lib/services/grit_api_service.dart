import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/social_config.dart';
import '../data/models/social_models.dart';
import '../data/models/challenge.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class GritApiService {
  final String? token;

  const GritApiService({this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Uri _uri(String path) => Uri.parse('${SocialConfig.apiBaseUrl}$path');

  Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(body['error'] as String? ?? 'Request failed', statusCode: response.statusCode);
    }
    return body;
  }

  Future<({String token, SocialUser user})> register({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    final response = await http
        .post(_uri('/auth/register'),
            headers: _headers,
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
              'mobileNumber': mobileNumber,
              'password': password,
            }))
        .timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (token: body['token'] as String, user: SocialUser.fromJson(body['user'] as Map<String, dynamic>));
  }

  /// [identifier] may be an email address or a mobile number.
  Future<({String token, SocialUser user})> login({required String identifier, required String password}) async {
    final response = await http
        .post(_uri('/auth/login'), headers: _headers, body: jsonEncode({'identifier': identifier, 'password': password}))
        .timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (token: body['token'] as String, user: SocialUser.fromJson(body['user'] as Map<String, dynamic>));
  }

  Future<List<FeedPost>> getFeed() async {
    final response = await http.get(_uri('/feed'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (body['posts'] as List).map((p) => FeedPost.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<FeedPost> createPost(String content, {String postType = 'general'}) async {
    final response = await http
        .post(_uri('/feed/posts'), headers: _headers, body: jsonEncode({'content': content, 'postType': postType}))
        .timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return FeedPost.fromJson(body['post'] as Map<String, dynamic>);
  }

  Future<void> deletePost(int postId) async {
    final response = await http.delete(_uri('/feed/posts/$postId'), headers: _headers).timeout(const Duration(seconds: 60));
    _decode(response);
  }

  Future<bool> toggleLike(int postId) async {
    final response =
        await http.post(_uri('/feed/posts/$postId/like'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return body['liked'] as bool;
  }

  Future<List<PostComment>> getComments(int postId) async {
    final response =
        await http.get(_uri('/feed/posts/$postId/comments'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (body['comments'] as List).map((c) => PostComment.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<PostComment> addComment(int postId, String content) async {
    final response = await http
        .post(_uri('/feed/posts/$postId/comments'), headers: _headers, body: jsonEncode({'content': content}))
        .timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return PostComment.fromJson(body['comment'] as Map<String, dynamic>);
  }

  Future<List<SocialUser>> getFriends() async {
    final response = await http.get(_uri('/friends'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (body['friends'] as List).map((f) => SocialUser.fromJson(f as Map<String, dynamic>)).toList();
  }

  Future<List<FriendRequest>> getFriendRequests() async {
    final response = await http.get(_uri('/friends/requests'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (body['requests'] as List).map((r) => FriendRequest.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> sendFriendRequest(String email) async {
    final response = await http
        .post(_uri('/friends/request'), headers: _headers, body: jsonEncode({'email': email}))
        .timeout(const Duration(seconds: 60));
    _decode(response);
  }

  Future<void> syncStats({
    required int gritScore,
    required int streak,
    required double totalVolumeKg,
    required int totalWorkouts,
  }) async {
    final response = await http
        .post(_uri('/leaderboard/sync'),
            headers: _headers,
            body: jsonEncode({
              'gritScore': gritScore,
              'streak': streak,
              'totalVolumeKg': totalVolumeKg,
              'totalWorkouts': totalWorkouts,
            }))
        .timeout(const Duration(seconds: 60));
    _decode(response);
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await http.get(_uri('/leaderboard'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (body['entries'] as List).map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Challenge> createChallenge({
    required String title,
    required ChallengeGoalType goalType,
    required double goalTarget,
    required int durationDays,
  }) async {
    final response = await http
        .post(_uri('/challenges'),
            headers: _headers,
            body: jsonEncode({
              'title': title,
              'goalType': goalType.dbValue,
              'goalTarget': goalTarget,
              'durationDays': durationDays,
            }))
        .timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return Challenge.fromJson(body['challenge'] as Map<String, dynamic>);
  }

  Future<List<Challenge>> getMyChallenges() async {
    final response = await http.get(_uri('/challenges/mine'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (body['challenges'] as List).map((c) => Challenge.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<Challenge>> getAvailableChallenges() async {
    final response =
        await http.get(_uri('/challenges/available'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return (body['challenges'] as List).map((c) => Challenge.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<Challenge> joinChallenge(int challengeId) async {
    final response =
        await http.post(_uri('/challenges/$challengeId/join'), headers: _headers).timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return Challenge.fromJson(body['challenge'] as Map<String, dynamic>);
  }

  Future<Challenge> syncChallengeProgress(int challengeId, double progress) async {
    final response = await http
        .post(_uri('/challenges/$challengeId/progress'), headers: _headers, body: jsonEncode({'progress': progress}))
        .timeout(const Duration(seconds: 60));
    final body = _decode(response);
    return Challenge.fromJson(body['challenge'] as Map<String, dynamic>);
  }

  Future<void> acceptFriendRequest(int requestId) async {
    final response =
        await http.post(_uri('/friends/$requestId/accept'), headers: _headers).timeout(const Duration(seconds: 60));
    _decode(response);
  }

  Future<void> declineFriendRequest(int requestId) async {
    final response =
        await http.post(_uri('/friends/$requestId/decline'), headers: _headers).timeout(const Duration(seconds: 60));
    _decode(response);
  }
}
