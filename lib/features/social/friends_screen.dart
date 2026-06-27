import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/grit_theme.dart';
import '../../core/utils/haptics.dart';
import '../../providers/social_provider.dart';
import '../../services/grit_api_service.dart';
import '../../shared/widgets/grit_skeleton.dart';
import '../../data/models/social_models.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final friendsAsync = ref.watch(friendsProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);

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
                Text('FRIENDS', style: GritTextStyles.headlineSmall().copyWith(color: grit.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.person_add, color: grit.accent),
                  onPressed: () => _showAddFriendDialog(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(friendsProvider);
          ref.invalidate(friendRequestsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: GritSpacing.horizontalMargin, vertical: 20),
          children: [
            requestsAsync.when(
              loading: () => const GritSkeleton(height: 60, width: double.infinity),
              error: (_, __) => const SizedBox.shrink(),
              data: (requests) {
                if (requests.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FRIEND REQUESTS', style: GritTextStyles.sectionHeader().copyWith(color: grit.textSecondary)),
                    const SizedBox(height: 12),
                    for (final req in requests) _requestTile(context, ref, req),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
            Text('YOUR FRIENDS', style: GritTextStyles.sectionHeader().copyWith(color: grit.textSecondary)),
            const SizedBox(height: 12),
            friendsAsync.when(
              loading: () => const GritSkeleton(height: 60, width: double.infinity),
              error: (e, st) => Text(
                e is ApiException ? e.message : 'Could not load friends',
                style: GritTextStyles.label(12, color: grit.textSecondary),
              ),
              data: (friends) {
                if (friends.isEmpty) {
                  return Text('No friends yet — tap + to add one by username.',
                      style: GritTextStyles.label(12, color: grit.muted));
                }
                return Column(
                  children: friends.map((f) => _friendTile(context, f)).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestTile(BuildContext context, WidgetRef ref, FriendRequest req) {
    final grit = Theme.of(context).grit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
      child: Row(
        children: [
          Expanded(
            child: Text(req.user.displayName, style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary)),
          ),
          GestureDetector(
            onTap: () {
              GritHaptics.selectionTick();
              ref.read(socialActionsProvider).acceptFriendRequest(req.requestId);
            },
            child: Icon(Icons.check_circle, color: grit.success, size: 26),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              GritHaptics.selectionTick();
              ref.read(socialActionsProvider).declineFriendRequest(req.requestId);
            },
            child: Icon(Icons.cancel, color: grit.failureSet, size: 26),
          ),
        ],
      ),
    );
  }

  Widget _friendTile(BuildContext context, SocialUser user) {
    final grit = Theme.of(context).grit;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: grit.surface, border: Border.all(color: grit.border)),
      child: Row(
        children: [
          Text(user.displayName, style: GritTextStyles.tileTitle().copyWith(color: grit.textPrimary)),
          const SizedBox(width: 8),
          Text(user.email, style: GritTextStyles.label(11, color: grit.textSecondary)),
        ],
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final grit = Theme.of(context).grit;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: grit.surface,
        title: Text('ADD FRIEND', style: GritTextStyles.titleMedium().copyWith(color: grit.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: GritTextStyles.label(13, color: grit.textPrimary),
          decoration: InputDecoration(
            hintText: 'Their email address',
            hintStyle: GritTextStyles.label(13, color: grit.muted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('CANCEL', style: GritTextStyles.label(13, color: grit.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final email = controller.text.trim();
              Navigator.of(dialogContext).pop();
              if (email.isEmpty) return;
              try {
                await ref.read(socialActionsProvider).sendFriendRequest(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Friend request sent to $email')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e is ApiException ? e.message : 'Could not send request')),
                  );
                }
              }
            },
            child: Text('SEND', style: GritTextStyles.label(13, color: grit.accent)),
          ),
        ],
      ),
    );
  }
}
