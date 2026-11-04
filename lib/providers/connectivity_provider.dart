import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return _connectivityEvents(connectivity);
});

Stream<bool> _connectivityEvents(Connectivity connectivity) async* {
  yield _hasNetwork(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_hasNetwork);
}

bool _hasNetwork(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}
