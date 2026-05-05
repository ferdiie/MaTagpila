// lib/core/providers/navigation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

// ─────────────────────────────────────────────
//  NAV ITEM MODEL
// ─────────────────────────────────────────────
class NavItem {
  final String id;
  final String label;
  final String iconPath;
  final UserRole? requiredRole; // null = accessible by all

  const NavItem({
    required this.id,
    required this.label,
    required this.iconPath,
    this.requiredRole,
  });
}

// ─────────────────────────────────────────────
//  ALL POSSIBLE NAV ITEMS
// ─────────────────────────────────────────────
const _allNavItems = [
  NavItem(
    id: 'dashboard',
    label: 'Home',
    iconPath: 'home',
    requiredRole: UserRole.admin,
  ),
  NavItem(id: 'pos', label: 'POS', iconPath: 'pos'),
  NavItem(id: 'price_checker', label: 'Prices', iconPath: 'price'),
  NavItem(
    id: 'inventory',
    label: 'Inventory',
    iconPath: 'inventory',
    requiredRole: UserRole.admin,
  ),
  NavItem(
    id: 'profile',
    label: 'Profile',
    iconPath: 'profile',
    requiredRole: UserRole.admin,
  ),
];

// ─────────────────────────────────────────────
//  ROLE-FILTERED NAV ITEMS
// ─────────────────────────────────────────────
List<NavItem> getNavItemsForRole(UserRole role) {
  return _allNavItems.where((item) {
    if (item.requiredRole == null) return true;
    return item.requiredRole == role;
  }).toList();
}

// ─────────────────────────────────────────────
//  NAVIGATION STATE NOTIFIER
// ─────────────────────────────────────────────
class NavigationState {
  final int currentIndex;
  final UserRole role;

  const NavigationState({this.currentIndex = 0, this.role = UserRole.cashier});

  List<NavItem> get navItems => getNavItemsForRole(role);

  String get currentTabId =>
      currentIndex < navItems.length ? navItems[currentIndex].id : 'pos';

  NavigationState copyWith({int? currentIndex, UserRole? role}) =>
      NavigationState(
        currentIndex: currentIndex ?? this.currentIndex,
        role: role ?? this.role,
      );
}

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void setRole(UserRole role) {
    state = state.copyWith(role: role, currentIndex: 0);
  }

  void navigateTo(int index) {
    final items = state.navItems;
    if (index >= 0 && index < items.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void navigateToId(String id) {
    final items = state.navItems;
    final idx = items.indexWhere((item) => item.id == id);
    if (idx != -1) {
      state = state.copyWith(currentIndex: idx);
    }
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
      return NavigationNotifier();
    });
