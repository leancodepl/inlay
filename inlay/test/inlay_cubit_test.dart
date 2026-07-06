import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inlay/inlay.dart';

class _FakeStore implements InlaySnapshotStore<int> {
  final _controller = StreamController<int>.broadcast();

  int snapshot = 0;
  final writes = <(int value, int? previous)>[];

  @override
  Stream<int> get stream => _controller.stream;

  @override
  Future<int> getSnapshot() async => snapshot;

  @override
  Future<void> writeSnapshot(int snapshot, {int? previous}) async {
    writes.add((snapshot, previous));
  }

  void emitExternal(int value) => _controller.add(value);

  Future<void> close() => _controller.close();
}

class _CounterCubit extends InlayCubit<int> {
  _CounterCubit(super.store);

  void setValue(int value) => emit(InlayStateReady(value));

  void backToLoading() => emit(const InlayStateLoading());
}

class _TwoStoreCubit extends Cubit<(int, int)> with InlayStoreObserver {
  _TwoStoreCubit(InlaySnapshotStore<int> a, InlaySnapshotStore<int> b)
    : super((0, 0)) {
    observeStore(a, (snapshot) => emit((snapshot, state.$2)));
    observeStore(b, (snapshot) => emit((state.$1, snapshot)));
  }
}

void main() {
  group('InlayState', () {
    test('loading state exposes no data', () {
      const InlayState<int> state = InlayStateLoading();

      expect(state.isLoading, isTrue);
      expect(state.dataOrNull, isNull);
      expect(() => state.requireData, throwsStateError);
    });

    test('ready state exposes its data', () {
      const InlayState<int> state = InlayStateReady(7);

      expect(state.isLoading, isFalse);
      expect(state.dataOrNull, 7);
      expect(state.requireData, 7);
    });
  });

  group('InlayCubit', () {
    late _FakeStore store;
    late _CounterCubit cubit;

    setUp(() {
      store = _FakeStore();
      cubit = _CounterCubit(store);
    });

    tearDown(() async {
      await cubit.close();
      await store.close();
    });

    test('starts loading, becomes ready after init', () async {
      store.snapshot = 42;

      expect(cubit.state.isLoading, isTrue);
      await cubit.init();

      expect(cubit.state.requireData, 42);
    });

    test('loading the initial snapshot does not write back', () async {
      store.snapshot = 42;

      await cubit.init();

      expect(store.writes, isEmpty);
    });

    test(
      'emit persists the snapshot with the previous state as diff base',
      () async {
        store.snapshot = 1;
        await cubit.init();

        cubit.setValue(2);

        expect(cubit.state.requireData, 2);
        expect(store.writes, [(2, 1)]);
      },
    );

    test('cross-engine stream updates state without writing back', () async {
      await cubit.init();

      store.emitExternal(99);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.requireData, 99);
      expect(store.writes, isEmpty);
    });

    test('emitting a loading state does not touch the store', () async {
      await cubit.init();

      cubit.backToLoading();

      expect(cubit.state.isLoading, isTrue);
      expect(store.writes, isEmpty);
    });

    test('close cancels the store subscription', () async {
      await cubit.init();
      await cubit.close();

      store.emitExternal(99);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.requireData, 0);
    });
  });

  group('InlayStoreObserver', () {
    test('delivers snapshots from every observed store', () async {
      final a = _FakeStore();
      final b = _FakeStore();
      final cubit = _TwoStoreCubit(a, b);

      a.emitExternal(1);
      b.emitExternal(2);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, (1, 2));
      await cubit.close();
      await a.close();
      await b.close();
    });

    test('close cancels all subscriptions', () async {
      final a = _FakeStore();
      final b = _FakeStore();
      final cubit = _TwoStoreCubit(a, b);
      await cubit.close();

      a.emitExternal(1);
      b.emitExternal(2);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, (0, 0));
      await a.close();
      await b.close();
    });
  });
}
