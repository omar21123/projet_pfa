import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Modèle simple pour une question fréquente.
class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

/// Page standard "Centre d'aide" : recherche + FAQ dépliable + contact support.
class HelpCenterPage extends StatefulWidget {
  final List<FaqItem> faqItems;

  const HelpCenterPage({
    super.key,
    this.faqItems = _defaultFaqItems,
  });

  // Contenu par défaut -> remplace-le par tes vraies questions.
  static const List<FaqItem> _defaultFaqItems = [
    FaqItem(
      question: 'Comment passer une commande ?',
      answer:
          'Ajoute les articles souhaités à ton panier, puis suis les étapes '
          'de paiement pour valider ta commande.',
    ),
    FaqItem(
      question: 'Quels sont les modes de paiement acceptés ?',
      answer:
          'Nous acceptons le paiement à la livraison et les cartes bancaires '
          'locales. D\'autres options seront ajoutées prochainement.',
    ),
    FaqItem(
      question: 'Comment suivre ma commande ?',
      answer:
          'Rends-toi dans "Historique des achats" pour voir le statut de '
          'chacune de tes commandes en temps réel.',
    ),
    FaqItem(
      question: 'Comment modifier ou annuler une commande ?',
      answer:
          'Contacte notre support via cette page avant l\'expédition de ta '
          'commande, nous ferons le nécessaire.',
    ),
    FaqItem(
      question: 'Comment contacter le vendeur ?',
      answer:
          'Depuis la page du produit ou de la commande, appuie sur '
          '"Contacter le vendeur" pour lui envoyer un message direct.',
    ),
  ];

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> get _filteredItems {
    if (_query.trim().isEmpty) return widget.faqItems;
    final q = _query.toLowerCase();
    return widget.faqItems
        .where((item) =>
            item.question.toLowerCase().contains(q) ||
            item.answer.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        title: Text(
          "Centre d'aide",
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSearchBar(context)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Questions fréquentes',
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (_filteredItems.isEmpty)
            SliverToBoxAdapter(child: _buildEmptyState(context))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FaqTile(item: _filteredItems[index]),
                  ),
                  childCount: _filteredItems.length,
                ),
              ),
            ),
          SliverToBoxAdapter(child: _buildSupportSection(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          style: TextStyle(color: AppColors.primaryText(context)),
          decoration: InputDecoration(
            hintText: 'Rechercher une question...',
            hintStyle: TextStyle(color: AppColors.secondary(context)),
            prefixIcon: Icon(Icons.search, color: AppColors.secondary(context)),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close, color: AppColors.secondary(context)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.search_off, color: AppColors.secondary(context), size: 40),
          const SizedBox(height: 12),
          Text(
            'Aucun résultat pour "$_query"',
            style: TextStyle(color: AppColors.secondary(context), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Besoin d'aide supplémentaire ?",
              style: TextStyle(
                color: AppColors.onPrimary(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Notre équipe support est là pour toi.',
              style: TextStyle(
                color: AppColors.onPrimary(context).withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _SupportContactRow(
              icon: Icons.email_outlined,
              label: 'Nous écrire par e-mail',
              onTap: widget.onEmailTap,
            ),
            _SupportContactRow(
              icon: Icons.chat_bubble_outline,
              label: 'Discuter sur WhatsApp',
              onTap: widget.onWhatsAppTap,
            ),
            _SupportContactRow(
              icon: Icons.call_outlined,
              label: 'Nous appeler',
              onTap: widget.onPhoneTap,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

extension on HelpCenterPage {
  void onEmailTap() {}
  
  void onWhatsAppTap() {}
  
  void onPhoneTap() {}
}

class _FaqTile extends StatefulWidget {
  final FaqItem item;

  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (value) => setState(() => _expanded = value),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppColors.primary(context),
          collapsedIconColor: AppColors.secondary(context),
          title: Text(
            widget.item.question,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 14,
              fontWeight: _expanded ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.item.answer,
                style: TextStyle(
                  color: AppColors.secondary(context),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLast;

  const _SupportContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.onPrimary(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6), size: 18),
          ],
        ),
      ),
    );
  }
}