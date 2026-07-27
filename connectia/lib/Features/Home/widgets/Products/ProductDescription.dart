import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bloc "Description" avec titre en majuscules + texte multi-lignes,
/// option "voir plus / voir moins" si le texte dépasse [collapsedMaxLines].
class ProductDescription extends StatefulWidget {
  final String description;
  final int collapsedMaxLines;

  const ProductDescription({
    super.key,
    required this.description,
    this.collapsedMaxLines = 4,
  });

  @override
  State<ProductDescription> createState() => _ProductDescriptionState();
}

class _ProductDescriptionState extends State<ProductDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.plusJakartaSans(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      color: AppColors.secondary(context),
      height: 1.6,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIPTION',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: AppColors.primaryText(context),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: Text(
            widget.description,
            style: textStyle,
            maxLines: _expanded ? null : widget.collapsedMaxLines,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final span = TextSpan(text: widget.description, style: textStyle);
            final painter = TextPainter(
              text: span,
              maxLines: widget.collapsedMaxLines,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);

            final isOverflowing = painter.didExceedMaxLines;
            if (!isOverflowing) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Voir moins' : 'Voir plus',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary(context),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}