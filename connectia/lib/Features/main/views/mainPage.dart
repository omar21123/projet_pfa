import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Welcome to Connectia! we doing things differently here',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: GNav(
        tabs: const [
          GButton(icon: Icons.home, text: "Accueil"),
          GButton(icon: Icons.search, text: "Recherche"),
          GButton(icon: Icons.shopping_cart_outlined, text: "Panier"),
          GButton(icon: Icons.person, text: "compte"),
        ],
      ),
    );
  }
}
