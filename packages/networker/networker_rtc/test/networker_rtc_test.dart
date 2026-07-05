import 'package:networker/networker.dart';
import 'package:networker_rtc/config.dart';
import 'package:test/test.dart';

void main() {
  test('configuration maps ice servers to WebRTC format', () {
    final config = NetworkerRtcConfiguration(
      iceServers: const [
        NetworkerRtcIceServer(
          urls: ['stun:example.org:3478', 'turn:example.org:3478'],
          username: 'user',
          credential: 'secret',
        ),
      ],
      extra: const {'sdpSemantics': 'unified-plan'},
    );

    expect(config.toMap(), {
      'sdpSemantics': 'unified-plan',
      'iceServers': [
        {
          'urls': ['stun:example.org:3478', 'turn:example.org:3478'],
          'username': 'user',
          'credential': 'secret',
        },
      ],
    });
  });

  test('signals round trip through maps', () {
    const signal = NetworkerRtcSignal(
      type: NetworkerRtcSignalType.candidate,
      channel: kAuthorityChannel,
      candidate: NetworkerRtcIceCandidate(
        candidate: 'candidate',
        sdpMid: '0',
        sdpMLineIndex: 1,
      ),
    );

    final decoded = NetworkerRtcSignal.fromMap(signal.toMap());

    expect(decoded.type, NetworkerRtcSignalType.candidate);
    expect(decoded.channel, kAuthorityChannel);
    expect(decoded.candidate?.candidate, 'candidate');
    expect(decoded.candidate?.sdpMid, '0');
    expect(decoded.candidate?.sdpMLineIndex, 1);
  });
}
