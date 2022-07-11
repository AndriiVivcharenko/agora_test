import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:agora_rtc_engine/rtc_channel.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_test/agora_engine.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;

class CallPage extends StatefulWidget {
  const CallPage({Key? key}) : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  static const channelId = 'test';

  int? _remoteUid;
  int _myUid = Random.secure().nextInt(4294967296);
  late final RtcEngine _engine;

  bool _joined = false;

  late Timer _periodicConnectionState;

  bool _myCameraState = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  @override
  void dispose() {
    _periodicConnectionState.cancel();
    _engine.stopPreview();
    _engine.leaveChannel();
    super.dispose();
  }

  Future<void> _initAgora() async {
    _engine = await RtcEngine.createWithContext(
        RtcEngineContext("appid"));
    await _engine.startPreview();

    await _engine.enableVideo();
    await _engine.disableAudio();


    _periodicConnectionState = Timer.periodic(const Duration(seconds: 5), (timer) {
      _engine.getConnectionState().then((value) {
        print(value.name);
      });
    });

    _setEventHandler();
    await _engine.joinChannel(
        "token",
        channelId,
        null,
        _myUid);
  }

  void _setEventHandler() {
    _engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (String channel, int uid, int elapsed) {
        _joined = true;
        setState(() {});
      },
      userJoined: (int uid, int elapsed) {
        _remoteUid = uid;
        setState(() {});
      },
      leaveChannel: (RtcStats stats) {
        print(stats.toJson());
      },
      remoteVideoStateChanged: (int uid, VideoRemoteState state,
          VideoRemoteStateReason reason, int elapsed) {
        print(uid);
        print(state.name);
        print(reason.name);
      },
      userOffline: (int uid, UserOfflineReason reason) {
        if (uid == _remoteUid) {
          _remoteUid = null;
        }
        setState(() {});
      },
      error: (e) {
        print(e);
      },
      warning: (e) {
        print(e);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Call"),
        toolbarHeight: 50,
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_joined) ...[
                  if (_remoteUid != null)
                    SizedBox(
                      width: (9 / 16) * MediaQuery.of(context).size.height -
                          50 -
                          MediaQuery.of(context).padding.top,
                      height: MediaQuery.of(context).size.height -
                          50 -
                          MediaQuery.of(context).padding.top,
                      child: rtc_remote_view.SurfaceView(
                          uid: _remoteUid!, channelId: channelId),
                    )
                  else
                    _buildCenterLoader("Waiting remote user")
                ] else ...[
                  _buildCenterLoader("Joining...")
                ]
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                children: [
                  const SizedBox(
                    width: 120,
                    height: (16 / 9) * 120,
                    child: rtc_local_view.SurfaceView(channelId: channelId),
                  ),
                  ElevatedButton(onPressed: () {
                    _myCameraState = !_myCameraState;
                    _engine.muteLocalVideoStream(_myCameraState);
                  }, child: Text("Switch Camera"))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Center _buildCenterLoader(String title) {
    return Center(
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(
            height: 12,
          ),
          Text(title)
        ],
      ),
    );
  }
}
