import 'dart:async';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';

/// Barre de recherche "factice" : non éditable, cliquable uniquement.
/// Au tap -> navigation vers la page de suggestions de recherche.
/// Le placeholder anime en boucle (effet machine à écrire) à travers
/// une liste de suggestions ("Rechercher des produits", "... des marques", etc.)
class SearchEntryButton extends StatefulWidget {
  final VoidCallback onTap;
  final List<String> suggestions;

  const SearchEntryButton({
    super.key,
    required this.onTap,
    this.suggestions = const [
      'Rechercher des produits',
      'Rechercher des marques',
      'Rechercher des catégories',
      'Recherchez selon vos envies',
    ],
  });

  @override
  State<SearchEntryButton> createState() => _SearchEntryButtonState();
}

class _SearchEntryButtonState extends State<SearchEntryButton> {
  Timer? _timer;
  int _wordIndex = 0;
  int _charCount = 0;
  bool _deleting = false;

  static const _typeSpeed = Duration(milliseconds: 55);
  static const _deleteSpeed = Duration(milliseconds: 30);
  static const _holdFull = Duration(milliseconds: 1400);
  static const _holdEmpty = Duration(milliseconds: 300);

  String get _currentWord => widget.suggestions[_wordIndex];
  String get _displayedText => _currentWord.substring(0, _charCount);

  @override
  void initState() {
    super.initState();
    _scheduleNext(_typeSpeed);
  }

  void _scheduleNext(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _tick);
  }

  void _tick() {
    if (!mounted) return;

    setState(() {
      if (!_deleting) {
        // Typing forward
        if (_charCount < _currentWord.length) {
          _charCount++;
          _scheduleNext(_typeSpeed);
        } else {
          // Fully typed -> pause, then start deleting
          _deleting = true;
          _scheduleNext(_holdFull);
        }
      } else {
        // Deleting
        if (_charCount > 0) {
          _charCount--;
          _scheduleNext(_deleteSpeed);
        } else {
          // Fully deleted -> move to next word, pause, then type
          _deleting = false;
          _wordIndex = (_wordIndex + 1) % widget.suggestions.length;
          _scheduleNext(_holdEmpty);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.secondary(context).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 22,
                color: AppColors.secondary(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _displayedText,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.secondary(context),
                      ),
                    ),
                    // Curseur clignotant simple (statique ici, pas d'anim
                    // séparée pour rester léger ; purement décoratif)
                    Container(
                      width: 1.5,
                      height: 16,
                      color: AppColors.secondary(context).withValues(alpha: 0.5),
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