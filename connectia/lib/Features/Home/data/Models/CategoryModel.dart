class NavbarCategory {
  final int id;
  final int? parentId;
  final String name;
  final String slug;
  final String? iconUrl;
  final int displayOrder;
  final List<NavbarCategory> children;

  const NavbarCategory({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    this.iconUrl,
    required this.displayOrder,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;

  factory NavbarCategory.fromJson(Map<String, dynamic> json) =>
      NavbarCategory(
        id: json['CategoryID'] as int? ?? 0,
        parentId: json['ParentCategoryID'] as int?,
        name: json['Name'] as String? ?? '',
        slug: json['Slug'] as String? ?? '',
        iconUrl: json['IconURL'] as String?,
        displayOrder: json['DisplayOrder'] as int? ?? 0,
        children: (json['children'] as List?)
                ?.map((e) =>
                    NavbarCategory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
