import 'dart:ui';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Core/Navigations/CustomNavigator.dart';
import 'package:connectia/Core/shared/Models/VendorPublicProfileModel.dart';
import 'package:connectia/Core/shared/Views/VendorRepo.dart';
import 'package:connectia/Features/Home/data/Models/ProductModel.dart';
import 'package:connectia/Features/Home/widgets/Products/ProductCard.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

const double _kHPad = 20;

class VendorProfilePage extends StatefulWidget {
  final int vendorProfileId;
  final String storeName;
  const VendorProfilePage({
    super.key,
    required this.vendorProfileId,
    required this.storeName,
  });

  @override
  State<VendorProfilePage> createState() => _VendorProfilePageState();
}

class _VendorProfilePageState extends State<VendorProfilePage> {
  VendorPublicProfileModel? _profile;
  bool _isLoadingProfile = true;
  String? _error;

  List<ProductModel> _products = [];
  bool _isLoadingProducts = true;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchProducts();
  }

  Future<void> _fetchProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProfile = true;
      _error = null;
    });

    try {
      final result = await locator<VendorRepo>().getPublicProfile(
        vendorProfileId: widget.vendorProfileId,
      );
      if (!mounted) return;
      result.fold(
        (failure) => setState(() {
          _error = failure.displayMessage;
          _isLoadingProfile = false;
        }),
        (profile) => setState(() {
          _profile = profile;
          _isLoadingProfile = false;
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _fetchProducts({bool loadMore = false}) async {
    if (!mounted) return;
    if (loadMore) {
      if (_loadingMore || _currentPage > _lastPage) return;
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _isLoadingProducts = true;
        _currentPage = 1;
      });
    }

    try {
      final pageToFetch = loadMore ? _currentPage + 1 : 1;
      final result = await locator<VendorRepo>().getVendorProducts(
        vendorProfileId: widget.vendorProfileId,
        page: pageToFetch,
        perPage: 20,
      );
      if (!mounted) return;
      result.fold(
        (failure) => setState(() => _loadingMore = false),
        (data) => setState(() {
          if (loadMore) {
            _products.addAll(data.products);
            _currentPage = pageToFetch;
          } else {
            _products = data.products;
          }
          _lastPage = data.lastPage;
          _isLoadingProducts = false;
          _loadingMore = false;
        }),
      );
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: _isLoadingProfile
          ? _buildShimmer()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final p = _profile!;
    return CustomScrollView(
      slivers: [
        _VendorSliverAppBar(profile: p),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Stats ──
              Padding(
                padding: const EdgeInsets.fromLTRB(_kHPad, 20, _kHPad, 0),
                child: Row(
                  children: [
                    _StatBox(
                      icon: Icons.inventory_2_outlined,
                      value: '${p.totalProducts}',
                      label: 'Produits',
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      icon: Icons.shopping_bag_outlined,
                      value: '${p.totalSales}',
                      label: 'Ventes',
                    ),
                    const SizedBox(width: 10),
                    _StatBox(
                      icon: Icons.star_rounded,
                      value: p.rating.toStringAsFixed(1),
                      label: '${p.reviewCount} avis',
                    ),
                  ],
                ),
              ),

              // ── Verification badges ──
              Padding(
                padding: const EdgeInsets.fromLTRB(_kHPad, 16, _kHPad, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (p.identityVerified)
                      _Badge(
                        icon: Icons.verified_user_rounded,
                        label: 'Identité',
                        color: AppColors.successColor(context),
                      ),
                    if (p.businessVerified)
                      _Badge(
                        icon: Icons.business_rounded,
                        label: 'Entreprise',
                        color: AppColors.successColor(context),
                      ),
                    if (p.bankVerified)
                      _Badge(
                        icon: Icons.account_balance_rounded,
                        label: 'Banque',
                        color: AppColors.successColor(context),
                      ),
                  ],
                ),
              ),

              // ── Address ──
              if (p.address != null && p.address!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kHPad, 16, _kHPad, 0),
                  child: _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: p.address!,
                  ),
                ),
              ],

              // ── Categories ──
              if (p.categories != null && p.categories!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kHPad, 10, _kHPad, 0),
                  child: _InfoChip(
                    icon: Icons.category_outlined,
                    label: p.categories!,
                  ),
                ),
              ],

              // ── Description ──
              if (p.description != null && p.description!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(_kHPad, 20, _kHPad, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'À PROPOS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primaryText(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        p.description!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary(context),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Products section title ──
              Padding(
                padding: const EdgeInsets.fromLTRB(_kHPad, 28, _kHPad, 12),
                child: Text(
                  'Produits (${p.totalProducts})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryText(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Products grid ──
        if (_isLoadingProducts)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: _kHPad),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 290,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ProductShimmer(),
                childCount: 6,
              ),
            ),
          )
        else if (_products.isEmpty)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(_kHPad, 0, _kHPad, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                mainAxisExtent: 290,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == _products.length - 1 && !_loadingMore) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fetchProducts(loadMore: true);
                    });
                  }
                  final product = _products[index];
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return ProductCard(
                        product: product,
                        width: constraints.maxWidth,
                        onTap: () {
                          CustomNavigator.navigateProductDetailsPage(
                            product.id,
                          );
                        },
                      );
                    },
                  );
                },
                childCount: _products.length,
              ),
            ),
          ),

        // ── Load more indicator ──
        if (_loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: Center(
                child:
                    SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: 48, color: AppColors.secondary(context)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _fetchProfile();
                _fetchProducts();
              },
              child: const Text('Réessayer'),
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
            Container(height: 260, width: double.infinity, color: Colors.white),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _kHPad),
              child: Row(
                children: List.generate(
                  3,
                  (_) => Expanded(
                    child: Container(
                      height: 72,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SliverAppBar with banner ──
class _VendorSliverAppBar extends StatelessWidget {
  final VendorPublicProfileModel profile;
  const _VendorSliverAppBar({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 260,
      backgroundColor: AppColors.background(context),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleIconBtn(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => context.pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16, right: 16),
        title: Text(
          profile.storeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner
            if (profile.bannerUrl != null && profile.bannerUrl!.isNotEmpty)
              Image.network(
                profile.bannerUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.accent20(context),
                ),
              )
            else
              Container(
                color: AppColors.primary(context).withValues(alpha: 0.15),
              ),
            // Blur + dark overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.black.withValues(alpha: 0.1)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
            // Logo
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipOval(
                      child: Container(
                        width: 88,
                        height: 88,
                        color: Colors.white,
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(
                          child: profile.logoUrl != null &&
                                  profile.logoUrl!.isNotEmpty
                              ? Image.network(
                                  profile.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.storefront_rounded,
                                    size: 36,
                                    color: AppColors.primary(context),
                                  ),
                                )
                              : Icon(
                                  Icons.storefront_rounded,
                                  size: 36,
                                  color: AppColors.primary(context),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (profile.rating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 16, color: Colors.amber.shade600),
                            const SizedBox(width: 4),
                            Text(
                              profile.rating.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Verified badge
            if (profile.identityVerified || profile.businessVerified)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 15,
                            color: AppColors.successColor(context)),
                        const SizedBox(width: 5),
                        Text(
                          'Vendeur vérifié',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.successColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.25),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary(context).withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary(context)),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary(context)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
