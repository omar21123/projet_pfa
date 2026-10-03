import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/api/Env/ApiEnvironment.dart';
import 'package:connectia/Core/shared/Models/BrandModel.dart';
import 'package:connectia/Features/Home/data/Models/ProductDetailModel.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/data/ProductDetailRepo.dart';
import 'package:connectia/Features/Home/data/ProductRepo.dart';
import 'package:connectia/Features/Home/widgets/Products/AddToCartButton.dart';
import 'package:connectia/Features/Home/widgets/Products/BrandVerifiedBadge.dart';
import 'package:connectia/Features/Home/widgets/Products/PaymentMethodSelector.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductDescription.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductHeroImage.dart';
import 'package:connectia/Features/Account/data/FavoritesCubit.dart';
import 'package:connectia/Features/Cart/data/CartRepo.dart';
import 'package:connectia/Features/Cart/data/Models/CartItemModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductDetailsStats.dart';
import 'package:connectia/Features/Home/widgets/Products/QuantitySelector.dart';
import 'package:connectia/Features/Search/widgets/SearchCategoryChip.dart';
import 'package:connectia/Features/Wishlist/data/WishlistCubit.dart';
import 'package:connectia/Features/Wishlist/widgets/ChooseWishlistDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_dialog/pro_dialog.dart';
import 'package:shimmer/shimmer.dart';

const double _kHPad = 20;
const double _kSectionGap = 24;

class ProductDetailsPage extends StatefulWidget {
  final String productId;
  final String searchTerm;
  final bool fromSearch;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    this.searchTerm = '',
    this.fromSearch = false,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  ProductDetailModel? _product;
  bool _isLoading = true;
  String? _error;
  int _selectedCombinationId = -1;
  bool _isLiked = false;
  bool _isWishlisted = false;
  SimilarProducts? _similarProducts;
  int _selectedQuantity = 1;

  /// configId → optionId : tracks user's option selections per config
  final Map<int, int> _selectedOptions = {};

  /// Initialize _selectedOptions with each config's default option
  void _initDefaultOptions(ProductDetailModel p) {
    _selectedOptions.clear();
    for (final config in p.configs) {
      final def = config.options.firstWhere(
        (o) => o.isDefault,
        orElse: () => config.options.first,
      );
      _selectedOptions[config.configId] = def.optionId;
    }
    _matchCombination();
  }

  /// Find and set the combination matching the current selected options.
  /// Picks the combination whose configId+optionId matches the last selected config.
  void _matchCombination() {
    if (_product == null || _selectedOptions.isEmpty) return;

    // Try to find a combination matching any of the selected options (most
    // recently changed first — iterate map values in reverse insertion order
    // isn't possible, so just search all and prefer exact multi-match).
    ProductCombination? best;
    for (final entry in _selectedOptions.entries) {
      final match = _product!.combinations.firstWhere(
        (c) => c.configId == entry.key && c.optionId == entry.value,
        orElse: () => const ProductCombination(
          combinationId: -1, sku: '', price: 0, compareAtPrice: 0,
          stock: 0, isDefault: false, configId: 0, optionId: 0,
        ),
      );
      if (match.combinationId != -1) {
        best = match;
        break; // use the first matching combination
      }
    }
    if (best != null) {
      _selectedCombinationId = best.combinationId;
    } else {
      _selectedCombinationId = -1;
    }
  }

  void _onOptionSelected(int configId, int optionId) {
    setState(() {
      _selectedOptions[configId] = optionId;
      _matchCombination();
    });
  }

  /// Current selected combination (or null)
  ProductCombination? get _activeCombination {
    if (_selectedCombinationId == -1 || _product == null) return null;
    try {
      return _product!.combinations
          .firstWhere((c) => c.combinationId == _selectedCombinationId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await locator<ProductDetailRepo>().getProductInfo(
        productId: widget.productId,
        fromSearch: widget.fromSearch,
        searchTerm: widget.searchTerm,
      );

      if (!mounted) return;

      result.fold(
        (failure) => setState(() {
          _error = failure.displayMessage;
          _isLoading = false;
        }),
        (product) {
          setState(() {
            _product = product;
            _isLiked = product.isLiked;
            _isWishlisted = product.isWishlisted;
            _isLoading = false;
          });
          _initDefaultOptions(product);
          _fetchSimilarProducts();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSimilarProducts() async {
    if (!mounted || _product == null) return;
    final productId = int.tryParse(_product!.id);
    if (productId == null) return;

    try {
      final result = await locator<ProductRepo>().getSimilarProducts(
        productId: productId,
        limit: 10,
      );
      if (!mounted) return;
      result.fold(
        (failure) {},
        (similar) => setState(() => _similarProducts = similar),
      );
    } catch (_) {}
  }

  double get _currentPrice {
    final combo = _activeCombination;
    if (combo != null && combo.price > 0) return combo.price;
    final base = _product?.effectivePrice ?? 0;
    return base > 0 ? base : 0;
  }

  double get _currentComparePrice {
    final combo = _activeCombination;
    if (combo != null && combo.compareAtPrice > 0) return combo.compareAtPrice;
    return 0;
  }

  int get _currentStock {
    final combo = _activeCombination;
    if (combo != null) return combo.stock;
    return _product?.stock ?? 0;
  }

  String get _currentImage {
    final combo = _activeCombination;
    if (combo?.combinationImage != null &&
        combo!.combinationImage!.isNotEmpty) {
      final url = combo.combinationImage!;
      if (url.startsWith('http')) return url;
      final base = ApiEnvironment.baseUrl;
      final trimmed =
          base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
      return '$trimmed/$url';
    }
    return _product?.resolvedFirstImage ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WishlistCubit(repo: locator())..fetchWishlists(),
      child: BlocListener<FavoritesCubit, FavoritesState>(
        listener: (context, state) {
          if (state is FavoritesLoaded && _product != null) {
            final productId = int.tryParse(widget.productId) ?? 0;
            final cubitFavorite = context.read<FavoritesCubit>().isFavorite(productId);
            if (_isLiked != cubitFavorite) {
              setState(() => _isLiked = cubitFavorite);
            }
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.softBg(context),
          body: _isLoading
              ? _buildShimmer()
              : _error != null
                  ? _buildError()
                  : _buildContent(),
        bottomNavigationBar: _product != null
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(_kHPad, 12, _kHPad, 12),
                decoration: BoxDecoration(
                  color: AppColors.background(context),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AddToCartButton(
                        onTap: () => _showAddToCartDialog(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary(context),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Acheter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
        ),
      ),
    );
  }

  Widget _buildContent() {
    final p = _product!;
    final vendor = p.vendor;

    return Column(
      children: [
        // ── Hero image ──
        ProductHeroImage(
          productId: p.id,
          imageUrl: _currentImage,
          height: 280,
          isLiked: _isLiked,
          isWishlisted: _isWishlisted,
          onBackTap: () => context.pop(),
          onLikeTap: () {
            final productId = int.tryParse(widget.productId) ?? 0;
            final wasLiked = _isLiked;
            setState(() => _isLiked = !wasLiked);
            context.read<FavoritesCubit>().toggleFavorite(productId);
          },
          onWishlistTap: () {
            final productId = int.tryParse(p.id);
            if (productId == null) return;
            final wishlistCubit = context.read<WishlistCubit>();
            if (_isWishlisted) {
              // Remove from wishlist
              setState(() => _isWishlisted = false);
              wishlistCubit.removeProductFromWishlists(productId);
            } else {
              // Add to wishlist
              showChooseWishlistDialog(
                context,
                productId: productId,
                onSelected: (wishListId, name) {
                  setState(() => _isWishlisted = true);
                },
              );
            }
          },
        ),

        // ── Scrollable body ──
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              // ── Tags ──
              if (p.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kHPad, 12, _kHPad, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: p.tags
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Color(int.parse(
                                        tag.color.replaceFirst('#', '0xFF')))
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(int.parse(
                                      tag.color.replaceFirst('#', '0xFF'))),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),

              // ── Brand ──
              Padding(
                padding: const EdgeInsets.fromLTRB(_kHPad, 16, _kHPad, 0),
                child: BrandVerifiedBadge(
                  label: p.brandName,
                  isVerified: vendor?.identityVerified ?? false,
                  onTap: vendor != null
                      ? () async {
                          await CustomNavigator.navigateBrandInfoPage(
                            BrandModel(
                              name: vendor.storeName,
                              logoUrl: vendor.logoUrl ?? '',
                              website: '',
                              description: '',
                              countryName: '',
                              isVerified: vendor.businessVerified,
                            ),
                          );
                        }
                      : null,
                ),
              ),

              // ── Title ──
              Padding(
                padding: const EdgeInsets.fromLTRB(_kHPad, 16, _kHPad, 0),
                child: Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText(context),
                    height: 1.2,
                  ),
                ),
              ),

              // ── Model ──
              if (p.modelName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kHPad, 4, _kHPad, 0),
                  child: Text(
                    'Modele : ${p.modelName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.secondary(context),
                    ),
                  ),
                ),

              // ── Price ──
              Padding(
                padding: const EdgeInsets.fromLTRB(_kHPad, 10, _kHPad, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_currentPrice.toStringAsFixed(2)} MAD',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary(context),
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    if (p.hasPromotion) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          '${_currentComparePrice.toStringAsFixed(2)} MAD',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            color: AppColors.secondary(context),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: AppColors.secondary(context)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        margin: const EdgeInsets.only(bottom: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.wishlist(context).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.promotion!.discountLabelFormatted,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.wishlist(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Stock ──
              Padding(
                padding: const EdgeInsets.fromLTRB(_kHPad, 8, _kHPad, 0),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 14, color: AppColors.secondary(context)),
                    const SizedBox(width: 4),
                    Text(
                      _currentStock > 0
                          ? 'En stock ($_currentStock)'
                          : 'Rupture de stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: _currentStock > 0
                            ? Colors.green.shade600
                            : AppColors.wishlist(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Stats ──
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(_kHPad, _kSectionGap, _kHPad, 0),
                child: ProductDetailsStats(
                  rating: '${p.totalWishlists}',
                  sales: _formatCount(p.totalSales),
                  favorites: _formatCount(p.totalLiked),
                ),
              ),

              // ── Categories ──
              if (p.categories.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(_kHPad, 12, _kHPad, 0),
                    itemCount: p.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return SearchCategoryChip(
                        isSelected: p.categories[index].isPrimary,
                        label: p.categories[index].name,
                        onTap: () {},
                      );
                    },
                  ),
                ),

              // ── Configs ──
              if (p.configs.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      _kHPad, _kSectionGap, _kHPad, 0),
                  child: _buildConfigsSection(p),
                ),

              // ── Quantity ──
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(_kHPad, _kSectionGap, _kHPad, 0),
                child: QuantitySelector(
                  initialValue: 1,
                  max: _currentStock,
                  onChanged: (qty) => _selectedQuantity = qty,
                ),
              ),

              // // ── Payment ──
              // if (p.paymentMethods.isNotEmpty)
              //   Padding(
              //     padding: const EdgeInsets.fromLTRB(
              //         _kHPad, _kSectionGap, _kHPad, 0),
              //     child: PaymentMethodSelector(
              //       availableMethods: p.paymentMethods,
              //       onChanged: (method) {},
              //     ),
              //   ),

              // ── Description ──
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(_kHPad, _kSectionGap, _kHPad, 0),
                child: ProductDescription(description: p.description),
              ),

              // ── Vendor ──
              if (vendor != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      _kHPad, _kSectionGap, _kHPad, 0),
                  child: GestureDetector(
                    onTap: () {
                      final vendorId = int.tryParse(vendor.id);
                      if (vendorId == null) return;
                      CustomNavigator.navigateVendorProfilePage(
                        vendorProfileId: vendorId,
                        storeName: vendor.storeName,
                      );
                    },
                    child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            AppColors.secondary(context).withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppColors.primary(context).withValues(alpha: 0.1),
                          backgroundImage: vendor.logoUrl != null &&
                                  vendor.logoUrl!.isNotEmpty
                              ? NetworkImage(vendor.logoUrl!)
                              : null,
                          child: vendor.logoUrl == null ||
                                  vendor.logoUrl!.isEmpty
                              ? Icon(Icons.storefront,
                                  color: AppColors.primary(context))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vendor.storeName,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryText(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  if (vendor.identityVerified)
                                    _buildVerifyBadge(
                                        Icons.verified_user,
                                        'Identite verifiee'),
                                  if (vendor.businessVerified) ...[
                                    const SizedBox(width: 6),
                                    _buildVerifyBadge(Icons.business_center,
                                        'Business verifie'),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: AppColors.secondary(context)),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom padding for safe area ──
              const SizedBox(height: 20),

              // ── Similar Products ──
              if (_similarProducts != null) ...[
                if (_similarProducts!.similar.isNotEmpty)
                  _SimilarSection(
                    title: 'Produits similaires',
                    products: _similarProducts!.similar,
                  ),
                if (_similarProducts!.similarInCategories.isNotEmpty)
                  _SimilarSection(
                    title: 'Dans les mêmes catégories',
                    products: _similarProducts!.similarInCategories,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigsSection(ProductDetailModel p) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: AppColors.accent30(context), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personnalisons votre produit',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText(context),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cette personnalisation est proposee par le vendeur.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ...p.configs.map((config) {
            final selectedOptionId =
                _selectedOptions[config.configId] ?? config.options.first.optionId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: config.options.map((option) {
                      final isSelected = selectedOptionId == option.optionId;
                      return GestureDetector(
                        onTap: () => _onOptionSelected(
                            config.configId, option.optionId),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary(context)
                                    .withValues(alpha: 0.1)
                                : AppColors.surface(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary(context)
                                  : AppColors.secondary(context)
                                      .withValues(alpha: 0.15),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 14,
                                    color: AppColors.primary(context),
                                  ),
                                ),
                              Text(
                                option.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary(context)
                                      : AppColors.primaryText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVerifyBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.green.shade600),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCartDialog() {
    final p = _product;
    if (p == null) return;

    final price = p.effectivePrice;
    final productId = int.tryParse(p.id);
    if (productId == null) return;

    showProDialog(
      context,
      type: DialogType.info,
      iconColor: AppColors.primary(context),
      iconBackgroundColor: AppColors.accent20(context),
      title: 'Ajouter au panier',
      description:
          '${p.name}\n${_selectedQuantity}× ${price.toStringAsFixed(0)} MAD',
      buttons: [
        DialogButton(
          text: 'Annuler',
          style: DialogButtonStyle.outlined,
          onPressed: () => Navigator.pop(context),
        ),
        DialogButton(
          text: 'Confirmer',
          isPrimary: true,
          icon: Icons.shopping_cart_outlined,
          onPressed: () async {
            Navigator.pop(context);
            final request = AddToCartRequest(
              productId: productId,
              fromSearch: widget.fromSearch,
              searchTerm: widget.searchTerm,
              compositionId: _selectedCombinationId != -1
                  ? _selectedCombinationId
                  : null,
              quantity: _selectedQuantity,
              unitPrice: price,
            );
            final success =
                await locator<CartRepo>().addToCart(request: request);
            if (!mounted) return;
            success.fold(
              (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(failure.displayMessage),
                    backgroundColor: AppColors.logout(context),
                  ),
                );
              },
              (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produit ajouté au panier'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: AppColors.secondary(context)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProduct,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.softBg(context),
      highlightColor: AppColors.surface(context),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              width: double.infinity,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kHPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(80, 24),
                  const SizedBox(height: 16),
                  _shimmerBox(200, 28),
                  const SizedBox(height: 8),
                  _shimmerBox(120, 16),
                  const SizedBox(height: 12),
                  _shimmerBox(160, 32),
                  const SizedBox(height: 8),
                  _shimmerBox(100, 14),
                  const SizedBox(height: 24),
                  _shimmerBox(double.infinity, 56),
                  const SizedBox(height: 24),
                  _shimmerBox(double.infinity, 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

/// Horizontal scrollable section showing similar products.
class _SimilarSection extends StatelessWidget {
  final String title;
  final List<ProductModel> products;
  const _SimilarSection({required this.title, required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(_kHPad, _kSectionGap, _kHPad, 12),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText(context),
            ),
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _kHPad),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final p = products[index];
              return _SimilarProductCard(product: p);
            },
          ),
        ),
      ],
    );
  }
}

class _SimilarProductCard extends StatelessWidget {
  final ProductModel product;
  const _SimilarProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        CustomNavigator.navigateProductDetailsPage(product.id);
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary(context).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                product.resolvedImageUrl,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppColors.accent20(context),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.secondary(context),
                    size: 28,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText(context),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${product.effectivePrice.toStringAsFixed(0)} MAD',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
