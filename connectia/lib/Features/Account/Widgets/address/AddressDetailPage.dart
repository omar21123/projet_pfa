import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Features/Account/data/AddressRepo.dart';
import 'package:connectia/Features/Account/data/Models/AddressModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:pro_dialog/pro_dialog.dart';
import 'package:shimmer/shimmer.dart';

class AddressDetailPage extends StatefulWidget {
  final int addressId;
  const AddressDetailPage({super.key, required this.addressId});

  @override
  State<AddressDetailPage> createState() => _AddressDetailPageState();
}

class _AddressDetailPageState extends State<AddressDetailPage> {
  AddressModel? _address;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await locator<AddressRepo>().getAddress(
      addressId: widget.addressId,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.displayMessage;
        _isLoading = false;
      }),
      (address) => setState(() {
        _address = address;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      body: _isLoading
          ? _buildShimmer()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final a = _address!;
    final hasCoords = a.latitude != null && a.longitude != null;
    final latLng =
        hasCoords ? LatLng(a.latitude!, a.longitude!) : null;

    return CustomScrollView(
      slivers: [
        // ── AppBar ──
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.background(context),
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryText(context)),
          title: Text(
            'Détails de l\'adresse',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryText(context),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Map preview ──
              if (hasCoords)
                Container(
                  height: 200,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary(context).withValues(alpha: 0.1),
                    ),
                  ),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: latLng!,
                      initialZoom: 15,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.connectia.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary(context),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.place,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // ── Info card ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.secondary(context)
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name + default badges ──
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.fullName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (a.isDefaultShipping || a.isDefaultBilling) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (a.isDefaultShipping)
                              _Badge(
                                icon: Icons.local_shipping_rounded,
                                label: 'Livraison par défaut',
                                color: AppColors.primary(context),
                              ),
                            if (a.isDefaultBilling)
                              _Badge(
                                icon: Icons.receipt_long_rounded,
                                label: 'Facturation par défaut',
                                color: AppColors.neutral(context),
                              ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      Divider(
                        color: AppColors.secondary(context)
                            .withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 16),

                      // ── Address lines ──
                      _infoRow(
                        Icons.location_on_outlined,
                        'Adresse',
                        a.addressLine1,
                      ),
                      if (a.addressLine2 != null && a.addressLine2!.isNotEmpty)
                        _infoRow(null, null, a.addressLine2!),
                      if (a.landmark != null && a.landmark!.isNotEmpty)
                        _infoRow(Icons.place_outlined, 'Repère', a.landmark!),

                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.map_outlined,
                        'Ville',
                        [a.postalCode, a.city].where((e) => e != null && e.isNotEmpty).join(' '),
                      ),
                      if (a.region != null && a.region!.isNotEmpty)
                        _infoRow(Icons.area_chart_outlined, 'Région', a.region!),
                      _infoRow(Icons.flag_outlined, 'Pays', a.country),

                      if (a.phone != null && a.phone!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _infoRow(Icons.phone_outlined, 'Téléphone', a.phone!),
                      ],

                      if (hasCoords) ...[
                        const SizedBox(height: 12),
                        _infoRow(
                          Icons.gps_fixed,
                          'Coordonnées',
                          '${a.latitude!.toStringAsFixed(5)}, ${a.longitude!.toStringAsFixed(5)}',
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Action buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  children: [
                    _ActionCard(
                      icon: Icons.local_shipping_rounded,
                      label: 'Définir comme livraison par défaut',
                      color: AppColors.primary(context),
                      enabled: !a.isDefaultShipping,
                      onTap: () {
                        showProDialog(
                          context,
                          type: DialogType.info,
                          iconColor: AppColors.primary(context),
                          iconBackgroundColor: AppColors.accent20(context),
                          title: 'Adresse par défaut',
                          description:
                              'Définir cette adresse comme adresse de livraison par défaut ?',
                          buttons: [
                            DialogButton(
                              text: 'Annuler',
                              style: DialogButtonStyle.outlined,
                              onPressed: () => Navigator.pop(context),
                            ),
                            DialogButton(
                              text: 'Confirmer',
                              isPrimary: true,
                              icon: Icons.check_rounded,
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await locator<AddressRepo>()
                                    .setDefaultShipping(addressId: a.id!);
                                if (!mounted) return;
                                result.fold(
                                  (failure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(failure.displayMessage),
                                        backgroundColor:
                                            AppColors.logout(context),
                                      ),
                                    );
                                  },
                                  (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Adresse de livraison par défaut mise à jour'),
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      icon: Icons.delete_outline_rounded,
                      label: 'Supprimer cette adresse',
                      color: AppColors.logout(context),
                      onTap: () {
                        showProDialog(
                          context,
                          type: DialogType.error,
                          iconColor: AppColors.logout(context),
                          iconBackgroundColor: AppColors.logoutBg(context),
                          title: 'Supprimer cette adresse',
                          description:
                              'Cette action est irréversible. Voulez-vous vraiment supprimer ?',
                          buttons: [
                            DialogButton(
                              text: 'Annuler',
                              style: DialogButtonStyle.outlined,
                              onPressed: () => Navigator.pop(context),
                            ),
                            DialogButton(
                              text: 'Supprimer',
                              isPrimary: true,
                              icon: Icons.delete_forever_rounded,
                              onPressed: () async {
                                Navigator.pop(context);
                                final result = await locator<AddressRepo>()
                                    .deleteAddress(addressId: a.id!);
                                if (!mounted) return;
                                result.fold(
                                  (failure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(failure.displayMessage),
                                        backgroundColor:
                                            AppColors.logout(context),
                                      ),
                                    );
                                  },
                                  (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Adresse supprimée'),
                                      ),
                                    );
                                    Navigator.pop(context, true);
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData? icon, String? label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.secondary(context)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.secondary(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              height: 200,
              margin: const EdgeInsets.fromLTRB(16, 60, 16, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 48, color: AppColors.secondary(context)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary(context)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAddress,
              child: const Text('Réessayer'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color.withValues(alpha: 0.05) : AppColors.surface(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? color.withValues(alpha: 0.2)
                  : AppColors.secondary(context).withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: enabled
                    ? color
                    : AppColors.secondary(context).withValues(alpha: 0.4),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: enabled
                        ? AppColors.primaryText(context)
                        : AppColors.secondary(context).withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (!enabled)
                Icon(Icons.check_circle,
                    size: 18, color: AppColors.successColor(context))
              else
                Icon(Icons.chevron_right,
                    size: 20,
                    color: enabled
                        ? color
                        : AppColors.secondary(context).withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}
