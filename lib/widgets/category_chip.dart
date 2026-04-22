import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/device.dart';

class CategoryChipRow extends StatelessWidget {
  final String? selectedCategory;
  final void Function(String?) onSelected;

  const CategoryChipRow({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          _chip(context, null, 'Alle', Icons.apps),
          ...kCategories.map((cat) => _chip(
                context,
                cat,
                kCategoryLabels[cat]!,
                kCategoryIcons[cat]!,
              )),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, String? value, String label, IconData icon) {
    final selected = selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(value),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.bgGrey,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        avatarBorder: const CircleBorder(),
        iconTheme: IconThemeData(
          color: selected ? Colors.white : AppColors.textMedium,
          size: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.circle),
          side: BorderSide(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
      ),
    );
  }
}
