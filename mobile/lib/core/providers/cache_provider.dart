import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// TTL cache utility for Riverpod async providers.
/// Usage: call `CacheTTL.schedule(ref, 'providerKey')` in the provider body
/// after successful fetch. After TTL expires, the provider auto-invalidates
/// and the next access triggers a refetch.
class CacheTTL {
  static const Duration ttl = Duration(minutes: 5);

  static final Map<String, Timer?> _timers = {};

  /// Schedule auto-invalidation of the given provider after TTL expires.
  /// Call this inside a provider's build method after data is fetched.
  static void schedule(Ref ref, String providerKey) {
    _timers[providerKey]?.cancel();
    _timers[providerKey] = Timer(ttl, () {
      ref.invalidateSelf();
      _timers.remove(providerKey);
    });

    ref.onDispose(() {
      _timers[providerKey]?.cancel();
      _timers.remove(providerKey);
    });
  }
}
