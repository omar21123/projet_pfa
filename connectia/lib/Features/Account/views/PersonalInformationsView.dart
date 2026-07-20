import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:connectia/Features/Account/Widgets/Personal%20Information/EditableAvatar.dart';
import 'package:flutter/material.dart';

class PersonalinformationsView extends StatelessWidget {
  const PersonalinformationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBg(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryText(context)),
        title: Text(
          "Informations personnelles",
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: EditableAvatar(
                imagePath:
                    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNIt52qUljGdJXFymRUK_ZPTSKAyeB1SJzA3N1ORpIwg&s=10',
                fullName: 'Mohammed Bourass',
                onImageChanged: (file) {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
