import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Core/DI/locator.dart';
import 'package:connectia/Features/Account/data/AddressesCubit.dart';
import 'package:connectia/Features/Account/data/Models/AddressModel.dart';
import 'package:connectia/Features/Cart/data/Cubits/CartCubit.dart';
import 'package:connectia/Features/Cart/data/OrderRepo.dart';
import 'package:connectia/Features/Cart/data/PaymentService.dart';
import 'package:connectia/Features/Home/data/Models/ProductConfig.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 0;
  AddressModel? _selectedAddress;
  PaymentMethod? _selectedPayment;
  bool _isPlacingOrder = false;

  // ── Notes ──
  final _notesController = TextEditingController();

  // ── Mock card fields ──
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _cardFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    context.read<AddressesCubit>().fetchAddresses();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _selectedAddress != null;
      case 1:
        return _selectedPayment != null;
      case 2:
        return true; // notes are optional
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 3 && _canProceed) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.softBg(context),
        appBar: AppBar(
          backgroundColor: AppColors.surface(context),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Passer la commande',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // ── Step indicator ──
            _buildStepIndicator(),
            const Divider(height: 1),
            // ── Step content ──
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _buildAddressStep(),
                  _buildPaymentStep(),
                  _buildNotesStep(),
                  _buildConfirmationStep(),
                ],
              ),
            ),
            // ── Bottom action bar ──
            _buildBottomBar(),
          ],
        ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Step indicator
  // ─────────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    final labels = ['Adresse', 'Paiement', 'Notes', 'Confirmation'];
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentStep;
          final isCurrent = i == _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= _currentStep
                          ? AppColors.primary(context)
                          : AppColors.secondary(context).withValues(alpha: 0.3),
                    ),
                  ),
                if (i == 0) const SizedBox(width: 4),
                CircleAvatar(
                  radius: 13,
                  backgroundColor: isActive
                      ? AppColors.primary(context)
                      : AppColors.softBg(context),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.onPrimary(context)
                          : AppColors.secondary(context),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.primary(context)
                          : AppColors.secondary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (i < 3) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Step 1: Address selection
  // ─────────────────────────────────────────────────────────────
  Widget _buildAddressStep() {
    return BlocBuilder<AddressesCubit, AddressesState>(
      builder: (context, state) {
        if (state is AddressesLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AddressesError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.secondary(context)),
                const SizedBox(height: 12),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AddressesCubit>().fetchAddresses(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        final addresses = state is AddressesLoaded ? state.addresses : <AddressModel>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Adresse de livraison',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText(context),
                ),
              ),
            ),
            if (addresses.isEmpty)
              _buildEmptyAddress()
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final addr = addresses[index];
                    final isSelected = _selectedAddress?.id == addr.id;
                    return _buildAddressTile(addr, isSelected);
                  },
                ),
              ),
            const SizedBox(height: 10),
            // Add new address button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.push('/AddAddressPage');
                  if (mounted) {
                    context.read<AddressesCubit>().fetchAddresses();
                  }
                },
                icon: Icon(Icons.add_location_alt_outlined,
                    color: AppColors.primary(context), size: 20),
                label: Text(
                  'Ajouter une nouvelle adresse',
                  style: TextStyle(
                    color: AppColors.primary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary(context).withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildEmptyAddress() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off_outlined,
                size: 56, color: AppColors.secondary(context).withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Aucune adresse enregistrée',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ajoutez une adresse pour continuer',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.secondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile(AddressModel addr, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedAddress = addr),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary(context).withValues(alpha: 0.06)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary(context)
                : AppColors.secondary(context).withValues(alpha: 0.2),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio circle
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary(context)
                    : Colors.transparent,
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.secondary(context).withValues(alpha: 0.4),
                        width: 1.5,
                      ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // Address info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          addr.fullName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText(context),
                          ),
                        ),
                      ),
                      if (addr.isDefaultShipping)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.successColorBg(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Défaut',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.successColor(context),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${addr.addressLine1}${(addr.addressLine2 != null && addr.addressLine2!.isNotEmpty) ? ', ${addr.addressLine2}' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary(context),
                    ),
                  ),
                  if (addr.landmark != null && addr.landmark!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      addr.landmark!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary(context).withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${addr.city}, ${addr.region} ${addr.postalCode}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (addr.phone != null && addr.phone!.isNotEmpty)
                    Text(
                      addr.phone!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary(context).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Step 2: Payment method
  // ─────────────────────────────────────────────────────────────
  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mode de paiement',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choisissez comment vous souhaitez payer',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondary(context),
            ),
          ),
          const SizedBox(height: 20),

          // COD tile
          _buildPaymentOption(
            method: PaymentMethod.cod,
            icon: Icons.payments_outlined,
            title: 'Paiement à la livraison',
            subtitle: 'Payez en espèces dès réception',
          ),
          const SizedBox(height: 12),

          // Online tile
          _buildPaymentOption(
            method: PaymentMethod.online,
            icon: Icons.credit_card,
            title: 'Paiement en ligne',
            subtitle: 'Payez maintenant par carte bancaire',
          ),

          // ── COD explanation ──
          if (_selectedPayment == PaymentMethod.cod) ...[
            const SizedBox(height: 20),
            _buildCodInfo(),
          ],

          // ── Online card form ──
          if (_selectedPayment == PaymentMethod.online) ...[
            const SizedBox(height: 24),
            _buildOnlineCardForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedPayment == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary(context).withValues(alpha: 0.06)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary(context)
                : AppColors.secondary(context).withValues(alpha: 0.2),
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary(context)
                    : AppColors.softBg(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.onPrimary(context)
                    : AppColors.secondary(context),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.primaryText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.secondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.primary(context)
                    : AppColors.surfaceAlt(context),
                border: isSelected
                    ? null
                    : Border.all(
                        color: AppColors.secondary(context).withValues(alpha: 0.4),
                      ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.loyaltyCardBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.loyaltyBorderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: AppColors.loyaltyTextColor(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement à la livraison',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.loyaltyTextColor(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Vous paierez le montant total directement au livreur lors de la réception de votre commande. '
                  'Si plusieurs livreurs interviennent, chaque livreur vous demandera le montant correspondant à sa partie. '
                  'Vous pouvez consulter la ventilation dans l\'historique des commandes.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.secondary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineCardForm() {
    return Form(
      key: _cardFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de carte',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 14),
          // Card holder
          _buildTextField(
            controller: _cardHolderController,
            label: 'Nom sur la carte',
            icon: Icons.person_outline,
            hint: 'Jean Dupont',
          ),
          const SizedBox(height: 12),
          // Card number
          _buildTextField(
            controller: _cardNumberController,
            label: 'Numéro de carte',
            icon: Icons.credit_card,
            hint: '4242 4242 4242 4242',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          // Expiry + CVV row
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _cardExpiryController,
                  label: 'Expiration',
                  icon: Icons.calendar_today,
                  hint: 'MM/AA',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _cardCvvController,
                  label: 'CVV',
                  icon: Icons.lock_outline,
                  hint: '123',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successColorBg(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.lock, size: 16, color: AppColors.successColor(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paiement sécurisé. Vos données bancaires ne sont pas stockées.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.successColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.primaryText(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.secondary(context)),
        labelStyle: TextStyle(color: AppColors.secondary(context)),
        hintStyle: TextStyle(
          color: AppColors.secondary(context).withValues(alpha: 0.5),
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.softBg(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.secondary(context).withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.secondary(context).withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary(context),
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Step 3: Notes (optional)
  // ─────────────────────────────────────────────────────────────
  Widget _buildNotesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions de livraison',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajoutez des notes pour le livreur (optionnel)',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.secondary(context),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _notesController,
            maxLines: 5,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primaryText(context),
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Livrer avant 18h, sonner au 3e étage, laisser devant la porte...',
              hintStyle: TextStyle(
                color: AppColors.secondary(context).withValues(alpha: 0.5),
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surface(context),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.secondary(context).withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.secondary(context).withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.primary(context),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.loyaltyCardBackground(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: AppColors.loyaltyTextColor(context)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ces notes sont optionnelles et seront transmises au livreur pour faciliter la livraison.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Step 4: Confirmation
  // ─────────────────────────────────────────────────────────────
  Widget _buildConfirmationStep() {
    final cartState = context.watch<CartCubit>().state;
    final subtotal = cartState is CartLoaded ? cartState.subtotal : 0.0;
    final savedAmount = cartState is CartLoaded ? cartState.totalSaved : 0.0;
    final itemCount = cartState is CartLoaded ? cartState.items.length : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText(context),
            ),
          ),
          const SizedBox(height: 20),

          // ── Address summary ──
          if (_selectedAddress != null) ...[
            _buildSummarySection(
              title: 'Adresse de livraison',
              icon: Icons.location_on_outlined,
              child: _buildAddressSummary(_selectedAddress!),
            ),
            const SizedBox(height: 16),
          ],

          // ── Payment summary ──
          if (_selectedPayment != null) ...[
            _buildSummarySection(
              title: 'Paiement',
              icon: Icons.payment_outlined,
              child: _buildPaymentSummary(_selectedPayment!),
            ),
            const SizedBox(height: 16),
          ],

          // ── Notes summary ──
          if (_notesController.text.isNotEmpty) ...[
            _buildSummarySection(
              title: 'Notes de livraison',
              icon: Icons.note_alt_outlined,
              child: Text(
                _notesController.text,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary(context),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Order breakdown ──
          _buildSummarySection(
            title: 'Détails de la commande',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                _buildSummaryRow('Articles', '$itemCount'),
                _buildSummaryRow('Sous-total', '${subtotal.toStringAsFixed(2)} MAD'),
                if (savedAmount > 0)
                  _buildSummaryRow(
                    'Économies',
                    '-${savedAmount.toStringAsFixed(2)} MAD',
                    valueColor: AppColors.successColor(context),
                  ),
                const Divider(height: 20),
                _buildSummaryRow(
                  'Total',
                  '${subtotal.toStringAsFixed(2)} MAD',
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary(context)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAddressSummary(AddressModel addr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          addr.fullName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${addr.addressLine1}, ${addr.city}${addr.region != null ? ', ${addr.region}' : ''}',
          style: TextStyle(fontSize: 13, color: AppColors.secondary(context)),
        ),
        if (addr.phone != null && addr.phone!.isNotEmpty)
          Text(
            addr.phone!,
            style: TextStyle(fontSize: 12, color: AppColors.secondary(context).withValues(alpha: 0.7)),
          ),
      ],
    );
  }

  Widget _buildPaymentSummary(PaymentMethod method) {
    final label = method == PaymentMethod.cod
        ? 'Paiement à la livraison (COD)'
        : 'Paiement en ligne (Carte)';
    final icon = method == PaymentMethod.cod
        ? Icons.payments_outlined
        : Icons.credit_card;
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary(context)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.primaryText(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppColors.primaryText(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  Bottom bar
  // ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.secondary(context).withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Retour',
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_canProceed && !_isPlacingOrder)
                    ? () {
                        if (_currentStep < 3) {
                          _nextStep();
                        } else {
                          _placeOrder();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: AppColors.onPrimary(context),
                  disabledBackgroundColor: AppColors.secondary(context).withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isPlacingOrder
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep < 3 ? 'Continuer' : 'Confirmer la commande',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null || _selectedPayment == null) return;

    setState(() => _isPlacingOrder = true);

    // 1. Process online payment (placeholder)
    if (_selectedPayment == PaymentMethod.online) {
      final cardState = _cardFormKey.currentState;
      if (cardState != null && !cardState.validate()) {
        setState(() => _isPlacingOrder = false);
        return;
      }

      final paymentResult = await locator<PaymentService>().processOnlinePayment(
        amount: context.read<CartCubit>().state is CartLoaded
            ? (context.read<CartCubit>().state as CartLoaded).subtotal
            : 0,
        currency: 'MAD',
        cardNumber: _cardNumberController.text,
        expiry: _cardExpiryController.text,
        cvv: _cardCvvController.text,
        holderName: _cardHolderController.text,
      );

      if (!mounted) return;

      final paymentFailed = paymentResult.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.displayMessage),
              backgroundColor: AppColors.logout(context),
            ),
          );
          return true;
        },
        (_) => false,
      );

      if (paymentFailed) {
        setState(() => _isPlacingOrder = false);
        return;
      }
    }

    // 2. Place the order
    final request = PlaceOrderRequest(
      addressId: _selectedAddress!.id!,
      paymentMethodId: _selectedPayment == PaymentMethod.cod ? 1 : 2,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final result = await locator<OrderRepo>().placeOrderFromCart(request: request);

    if (!mounted) return;

    setState(() => _isPlacingOrder = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.displayMessage),
            backgroundColor: AppColors.logout(context),
          ),
        );
      },
      (_) {
        _showOrderSuccessDialog();
      },
    );
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.successColorBg(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.successColor(context),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Commande confirmée !',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.primaryText(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Nous traitons votre commande et trouvons le meilleur livreur pour vous. '
              'Vous recevrez une notification dès que votre commande sera en cours de livraison.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.secondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: AppColors.onPrimary(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Retour à l\'accueil',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
