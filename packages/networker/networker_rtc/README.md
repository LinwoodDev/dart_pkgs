# Networker RTC

> RTC implementation of the networker API.

See the [networker](../networker) package for more information.

`networker_rtc` provides a WebRTC data-channel transport. It deliberately does
not own signaling; pass `NetworkerRtcSignal` objects through Swamp, websockets,
HTTP, QR codes, or any other channel, then feed the received signals back with
`handleSignal`.

```dart
final server = NetworkerRtcServer();
final client = NetworkerRtcClient(Uri.parse('rtc://host'));

server.onSignal.listen(client.handleSignal);
client.onSignal.listen(server.handleSignal);

await server.init();
await client.init();
final channel = await server.addPeer();

await client.onOpen.first;
await server.sendMessage(Uint8List.fromList([1, 2, 3]), channel);
```

Run the desktop chat example from `packages/networker/networker_rtc/example`:

```sh
flutter run -d linux
```

Open three instances for the full flow:

1. In the first instance choose `Start signaling server`.
2. Copy the shown `ws://.../rtc?room=demo` URL.
3. In the other two instances paste that URL and choose `Join as peer`.

The WebSocket server is only a rendezvous point. It relays offer, answer, and
ICE candidates between the two peers. Chat messages are sent directly over the
WebRTC data channel once it opens.
