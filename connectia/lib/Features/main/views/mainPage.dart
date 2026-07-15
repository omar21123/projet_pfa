import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/views/AccountView.dart';
import 'package:connectia/Features/Cart/Views/CartView.dart';
import 'package:connectia/Features/Home/Views/HomeView.dart';
import 'package:connectia/Features/Search/Views/SearchView.dart';
import 'package:flutter/material.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  final _pageController = PageController();
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Homeview(),
    Searchview(),
    Cartview(),
    Accountview(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChange(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabChange: _onTabChange,
        items: const [
          NavBarItem(icon: Icons.home_rounded, label: 'Accueil'),
          NavBarItem(icon: Icons.search_rounded, label: 'Recherche'),
          NavBarItem(icon: Icons.shopping_cart_outlined, label: 'Panier'),
          NavBarItem(icon: Icons.person_rounded, label: 'Compte'),
        ],
      ),
    );
  }
}

class NavBarItem {
  const NavBarItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTabChange,
  });

  final List<NavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTabChange;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 360;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: 10,
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final bool isSelected = index == selectedIndex;
              return _NavBarTab(
                item: items[index],
                isSelected: isSelected,
                isSmallScreen: isSmallScreen,
                onTap: () => onTabChange(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarTab extends StatelessWidget {
  const _NavBarTab({
    required this.item,
    required this.isSelected,
    required this.isSmallScreen,
    required this.onTap,
  });

  final NavBarItem item;
  final bool isSelected;
  final bool isSmallScreen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? (isSmallScreen ? 14 : 18) : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: isSmallScreen ? 20 : 22,
              color: isSelected
                  ? AppColors.onPrimary(context)
                  : AppColors.secondary(context),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary(context),
                        ),
                      ),
                    )
                  : const SizedBox(width: 0, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}
