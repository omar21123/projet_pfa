import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Features/Wishlist/data/WishlistCubit.dart';
import 'package:connectia/Features/Wishlist/data/WishlistModel.dart';
import 'package:connectia/Features/Wishlist/data/WishlistRepo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows a bottom sheet to pick an existing wishlist or create a new one,
/// then calls [onSelected] with the chosen wishlist ID.
///
/// Provides its own [WishlistCubit] (fetches via `getWishlists`,
/// creates via `createWishlist`, adds via `addItemToWishlist`) so it works
/// from any screen.
void showChooseWishlistDialog(
  BuildContext context, {
  required int productId,
  required void Function(int wishListId, String name) onSelected,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => BlocProvider(
      create: (context) =>
          WishlistCubit(repo: locator<WishlistRepo>())..fetchWishlists(),
      child: _ChooseWishlistBottomSheet(
        productId: productId,
        onSelected: onSelected,
      ),
    ),
  );
}

class _ChooseWishlistBottomSheet extends StatefulWidget {
  final int productId;
  final void Function(int wishListId, String name) onSelected;
  const _ChooseWishlistBottomSheet({
    required this.productId,
    required this.onSelected,
  });

  @override
  State<_ChooseWishlistBottomSheet> createState() =>
      _ChooseWishlistBottomSheetState();
}

class _ChooseWishlistBottomSheetState
    extends State<_ChooseWishlistBottomSheet> {
  final _createController = TextEditingController();
  bool _isCreating = false;
  bool _isAddingItem = false;

  @override
  void dispose() {
    _createController.dispose();
    super.dispose();
  }

  void _selectWishlist(WishlistModel wishlist) {
    final alreadyIn = wishlist.items.any(
      (item) => item.productId == widget.productId,
    );

    if (alreadyIn) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ce produit est déjà dans « ${wishlist.name} ». '
            'Allez dans Mon Compte > Liste de souhaits pour le supprimer.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isAddingItem = true);
    context.read<WishlistCubit>().addItemToWishlist(
          wishListId: wishlist.wishListId,
          productId: widget.productId,
        );
  }

  void _createAndSelect() {
    final name = _createController.text.trim();
    if (name.isEmpty) return;
    context.read<WishlistCubit>().createWishlist(name);
    setState(() => _isCreating = true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return BlocListener<WishlistCubit, WishlistState>(
      listenWhen: (prev, curr) => _isCreating || _isAddingItem,
      listener: (context, state) {
        if (state is WishlistError) {
          setState(() {
            _isCreating = false;
            _isAddingItem = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          return;
        }

        // Newly created wishlist → now add item to it
        if (_isCreating && state is WishlistLoaded && state.wishlists.isNotEmpty) {
          final created = state.wishlists.last;
          setState(() {
            _isCreating = false;
            _isAddingItem = true;
          });
          context.read<WishlistCubit>().addItemToWishlist(
                wishListId: created.wishListId,
                productId: widget.productId,
              );
          return;
        }

        // Item successfully added
        if (_isAddingItem && state is WishlistItemAdded) {
          Navigator.pop(context);
          widget.onSelected(state.wishlists.last.wishListId, state.wishlistName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ajouté à « ${state.wishlistName} »')),
          );
        }
      },
      child: Material(
        color: AppColors.surface(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.secondary(context).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Ajouter à une liste',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choisissez une liste ou créez-en une nouvelle',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondary(context),
              ),
            ),
            const SizedBox(height: 16),

            // ── Existing wishlists ──
            BlocBuilder<WishlistCubit, WishlistState>(
              builder: (context, state) {
                if (state is WishlistLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                if (state is WishlistError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: AppColors.secondary(context),
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                final wishlists = state is WishlistLoaded
                    ? state.wishlists
                    : <WishlistModel>[];

                if (wishlists.isEmpty) {
                  return const SizedBox.shrink();
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: wishlists.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 2),
                    itemBuilder: (_, index) {
                      final w = wishlists[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary(context)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            w.isDefault
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: AppColors.primary(context),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          w.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                        subtitle: Text(
                          '${w.itemCount} article${w.itemCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary(context),
                          ),
                        ),
                        trailing: Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary(context),
                          size: 22,
                        ),
                        onTap: () => _selectWishlist(w),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ── Create new ──
            Container(
              decoration: BoxDecoration(
                color: AppColors.softBg(context),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.add_rounded,
                      size: 20, color: AppColors.primary(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _createController,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primaryText(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nouvelle liste...',
                        hintStyle: TextStyle(
                          color: AppColors.secondary(context)
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _createAndSelect(),
                    ),
                  ),
                  _isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(Icons.check_circle_rounded,
                              color: AppColors.primary(context), size: 28),
                          onPressed: _createAndSelect,
                          padding: EdgeInsets.zero,
                          splashRadius: 20,
                        ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
