import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tollgate_app/presentation/features/tollgate/map/map_screen.dart';
import 'package:tollgate_app/presentation/features/tollgate/payment/payment_screen.dart';
import 'package:tollgate_app/presentation/features/settings/settings_screen.dart';

import '../features/wallet/send/send_screen.dart';
import '../features/wallet/receive/receive_screen.dart';
import '../features/wallet/reserve/reserve_screen.dart';
import '../features/wifi/connection_details/connection_screen.dart';
import '../features/home/home_screen.dart';
import '../features/wifi/network_scan/scan_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../features/wallet/mint/mint_screen.dart';
import '../common/layout/navigation_shell.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final homeNavigatorKey = GlobalKey<NavigatorState>();
final walletNavigatorKey = GlobalKey<NavigatorState>();
final settingsNavigatorKey = GlobalKey<NavigatorState>();
final mapNavigatorKey = GlobalKey<NavigatorState>();

/// Top go_router entry point.
GoRouter router() => GoRouter(
      initialLocation: '/',
      navigatorKey: rootNavigatorKey,
      debugLogDiagnostics: true,
      routes: [
        StatefulShellRoute.indexedStack(
          pageBuilder: (context, state, shell) => CustomTransitionPage(
            key: state.pageKey,
            child: NavigationShell(navigationShell: shell),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
          branches: [
            StatefulShellBranch(
              navigatorKey: homeNavigatorKey,
              routes: [
                GoRoute(
                  path: Routes.home,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const HomeScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            _buildFadeInTransition(animation, child),
                  ),
                  routes: [
                    GoRoute(
                      path: 'connection',
                      pageBuilder: (context, state) => CustomTransitionPage(
                        child: const ConnectionScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                _buildSlideLeftTransition(animation, child),
                      ),
                    ),
                    GoRoute(
                      path: 'scan',
                      pageBuilder: (context, state) => CustomTransitionPage(
                        child: const ScanScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                _buildSlideLeftTransition(animation, child),
                      ),
                    ),
                    GoRoute(
                      path: 'payment',
                      pageBuilder: (context, state) {
                        final Map<String, dynamic>? networkData =
                            state.extra as Map<String, dynamic>?;

                        return CustomTransitionPage(
                          child: PaymentScreen(networkData: networkData),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) =>
                                  _buildSlideLeftTransition(animation, child),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: mapNavigatorKey,
              routes: [
                GoRoute(
                  path: Routes.map,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const MapScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            _buildFadeInTransition(animation, child),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: walletNavigatorKey,
              routes: [
                GoRoute(
                  path: Routes.wallet,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const WalletScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            _buildFadeInTransition(
                      animation,
                      child,
                    ),
                  ),
                  routes: [
                    GoRoute(
                      path: 'mint',
                      pageBuilder: (context, state) => CustomTransitionPage(
                        child: const MintScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                _buildSlideLeftTransition(animation, child),
                      ),
                    ),
                    GoRoute(
                      path: 'send',
                      pageBuilder: (context, state) => CustomTransitionPage(
                        child: const SendScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                _buildSlideLeftTransition(animation, child),
                      ),
                    ),
                    GoRoute(
                      path: 'receive',
                      pageBuilder: (context, state) => CustomTransitionPage(
                        child: const ReceiveScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                _buildSlideLeftTransition(animation, child),
                      ),
                    ),
                    GoRoute(
                      path: 'reserve',
                      pageBuilder: (context, state) => CustomTransitionPage(
                        child: const ReserveScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) =>
                                _buildSlideLeftTransition(animation, child),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              navigatorKey: settingsNavigatorKey,
              routes: [
                GoRoute(
                  path: Routes.settings,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    child: const SettingsScreen(),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) =>
                        _buildFadeInTransition(
                      animation,
                      child,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );

SlideTransition _buildSlideLeftTransition(
    Animation<double> animation, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
}

FadeTransition _buildFadeInTransition(
    Animation<double> animation, Widget child) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
    child: child,
  );
}
