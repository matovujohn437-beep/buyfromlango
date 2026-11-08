import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/sign_up_screen.dart';
import 'screens/auth/profile_setup_screen.dart'; // <-- Added this
import 'screens/admin/reports_screen.dart';
import 'screens/buyer_needs/buyer_needs_screen.dart';
import 'screens/buyer_needs/create_buyer_need_screen.dart';
import 'screens/category/category_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/chat/threads_screen.dart';
import 'screens/home/home_screen.dart';
import 'models/listing.dart';
import 'models/listing_detail_route_data.dart';
import 'screens/listing/create_listing_screen.dart';
import 'screens/listing/edit_listing_screen.dart';
import 'screens/listing/listing_detail_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/order/orders_screen.dart';
import 'screens/price_board/price_board_screen.dart';
import 'screens/preload_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/public_profile_screen.dart';
import 'screens/profile/seller_catalog_screen.dart';
import 'screens/splash_screen.dart';
import 'supabase_config.dart';

class AppRouter {
  AppRouter._();

  static final _authRefreshListenable = _AuthRefreshListenable();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authRefreshListenable,
    redirect: (context, state) async {
      final isSignedIn = SupabaseConfig.client.auth.currentSession != null;
      final location = state.matchedLocation;

      if (isSignedIn &&
          location != '/' &&
          location != '/splash' &&
          location != '/onboarding' &&
          location != '/profile-setup') {
        final userId = SupabaseConfig.client.auth.currentUser!.id;
        final profile = await SupabaseConfig.client
            .from('profiles')
            .select('district_id, phone')
            .eq('id', userId)
            .maybeSingle();
        if (profile == null ||
            profile['district_id'] == null ||
            (profile['phone'] as String?)?.isEmpty != false) {
          return '/profile-setup';
        }
      }

      // 1. If user is signed in and tries to access auth screens/splash, send to home
      if (isSignedIn &&
          (location == '/sign-in' ||
              location == '/sign-up' ||
              location == '/auth')) {
        return '/home';
      }

      // 2. If user is NOT signed in, protect all private routes
      if (!isSignedIn &&
          (location == '/profile' ||
              location == '/chats' ||
              location == '/orders' ||
              location.startsWith('/chat/') ||
              (location.startsWith('/listing/') &&
                  location.endsWith('/edit')) ||
              location == '/listing/new' ||
              location == '/buyer-needs/new' ||
              location == '/profile-setup')) {
        // Protect setup
        return '/sign-in';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PreloadScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        redirect: (context, state) => '/sign-in',
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      // Added the Profile Setup Route here
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/category/:categoryId',
        builder: (context, state) => CategoryScreen(
          categoryId: state.pathParameters['categoryId']!,
        ),
      ),
      GoRoute(
        path: '/buyer-needs',
        builder: (context, state) => const BuyerNeedsScreen(),
      ),
      GoRoute(
        path: '/buyer-needs/new',
        builder: (context, state) => const CreateBuyerNeedScreen(),
      ),
      GoRoute(
        path: '/price-board',
        builder: (context, state) => const PriceBoardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:profileId',
        builder: (context, state) => PublicProfileScreen(
          profileId: state.pathParameters['profileId']!,
        ),
      ),
      GoRoute(
        path: '/seller/:sellerId',
        builder: (context, state) => SellerCatalogScreen(
          sellerId: state.pathParameters['sellerId']!,
        ),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ThreadsScreen(),
      ),
      GoRoute(
        path: '/chat/:threadId',
        redirect: (context, state) =>
            int.tryParse(state.pathParameters['threadId'] ?? '') == null
                ? '/chats'
                : null,
        builder: (context, state) {
          final routeData = state.extra is ChatRouteData
              ? state.extra as ChatRouteData
              : null;
          return ChatScreen(
            threadId: int.parse(state.pathParameters['threadId']!),
            otherUserName: routeData?.otherUserName ?? 'Chat',
          );
        },
      ),
      GoRoute(
        path: '/listing/new',
        builder: (context, state) => CreateListingScreen(
          categoryId: state.uri.queryParameters['category'],
          listing:
              state.extra is ListingModel ? state.extra as ListingModel : null,
        ),
      ),
      GoRoute(
        path: '/listing/:listingId/edit',
        redirect: (context, state) =>
            int.tryParse(state.pathParameters['listingId'] ?? '') == null
                ? '/profile'
                : null,
        builder: (context, state) => EditListingScreen(
          listingId: int.parse(state.pathParameters['listingId']!),
        ),
      ),
      GoRoute(
        path: '/listing/:listingId',
        redirect: (context, state) =>
            int.tryParse(state.pathParameters['listingId'] ?? '') == null
                ? '/home'
                : null,
        builder: (context, state) => ListingDetailScreen(
          listingId: int.parse(state.pathParameters['listingId']!),
          routeData: state.extra is ListingDetailRouteData
              ? state.extra as ListingDetailRouteData
              : null,
        ),
      ),
    ],
  );
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable() {
    _subscription = SupabaseConfig.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
