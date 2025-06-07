library;

class NetworkerRtcIceServer {
  final String url;

  const NetworkerRtcIceServer({required this.url});

  Map<String, dynamic> toMap() => {'url': url};
}

class NetworkerRtcConfiguration {
  final List<List<NetworkerRtcIceServer>> iceServers;

  const NetworkerRtcConfiguration({
    this.iceServers = const [
      [NetworkerRtcIceServer(url: 'stun:stunserver.stunprotocol.org:3478')],
    ],
  });

  Map<String, dynamic> toMap() => {
    'iceServers': iceServers
        .map((e) => e.map((e) => e.toMap()).toList())
        .toList(),
  };
}
