class SocialUser {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  const SocialUser({required this.id, required this.firstName, required this.lastName, required this.email});

  String get displayName => '$firstName $lastName';

  factory SocialUser.fromJson(Map<String, dynamic> json) => SocialUser(
        id: json['id'] as int,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        email: json['email'] as String,
      );
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String displayName;
  final int gritScore;
  final int streak;
  final double totalVolumeKg;
  final int totalWorkouts;
  final bool isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.gritScore,
    required this.streak,
    required this.totalVolumeKg,
    required this.totalWorkouts,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: user['id'] as int,
      displayName: '${user['firstName']} ${user['lastName']}',
      gritScore: json['gritScore'] as int,
      streak: json['streak'] as int,
      totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
      totalWorkouts: json['totalWorkouts'] as int,
      isMe: json['isMe'] as bool,
    );
  }
}

class FriendRequest {
  final int requestId;
  final SocialUser user;

  const FriendRequest({required this.requestId, required this.user});

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
        requestId: json['requestId'] as int,
        user: SocialUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class FeedPost {
  final int id;
  final String content;
  final String postType;
  final String createdAt;
  final SocialUser author;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;

  const FeedPost({
    required this.id,
    required this.content,
    required this.postType,
    required this.createdAt,
    required this.author,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
        id: json['id'] as int,
        content: json['content'] as String,
        postType: json['postType'] as String,
        createdAt: json['createdAt'] as String,
        author: SocialUser.fromJson(json['author'] as Map<String, dynamic>),
        likeCount: json['likeCount'] as int,
        commentCount: json['commentCount'] as int,
        likedByMe: json['likedByMe'] as bool,
      );

  FeedPost copyWith({int? likeCount, int? commentCount, bool? likedByMe}) => FeedPost(
        id: id,
        content: content,
        postType: postType,
        createdAt: createdAt,
        author: author,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
      );
}

class PostComment {
  final int id;
  final String content;
  final String createdAt;
  final SocialUser author;

  const PostComment({required this.id, required this.content, required this.createdAt, required this.author});

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as int,
        content: json['content'] as String,
        createdAt: json['createdAt'] as String,
        author: SocialUser.fromJson(json['author'] as Map<String, dynamic>),
      );
}
