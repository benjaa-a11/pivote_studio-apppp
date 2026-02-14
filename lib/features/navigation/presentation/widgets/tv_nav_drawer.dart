import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TVNavDrawer extends StatefulWidget {
  final Function(int) onDestinationSelected;
  final int selectedIndex;
  final bool isExpanded;
  final Function(bool) onFocusChange;

  const TVNavDrawer({
    super.key,
    required this.onDestinationSelected,
    required this.selectedIndex,
    required this.isExpanded,
    required this.onFocusChange,
  });

  @override
  State<TVNavDrawer> createState() => _TVNavDrawerState();
}

class _TVNavDrawerState extends State<TVNavDrawer> {
  final FocusNode _drawerFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _drawerFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _drawerFocusNode.removeListener(_handleFocusChange);
    _drawerFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    // Only expand if one of the children has focus
    // This logic might need to be handled by the children focus nodes instead
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = widget.isExpanded ? 240.0 : 80.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: widget.isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                )
              ]
            : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 40), // Top padding / Logo area
          // Logo placeholder
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: widget.isExpanded ? 1.0 : 0.0,
            child: widget.isExpanded
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20),
                    child: Text("PIVOTE",
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold, letterSpacing: 2)),
                  )
                : const SizedBox.shrink(),
          ),

          Expanded(
            child: ListView(
              padding:
                  EdgeInsets.symmetric(horizontal: widget.isExpanded ? 16 : 12),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildNavItem(
                  index: 1,
                  icon: Icons.sports_soccer_rounded,
                  label: 'Fútbol',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildNavItem(
                  index: 2,
                  icon: Icons.favorite_rounded,
                  label: 'Favoritos',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildNavItem(
                  index: 3,
                  icon: FontAwesomeIcons.radio,
                  label: 'Radio',
                  theme: theme,
                  isFaIcon: true,
                ),
                const SizedBox(height: 12),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  theme: theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required ThemeData theme,
    bool isFaIcon = false,
  }) {
    final isSelected = widget.selectedIndex == index;

    return _TVNavItem(
      icon: icon,
      label: label,
      isSelected: isSelected,
      isExpanded: widget.isExpanded,
      isFaIcon: isFaIcon,
      onTap: () => widget.onDestinationSelected(index),
      onFocusChange: (focused) {
        widget.onFocusChange(focused);
      },
      onExitFocus: () {
        // Logic to potentially collapse if focus leaves the drawer entirely
      },
    );
  }
}

class _TVNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final bool isFaIcon;
  final VoidCallback onTap;
  final Function(bool) onFocusChange;
  final VoidCallback onExitFocus;

  const _TVNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    required this.onFocusChange,
    required this.onExitFocus,
    this.isFaIcon = false,
  });

  @override
  State<_TVNavItem> createState() => _TVNavItemState();
}

class _TVNavItemState extends State<_TVNavItem> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    widget.onFocusChange(_focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor =
        theme.iconTheme.color?.withValues(alpha: 0.7) ?? Colors.grey;
    final color = _isFocused || widget.isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: widget.onTap,
      focusNode: _focusNode,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: _isFocused
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: _isFocused
              ? Border.all(
                  color: activeColor.withValues(alpha: 0.5), width: 1.5)
              : Border.all(color: Colors.transparent, width: 1.5),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: widget.isExpanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedScale(
              scale: _isFocused ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: widget.isFaIcon
                  ? FaIcon(widget.icon, size: 22, color: color)
                  : Icon(widget.icon, size: 26, color: color),
            ),

            // Label
            if (widget.isExpanded) ...[
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  widget.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: _isFocused || widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
