library;

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:networker/networker.dart';

class NetworkerRtcIceServer {
  final String? url;
  final List<String>? urls;
  final String? username;
  final String? credential;

  const NetworkerRtcIceServer({
    this.url,
    this.urls,
    this.username,
    this.credential,
  }) : assert(url != null || urls != null);

  const NetworkerRtcIceServer.stun(String url) : this(url: url);

  const NetworkerRtcIceServer.turn(
    String url, {
    required String username,
    required String credential,
  }) : this(url: url, username: username, credential: credential);

  Map<String, dynamic> toMap() => {
    'urls': urls ?? url,
    if (username != null) 'username': username,
    if (credential != null) 'credential': credential,
  };
}

class NetworkerRtcConfiguration {
  static const defaultIceServers = [
    NetworkerRtcIceServer.stun('stun:stun.l.google.com:19302'),
    NetworkerRtcIceServer.stun('stun:stun1.l.google.com:19302'),
    NetworkerRtcIceServer.stun('stun:stun2.l.google.com:19302'),
    NetworkerRtcIceServer.stun('stun:global.stun.twilio.com:3478'),
  ];

  final List<NetworkerRtcIceServer> iceServers;
  final Map<String, dynamic> extra;

  const NetworkerRtcConfiguration({
    this.iceServers = defaultIceServers,
    this.extra = const {},
  });

  Map<String, dynamic> toMap() => {
    ...extra,
    'iceServers': iceServers.map((e) => e.toMap()).toList(),
  };
}

enum NetworkerRtcSignalType { offer, answer, candidate }

class NetworkerRtcSessionDescription {
  final String? sdp;
  final String? type;

  const NetworkerRtcSessionDescription({required this.sdp, required this.type});

  factory NetworkerRtcSessionDescription.fromRtc(
    RTCSessionDescription description,
  ) => NetworkerRtcSessionDescription(
    sdp: description.sdp,
    type: description.type,
  );

  factory NetworkerRtcSessionDescription.fromMap(Map<String, dynamic> map) =>
      NetworkerRtcSessionDescription(
        sdp: map['sdp'] as String?,
        type: map['type'] as String?,
      );

  RTCSessionDescription toRtc() => RTCSessionDescription(sdp, type);

  Map<String, dynamic> toMap() => {'sdp': sdp, 'type': type};
}

class NetworkerRtcIceCandidate {
  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;

  const NetworkerRtcIceCandidate({
    required this.candidate,
    required this.sdpMid,
    required this.sdpMLineIndex,
  });

  factory NetworkerRtcIceCandidate.fromRtc(RTCIceCandidate candidate) =>
      NetworkerRtcIceCandidate(
        candidate: candidate.candidate,
        sdpMid: candidate.sdpMid,
        sdpMLineIndex: candidate.sdpMLineIndex,
      );

  factory NetworkerRtcIceCandidate.fromMap(Map<String, dynamic> map) =>
      NetworkerRtcIceCandidate(
        candidate: map['candidate'] as String?,
        sdpMid: map['sdpMid'] as String?,
        sdpMLineIndex: map['sdpMLineIndex'] as int?,
      );

  RTCIceCandidate toRtc() => RTCIceCandidate(candidate, sdpMid, sdpMLineIndex);

  Map<String, dynamic> toMap() => {
    'candidate': candidate,
    'sdpMid': sdpMid,
    'sdpMLineIndex': sdpMLineIndex,
  };
}

class NetworkerRtcSignal {
  final NetworkerRtcSignalType type;
  final Channel channel;
  final NetworkerRtcSessionDescription? description;
  final NetworkerRtcIceCandidate? candidate;

  const NetworkerRtcSignal({
    required this.type,
    this.channel = kAnyChannel,
    this.description,
    this.candidate,
  });

  factory NetworkerRtcSignal.offer(
    RTCSessionDescription description, {
    Channel channel = kAnyChannel,
  }) => NetworkerRtcSignal(
    type: NetworkerRtcSignalType.offer,
    channel: channel,
    description: NetworkerRtcSessionDescription.fromRtc(description),
  );

  factory NetworkerRtcSignal.answer(
    RTCSessionDescription description, {
    Channel channel = kAnyChannel,
  }) => NetworkerRtcSignal(
    type: NetworkerRtcSignalType.answer,
    channel: channel,
    description: NetworkerRtcSessionDescription.fromRtc(description),
  );

  factory NetworkerRtcSignal.candidate(
    RTCIceCandidate candidate, {
    Channel channel = kAnyChannel,
  }) => NetworkerRtcSignal(
    type: NetworkerRtcSignalType.candidate,
    channel: channel,
    candidate: NetworkerRtcIceCandidate.fromRtc(candidate),
  );

  factory NetworkerRtcSignal.fromMap(Map<String, dynamic> map) =>
      NetworkerRtcSignal(
        type: NetworkerRtcSignalType.values.byName(map['type'] as String),
        channel: map['channel'] as int? ?? kAnyChannel,
        description: switch (map['description']) {
          final Map<String, dynamic> description =>
            NetworkerRtcSessionDescription.fromMap(description),
          final Map description => NetworkerRtcSessionDescription.fromMap(
            Map<String, dynamic>.from(description),
          ),
          _ => null,
        },
        candidate: switch (map['candidate']) {
          final Map<String, dynamic> candidate =>
            NetworkerRtcIceCandidate.fromMap(candidate),
          final Map candidate => NetworkerRtcIceCandidate.fromMap(
            Map<String, dynamic>.from(candidate),
          ),
          _ => null,
        },
      );

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'channel': channel,
    if (description != null) 'description': description!.toMap(),
    if (candidate != null) 'candidate': candidate!.toMap(),
  };
}
