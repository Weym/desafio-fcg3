import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/providers/cache_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheTTL constants', () {
    test('exposes a 5-minute TTL', () {
      expect(CacheTTL.ttl, const Duration(minutes: 5));
    });
  });

  group('CacheTTL.schedule TTL expiry', () {
    test(
        'invalidates the provider after 5 minutes, forcing a rebuild on next read',
        () {
      fakeAsync((async) {
        // Build counter lives outside the provider so we do not mutate other
        // providers during a build (which Riverpod disallows).
        var buildCount = 0;

        final provider = Provider<int>((ref) {
          buildCount++;
          CacheTTL.schedule(ref, 'ttl_expiry_test');
          return buildCount;
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // First read triggers the initial build and schedules a 5-min timer.
        expect(container.read(provider), 1);
        expect(buildCount, 1);

        // Before TTL elapses, the cached value is returned (no rebuild).
        async.elapse(const Duration(minutes: 4));
        expect(container.read(provider), 1);
        expect(buildCount, 1);

        // Advance past the 5-minute threshold — Timer fires invalidateSelf.
        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();

        // Next read must rebuild, incrementing the counter.
        expect(
          container.read(provider),
          2,
          reason: 'Provider must rebuild after TTL-triggered invalidateSelf',
        );
        expect(buildCount, 2);
      });
    });
  });

  group('CacheTTL.schedule rescheduling', () {
    test('cancels the previous timer when called again with the same key', () {
      fakeAsync((async) {
        var buildCount = 0;

        final provider = Provider<int>((ref) {
          buildCount++;
          CacheTTL.schedule(ref, 'ttl_reschedule_test');
          return buildCount;
        });

        final container = ProviderContainer();
        addTearDown(container.dispose);

        // First build at t=0 schedules a timer for t+5min.
        container.read(provider);
        expect(buildCount, 1);

        // At t=3min, manually invalidate. The rebuild reschedules the timer
        // so it should fire at t=3+5=8min (not at the original t=5min).
        async.elapse(const Duration(minutes: 3));
        container.invalidate(provider);
        container.read(provider);
        expect(buildCount, 2);

        // At t=7min (4min since reschedule), the rescheduled timer has NOT
        // fired yet. The counter must not have incremented.
        async.elapse(const Duration(minutes: 4));
        expect(buildCount, 2);

        // At t=9min (6min since reschedule), the rescheduled timer fires
        // and the next read rebuilds.
        async.elapse(const Duration(minutes: 2));
        async.flushMicrotasks();
        container.read(provider);
        expect(
          buildCount,
          3,
          reason: 'Rescheduled timer should fire 5 minutes after reschedule',
        );
      });
    });
  });

  group('CacheTTL.schedule dispose cleanup', () {
    test('cancels pending timer on provider dispose (no leaked timers)', () {
      fakeAsync((async) {
        var buildCount = 0;

        final provider = Provider.autoDispose<int>((ref) {
          buildCount++;
          CacheTTL.schedule(ref, 'ttl_dispose_test');
          return buildCount;
        });

        final container = ProviderContainer();

        // Read once, then hold no reference so autoDispose cleans up.
        final sub = container.listen(provider, (_, __) {});
        expect(buildCount, 1);
        sub.close();

        // Force disposal of the provider by disposing the container.
        container.dispose();

        // Advance well past TTL: the onDispose cleanup must have cancelled
        // the timer so nothing fires and no pending timers remain.
        async.elapse(const Duration(minutes: 10));
        async.flushMicrotasks();

        expect(
          async.pendingTimers,
          isEmpty,
          reason:
              'onDispose on the Ref must cancel the CacheTTL timer so no '
              'timers remain pending after disposal',
        );
      });
    });
  });
}
