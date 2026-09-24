import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/session.dart';
import '../features/requests/presentation/pages.dart';
import '../l10n/generated/app_localizations.dart';
import 'dependencies.dart';

String safeReturnPath(String? raw) {
  if (raw == null || raw.length > 512) return '/requests';
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasQuery ||
      uri.hasFragment ||
      !uri.path.startsWith('/')) {
    return '/requests';
  }
  final p = uri.pathSegments;
  if (p.length == 1 && {'requests', 'settings'}.contains(p[0])) return uri.path;
  if (p.length == 2 &&
      p[0] == 'requests' &&
      RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(p[1])) {
    return uri.path;
  }
  return '/requests';
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (before, after) {
    refresh.value++;
  });
  final router = GoRouter(
    initialLocation: '/requests',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(sessionProvider) != null;
      final login = state.uri.path == '/login';
      if (!signedIn && !login) {
        return Uri(
          path: '/login',
          queryParameters: {'from': safeReturnPath(state.uri.toString())},
        ).toString();
      }
      if (signedIn && login) {
        return safeReturnPath(state.uri.queryParameters['from']);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/requests',
        builder: (context, state) => const RequestsPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CreateRequestPage(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                RequestDetailPage(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/requests'),
          child: Text(AppLocalizations.of(context).backToList),
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.labLogin)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.labNotice),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('login-ana'),
            onPressed: () => ref.read(sessionProvider.notifier).login('ana'),
            child: Text(l.loginAna),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('login-bruno'),
            onPressed: () => ref.read(sessionProvider.notifier).login('bruno'),
            child: Text(l.loginBruno),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l.language),
          DropdownButton<String>(
            isExpanded: true,
            value: locale?.languageCode ?? 'system',
            items: [
              DropdownMenuItem(value: 'system', child: Text(l.systemLanguage)),
              const DropdownMenuItem(value: 'es', child: Text('Castellano')),
              const DropdownMenuItem(value: 'eu', child: Text('Euskara')),
            ],
            onChanged: (value) => ref
                .read(localeProvider.notifier)
                .change(value == 'system' ? null : value),
          ),
        ],
      ),
    );
  }
}
