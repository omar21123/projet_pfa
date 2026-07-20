import 'dart:io';
import 'package:connectia/Core/Constants/AppColors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // flutter pub add image_picker

/// Avatar circulaire avec bouton crayon pour changer/supprimer la photo.
///
/// - `imagePath` : URL réseau (http/https) ou chemin local (fichier déjà
///   uploadé). Si null/vide -> avatar par défaut avec initiales.
/// - `onImageChanged` : déclenché avec le nouveau `File` choisi, ou `null`
///   si l'utilisateur supprime la photo.
class EditableAvatar extends StatefulWidget {
  final String? imagePath;
  final String fullName;
  final double size;
  final void Function(File? newImage) onImageChanged;

  const EditableAvatar({
    super.key,
    required this.imagePath,
    required this.fullName,
    required this.onImageChanged,
    this.size = 120,
  });

  @override
  State<EditableAvatar> createState() => _EditableAvatarState();
}

class _EditableAvatarState extends State<EditableAvatar> {
  final ImagePicker _picker = ImagePicker();

  // Aperçu local immédiat après sélection, en attendant que le parent
  // repasse un nouveau `imagePath` (ex: après upload serveur).
  File? _pendingImage;

  String get _initials {
    final parts = widget.fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  bool get _hasRemoteImage =>
      widget.imagePath != null && widget.imagePath!.trim().isNotEmpty;

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // ferme la bottom sheet
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() => _pendingImage = file);
    widget.onImageChanged(file);
  }

  void _deleteImage() {
    Navigator.pop(context); // ferme la bottom sheet
    setState(() => _pendingImage = null);
    widget.onImageChanged(null);
  }

  void _openOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.secondary(context).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            _OptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Choisir depuis la galerie',
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            _OptionTile(
              icon: Icons.camera_alt_outlined,
              label: 'Prendre une photo',
              onTap: () => _pickImage(ImageSource.camera),
            ),
            if (_pendingImage != null || _hasRemoteImage)
              _OptionTile(
                icon: Icons.delete_outline,
                label: 'Supprimer la photo',
                isDestructive: true,
                onTap: _deleteImage,
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: _buildImage(context),
                ),
              ),
            ),
            Positioned(
              bottom: -2,
              right: -2,
              child: GestureDetector(
                onTap: _openOptions,
                child: Container(
                  width: widget.size * 0.32,
                  height: widget.size * 0.32,
                  decoration: BoxDecoration(
                    color: AppColors.primary(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background(context),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    color: AppColors.onPrimary(context),
                    size: widget.size * 0.16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (_pendingImage != null) {
      return Image.file(_pendingImage!, fit: BoxFit.cover);
    }
    if (_hasRemoteImage) {
      final path = widget.imagePath!;
      final isNetwork =
          path.startsWith('http://') || path.startsWith('https://');
      return isNetwork
          ? Image.network(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildInitials(context),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : _buildInitials(context, loading: true),
            )
          : Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildInitials(context),
            );
    }
    return _buildInitials(context);
  }

  Widget _buildInitials(BuildContext context, {bool loading = false}) {
    return Container(
      color: AppColors.accent20(context),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(
              width: widget.size * 0.2,
              height: widget.size * 0.2,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary(context),
              ),
            )
          : Text(
              _initials,
              style: TextStyle(
                color: AppColors.primary(context),
                fontSize: widget.size * 0.32,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppColors.wishlist(context)
        : AppColors.primaryText(context);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}