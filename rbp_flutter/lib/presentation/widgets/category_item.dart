import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/category.dart';
import '../theme/app_icon_button.dart';

class CategoryItem extends StatelessWidget {
  const CategoryItem({
    super.key,
    required this.category,
    required this.onRename,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.mutedSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(child: Text(category.name)),
          AppIconButton(
            onPressed: onRename,
            icon: Icons.edit_outlined,
            color: AppColors.primary,
            hoverColor: AppColors.hoverPrimary,
            tooltip: 'Renombrar',
          ),
          AppIconButton(
            onPressed: onDelete,
            icon: Icons.delete_outline,
            color: AppColors.error,
            hoverColor: AppColors.hoverError,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}
