import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:phone_state/phone_state.dart';

class PhoneStateController {
  StreamSubscription<PhoneStateStatus?>? subscription;
  late final void Function() onCallEnded;

  PhoneStateController({required this.onCallEnded});

  Future<StreamSubscription<PhoneStateStatus?>?> initStream() async {
    final granted = await requestPermission();
    if (granted) {
      setStream();
      return subscription;
    }
    return null;
  }

  Future<bool> requestPermission() async {
    final status = await Permission.phone.request();
    if (status == PermissionStatus.granted) return true;
    return false;
  }

  void setStream() {
    subscription = PhoneState.phoneStateStream.listen((status) {
      if (status == PhoneStateStatus.CALL_ENDED) {
        onCallEnded();
      }
    });
  }

  void cancel() {
    subscription?.cancel();
  }
}
