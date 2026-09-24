// lib/components/app_footer.dart

import 'package:flutter/material.dart';
import 'package:ulima_plus/configs/themes.dart';

class AppFooterItem {
  const AppFooterItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class AppFooter extends StatelessWidget {
  /// Tamaño de la etiqueta activa con seis pestañas, el footer del delegado.
  /// A 14 px «Delegado» no cabe en la sexta parte de un Android de 360 dp ni
  /// del iPhone SE, y a 13 sí (RF-CHAT-5 de la spec del chat). Con cinco o
  /// menos pestañas la activa sigue en 14, el tamaño por omisión.
  static const double activaConSeisPestanas = 13;

  final int currentIndex;
  final List<AppFooterItem> items;
  final Function(int)? onTap;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: const Color(0xFF1E1E24),
      elevation: 12,

      onTap: (index) {
        if (onTap != null) {
          onTap!(index);
        }
      },

      selectedItemColor: MaterialTheme.primaryColor,
      unselectedItemColor: Colors.white.withValues(alpha: 0.68),

      type: BottomNavigationBarType.fixed,
      selectedFontSize: items.length >= 6 ? activaConSeisPestanas : 14,
      unselectedFontSize: 12,

      items: items
          .map(
            (item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
