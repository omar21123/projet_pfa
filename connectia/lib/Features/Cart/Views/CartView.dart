import 'package:connectia/Features/Cart/Widgets/CartItemWidget.dart';
import 'package:flutter/material.dart';

class Cartview extends StatelessWidget {
  const Cartview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Cartitemwidget();
        },
      ),
    );
  }
}
