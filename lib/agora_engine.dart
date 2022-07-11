
import 'package:agora_rtc_engine/rtc_engine.dart';

class AgoraEngine {
  static final AgoraEngine _instance = AgoraEngine._internal();

  late final RtcEngine _engine;

  static bool _initialized = false;

  AgoraEngine._internal();

  Future<void> init() async {
    if(!_initialized) {
      _engine = await RtcEngine.createWithContext(
          RtcEngineContext("aaa07770146d440d8b2ec72a2cbbc89c"));
      await _engine.enableVideo();
      await _engine.disableAudio();
      _initialized = true;
    }
  }

  factory AgoraEngine() {
    return _instance;
  }

  RtcEngine get value => _engine;
}
