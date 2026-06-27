import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/social_models.dart';
import '../../providers/social_provider.dart';
import '../../services/grit_api_service.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../app/routes.dart';
import 'package:go_router/go_router.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    // Auth is guaranteed at this point — the router redirects to the login
    // screen before any other route is reachable when logged out.
    final auth = ref.watch(socialAuthProvider);
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      backgroundColor: grit.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: grit.border, width: 1))),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: grit.textPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text('COMMUNITY', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.emoji_events, color: grit.accent),
                  onPressed: () => context.push(GritRoutes.challenges),
                ),
                IconButton(
                  icon: Icon(Icons.leaderboard, color: grit.accent),
                  onPressed: () => context.push(GritRoutes.leaderboard),
                ),
                IconButton(
                  icon: Icon(Icons.group, color: grit.accent),
                  onPressed: () => context.push(GritRoutes.friends),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(feedProvider),
        child: feedAsync.when(
          loading: () => const Center(child: GritSkeleton(height: 100, width: double.infinity)),
          error: (e, st) => Center(
            child: Text(e is ApiException ? e.message : 'Could not reach the server',
                style: GritTextStyles.label(13, color: grit.textSecondary)),
          ),
          data: (posts) => ListView(
            padding: const EdgeInsets.all(GritSpacing.horizontalMargin),
            children: [
              _composeBox(context, ref),
              const SizedBox(height: 20),
              if (posts.isEmpty)
                Text('No posts yet. Add a friend and share your first PR!',
                    style: GritTextStyles.label(12, color: grit.muted))
              else
                for (final post in posts) _postCard(context, ref, post, auth.user!.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composeBox(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final controller = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: GritTextStyles.label(13, color: grit.textPrimary),
              decoration: InputDecoration(
                hintText: "Share a workout, PR, or update...",
                hintStyle: GritTextStyles.label(13, color: grit.muted),
              ),
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (controller.text.trim().isEmpty) return;
              GritHaptics.mediumImpact();
              await ref.read(socialActionsProvider).createPost(controller.text.trim());
              controller.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: grit.accent),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(BuildContext context, WidgetRef ref, FeedPost post, int myUserId) {
    final grit = Theme.of(context).grit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(post.author.displayName,
                    style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary)),
              ),
              if (post.author.id == myUserId)
                GestureDetector(
                  onTap: () => ref.read(socialActionsProvider).deletePost(post.id),
                  child: Icon(Icons.delete_outline, size: 18, color: grit.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(post.content, style: GritTextStyles.label(13, color: grit.textPrimary, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  GritHaptics.selectionTick();
                  ref.read(socialActionsProvider).toggleLike(post.id);
                },
                child: Row(
                  children: [
                    Icon(
                      post.likedByMe ? Icons.front_hand : Icons.front_hand_outlined,
                      size: 18,
                      color: post.likedByMe ? grit.accent : grit.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text('${post.likeCount}', style: GritTextStyles.label(12, color: grit.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => _showComments(context, ref, post.id),
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 18, color: grit.textSecondary),
                    const SizedBox(width: 4),
                    Text('${post.commentCount}', style: GritTextStyles.label(12, color: grit.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, WidgetRef ref, int postId) {
    final grit = Theme.of(context).grit;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: grit.background,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (sheetCtx, scrollController) {
              return FutureBuilder<List<PostComment>>(
                future: ref.read(socialActionsProvider).getComments(postId),
                builder: (futureContext, snapshot) {
                  final comments = snapshot.data ?? [];
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(width: 36, height: 4, decoration: BoxDecoration(color: grit.border)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: snapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: comments.length,
                                itemBuilder: (itemContext, index) {
                                  final c = comments[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.author.displayName,
                                            style: GritTextStyles.label(11, weight: FontWeight.w700, color: grit.accent)),
                                        Text(c.content, style: GritTextStyles.label(13, color: grit.textPrimary)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                style: GritTextStyles.label(13, color: grit.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  hintStyle: GritTextStyles.label(13, color: grit.muted),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                if (controller.text.trim().isEmpty) return;
                                await ref.read(socialActionsProvider).addComment(postId, controller.text.trim());
                                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: grit.accent),
                                child: const Icon(Icons.send, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
