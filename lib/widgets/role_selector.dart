import 'package:flutter/material.dart';

import '../models/app_models.dart';

class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
  });

  final AppRole selectedRole;
  final ValueChanged<AppRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppRole.values.map((role) {
        return ChoiceChip(
          label: Text(role.label),
          selected: selectedRole == role,
          onSelected: (_) => onChanged(role),
        );
      }).toList(),
    );
  }
}
