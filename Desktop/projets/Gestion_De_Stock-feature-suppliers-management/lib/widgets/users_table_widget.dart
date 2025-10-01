import 'package:flutter/material.dart';
import '../models/models.dart';

class UsersTableWidget extends StatelessWidget {
  final List<User> users;
  final bool embedInCard;

  const UsersTableWidget({
    Key? key,
    required this.users,
    this.embedInCard = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final showHeader = !embedInCard;

    final inviteButton =
        embedInCard
            ? OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.mail_outline_rounded, size: 18),
              label: const Text('Inviter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                ),
              ),
            )
            : TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Voir plus'),
            );

    Widget buildUserTile(User user) {
      final initials =
          user.name.isNotEmpty
              ? user.name
                  .split(' ')
                  .where((part) => part.trim().isNotEmpty)
                  .take(2)
                  .map((part) => part[0])
                  .join()
                  .toUpperCase()
              : 'U';

      final roleColor = switch (user.role.toLowerCase()) {
        'admin' =>
          (isDarkMode ? Colors.orange.shade200 : Colors.orange.shade700),
        'manager' => (isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700),
        _ => (isDarkMode ? Colors.green.shade200 : Colors.green.shade700),
      };

      final secondaryLabel = 'ID #${user.id.toString().padLeft(4, '0')}';

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              child: Text(
                initials,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.grey.shade900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    secondaryLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Chip(
              label: Text(
                user.role,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDarkMode ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: roleColor.withValues(
                alpha: embedInCard ? 0.85 : 0.9,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            ),
          ],
        ),
      );
    }

    final contentChildren = <Widget>[
      if (showHeader) ...[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Utilisateurs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              inviteButton,
            ],
          ),
        ),
      ] else ...[
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: inviteButton,
          ),
        ),
      ],
    ];

    if (users.isEmpty) {
      contentChildren.add(
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Aucun utilisateur enregistré.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ),
      );
    } else {
      contentChildren.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              for (int index = 0; index < users.length; index++)
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: index == users.length - 1 ? 0 : 12,
                  ),
                  child: buildUserTile(users[index]),
                ),
            ],
          ),
        ),
      );
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: contentChildren,
    );

    if (embedInCard) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
              isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
        ],
      ),
      child: content,
    );
  }
}
