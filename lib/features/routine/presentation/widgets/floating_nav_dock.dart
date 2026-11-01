import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FloatingNavDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onAddPressed;
  final AppPaletteData palette;

  const FloatingNavDock({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onAddPressed,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      height: 64,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: palette.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              // Tab 0: Home
              Expanded(
                child: _buildNavItem(
                  index: 0,
                  label: 'Home',
                  icon: Icons.home_rounded,
                ),
              ),
              // Tab 1: Rotinas
              Expanded(
                child: _buildNavItem(
                  index: 1,
                  label: 'Rotinas',
                  icon: Icons.alarm_rounded,
                ),
              ),

              // Espaço central reservado para o FAB elevado
              const SizedBox(width: 56),

              // Tab 2: Timer
              Expanded(
                child: _buildNavItem(
                  index: 2,
                  label: 'Timer',
                  icon: Icons.timer_rounded,
                ),
              ),
              // Tab 3: Sono
              Expanded(
                child: _buildNavItem(
                  index: 3,
                  label: 'Sono',
                  icon: Icons.nightlight_round,
                ),
              ),
            ],
          ),

          // Botão Central Flutuante (+)
          Positioned(
            top: -10,
            child: GestureDetector(
              onTap: onAddPressed,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: palette.onPrimary,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? palette.primary : palette.textMuted;

    return InkWell(
      onTap: () => onIndexChanged(index),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: palette.primary,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}
