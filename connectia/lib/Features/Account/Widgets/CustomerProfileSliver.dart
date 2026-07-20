import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Carte de profil client à utiliser dans un CustomScrollView (Sliver).
/// Couleurs pilotées par AppColors -> s'adapte automatiquement au thème.
class CustomerProfileSliver extends StatelessWidget {
  final String fullName;
  final String email;
  final String? avatarUrl;
  final int achatsCount;
  final int favorisCount;
  final int wishlistItems;
  final VoidCallback? onEditTap;
  final EdgeInsetsGeometry padding;
  const CustomerProfileSliver({
    super.key,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.achatsCount,
    required this.favorisCount,
    required this.wishlistItems,
    this.onEditTap,
    required this.padding,
  });

  String get _initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  bool get _hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final onPrimary = AppColors.onPrimary(context);

    return SliverToBoxAdapter(
      child: Padding(
        padding: padding,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary(context),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAvatar(onPrimary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: TextStyle(
                            color: onPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: TextStyle(
                            color: onPrimary.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onEditTap,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: onPrimary.withValues(alpha: 0.12),
                      child: Icon(Icons.edit, color: onPrimary, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: onPrimary.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    value: '$achatsCount',
                    label: 'Achats',
                    textColor: onPrimary,
                  ),
                  _VerticalDivider(color: onPrimary),
                  _StatItem(
                    value: '$favorisCount',
                    label: 'Favoris',
                    textColor: onPrimary,
                  ),
                  _VerticalDivider(color: onPrimary),
                  _StatItem(
                    value: '$wishlistItems',
                    label: 'Wishlist',
                    textColor: onPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color onPrimary) {
    if (_hasAvatar) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          // Si l'URL est cassée / réseau indisponible, on retombe sur les initiales
          errorBuilder: (context, error, stackTrace) =>
              _buildInitialsAvatar(onPrimary),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _buildInitialsAvatar(onPrimary, loading: true);
          },
        ),
      );
    }
    return _buildInitialsAvatar(onPrimary);
  }

  Widget _buildInitialsAvatar(Color onPrimary, {bool loading = false}) {
    return CircleAvatar(
      radius: 34,
      backgroundColor: onPrimary.withValues(alpha: 0.2),
      child: loading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: onPrimary.withValues(alpha: 0.7),
              ),
            )
          : Text(
              _initials,
              style: TextStyle(
                color: onPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color textColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  final Color color;

  const _VerticalDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      width: 1,
      color: color.withValues(alpha: 0.15),
    );
  }
}
