import 'dart:convert';
import 'package:meta/meta.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/types/resultv2.dart';
import 'package:moxxyv2/xmpp/xeps/errors.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0060.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0380.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0384/crypto.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0384/errors.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0384/helpers.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0384/types.dart';
import 'package:omemo_dart/omemo_dart.dart';

const _doNotEncryptList = [
  // XEP-0033
  DoNotEncrypt('addresses', extendedAddressingXmlns),
  // XEP-0334
  DoNotEncrypt('no-permanent-store', messageProcessingHintsXmlns),
  DoNotEncrypt('no-store', messageProcessingHintsXmlns),
  DoNotEncrypt('no-copy', messageProcessingHintsXmlns),
  DoNotEncrypt('store', messageProcessingHintsXmlns),
  // XEP-0359
  DoNotEncrypt('origin-id', stableIdXmlns),
  DoNotEncrypt('stanza-id', stableIdXmlns),
];

class OmemoManager extends XmppManagerBase {

  OmemoManager(this.omemoState) : super() {
    omemoState.eventStream.listen((event) async {
      if (event is RatchetModifiedEvent) {
        await commitRatchet(event.ratchet, event.jid, event.deviceId);
      } else if (event is DeviceMapModifiedEvent) {
        await commitDeviceMap(event.map);
      } else if (event is DeviceModifiedEvent) {
        await commitDevice(event.device);

        // Publish it
        await publishBundle(await event.device.toBundle());
      }
    });
  }

  @protected
  final OmemoSessionManager omemoState;

  final Map<JID, List<int>> _deviceMap = {};
  
  @override
  String getId() => omemoManager;

  @override
  String getName() => 'OmemoManager';

  // TODO(Unknown): Technically, this is not always true
  @override
  Future<bool> isSupported() async => true;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    /*StanzaHandler(
      stanzaTag: 'iq',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onIncomingStanza,
    ),*/
    StanzaHandler(
      stanzaTag: 'message',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onIncomingStanza,
      priority: -98,
    ),
  ];

  @override
  List<StanzaHandler> getOutgoingPreStanzaHandlers() => [
    /*StanzaHandler(
      stanzaTag: 'iq',
      tagXmlns: omemoXmlns,
      tagName: 'encrypted',
      callback: _onOutgoingStanza,
    ),*/
    StanzaHandler(
      stanzaTag: 'message',
      callback: _onOutgoingStanza,
      priority: 100,
    ),
  ];

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PubSubNotificationEvent) {
      if (event.item.node != omemoDevicesXmlns) return;

      _deviceMap[JID.fromString(event.from)] = event.item.payload.children
        .map((child) => int.parse(child.attributes['id']! as String))
        .toList();
    }
  }
  
  /// Commit the OMEMO ratchet to persistent storage, if wanted.
  @visibleForOverriding
  Future<void> commitRatchet(OmemoDoubleRatchet ratchet, String jid, int deviceId) async {}

  /// Commit the session manager's device map to storage, if wanted.
  @visibleForOverriding
  Future<void> commitDeviceMap(Map<String, List<int>> map) async {}

  /// Commit the device to storage, if wanted.
  @visibleForOverriding
  Future<void> commitDevice(Device device) async {}

  /// Determines what child elements of a stanza should be encrypted. If shouldEncrypt
  /// returns true for [element], then [element] will be encrypted. If shouldEncrypt
  /// returns false, then [element] won't be encrypted.
  ///
  /// The default implementation ignores all elements that are mentioned in XEP-0420, i.e.:
  /// - XEP-0033 elements (<addresses />)
  /// - XEP-0334 elements (<store/>, <no-copy/>, <no-store/>, <no-permanent-store/>)
  /// - XEP-0359 elements (<origin-id />, <stanza-id />)
  @visibleForOverriding
  bool shouldEncrypt(XMLNode element) {
    for (final ignore in _doNotEncryptList) {
      final xmlns = element.attributes['xmlns'] ?? '';
      if (element.tag == ignore.tag && xmlns == ignore.xmlns) {
        return false;
      }
    }

    return true;
  }
  
  /// Encrypt [children] using OMEMO. This either produces an <encrypted /> element with
  /// an attached payload, if [children] is not null, or an empty OMEMO message if
  /// [children] is null. This function takes care of creating the affix elements as
  /// specified by both XEP-0420 and XEP-0384.
  /// [jids] is the list of JIDs the payload should be encrypted for.
  Future<XMLNode> _encryptChildren(List<XMLNode>? children, List<String> jids, String toJid, List<OmemoBundle> newSessions) async {
    XMLNode? payload;
    if (children != null) {
      payload = XMLNode.xmlns(
        tag: 'envelope',
        xmlns: sceXmlns,
        children: [
          XMLNode(
            tag: 'content',
            children: children,
          ),

          XMLNode(
            tag: 'rpad',
            text: generateRpad(),
          ),
          XMLNode(
            tag: 'to',
            attributes: <String, String>{
              'jid': toJid,
            },
          ),
          XMLNode(
            tag: 'from',
            attributes: <String, String>{
              'jid': getAttributes().getFullJID().toString(),
            },
          ),
          /*
          XMLNode(
            tag: 'time',
            // TODO(Unknown): Implement
            attributes: <String, String>{
              'stamp': '',
            },
          ),
          */
        ],
      );
    }

    final encryptedEnvelope = await omemoState.encryptToJids(
      jids,
      payload?.toXml(),
      newSessions: newSessions,
    );

    final keyElements = <String, List<XMLNode>>{};
    for (final key in encryptedEnvelope.encryptedKeys) {
      final keyElement = XMLNode(
        tag: 'key',
        attributes: <String, String>{
          'rid': '${key.rid}',
          'kex': key.kex ? 'true' : 'false',
        },
        text: key.value,
      );

      if (keyElements.containsKey(key.jid)) {
        keyElements[key.jid]!.add(keyElement);
      } else {
        keyElements[key.jid] = [keyElement];
      }
    }

    final keysElements = keyElements.entries.map((entry) {
      return XMLNode(
        tag: 'keys',
        attributes: <String, String>{
          'jid': entry.key,
        },
        children: entry.value,
      );
    }).toList();

    var payloadElement = <XMLNode>[];
    if (payload != null) {
      payloadElement = [
        XMLNode(
          tag: 'payload',
          text: base64.encode(encryptedEnvelope.ciphertext!),
        ),
      ];
    }
    
    return XMLNode.xmlns(
      tag: 'encrypted',
      xmlns: omemoXmlns,
      children: [
        ...payloadElement,
        XMLNode(
          tag: 'header',
          attributes: <String, String>{
            'sid': (await omemoState.getDeviceId()).toString(),
          },
          children: keysElements,
        ),
      ],
    );
  }

  Future<void> _ackRatchet(String jid, int deviceId) async {
    logger.finest('Acking ratchet $jid:$deviceId');
    await omemoState.ratchetAcknowledged(jid, deviceId);
  }

  Future<Result<OmemoError, List<OmemoBundle>>> _findNewSessions(JID toJid) async {
    final newSessions = List<OmemoBundle>.empty(growable: true);
    final unackedRatchets = await omemoState.getUnacknowledgedRatchets(toJid.toString());
    final sessionAvailable = (await omemoState.getDeviceMap()).containsKey(toJid.toString());
    if (!sessionAvailable) {
      logger.finest('No session for $toJid. Retrieving bundles to build a new session.');
      final bundles = await retrieveDeviceBundles(toJid);
      if (!bundles.isType<OmemoError>()) {
        newSessions.addAll(bundles.get<List<OmemoBundle>>());
      } else {
        logger.warning('Failed to retrieve device bundles for $toJid');
      }
    } else if (unackedRatchets != null && unackedRatchets.isNotEmpty) {
      logger.finest('Got unacked ratchets');
      for (final id in unackedRatchets) {
        logger.finest('Retrieving bundle for $toJid:$id');
        final bundle = await retrieveDeviceBundle(toJid, id);
        if (!bundle.isType<OmemoError>()) {
          newSessions.add(bundle.get<OmemoBundle>());
        } else {
          logger.warning('Failed to retrieve device bundles for $toJid:$id');
        }
      }
    } else {
      final map = await omemoState.getDeviceMap();
      final devices = map[toJid.toString()]!;
      final ratchetSessionsRaw = await getDeviceList(toJid);
      if (ratchetSessionsRaw.isType<OmemoError>()) return Result(OmemoUnknownError());

      final ratchetSessions = ratchetSessionsRaw.get<List<int>>();
      if (devices.length != ratchetSessions.length) {
        logger.finest('Mismatch between devices we have a session with and published devices');
        for (final id in devices) {
          if (ratchetSessions.contains(id)) continue;

          logger.finest('Retrieving bundle for $toJid:$id');
          final bundle = await retrieveDeviceBundle(toJid, id);
          if (!bundle.isType<OmemoBundle>()) {
            newSessions.add(bundle.get<OmemoBundle>());
          } else {
            logger.warning('Failed to retrieve bundle for $toJid:$id');
          }
        }
      }
    }

    return Result(newSessions);
  }

  Future<void> sendEmptyMessage(JID toJid, {bool findNewSessions = false}) async {
    var newSessions = <OmemoBundle>[];
    if (findNewSessions) {
      final result = await _findNewSessions(toJid);
      if (!result.isType<OmemoError>()) newSessions = result.get<List<OmemoBundle>>();
    }

    final empty = await _encryptChildren(
      null,
      [toJid.toString()],
      toJid.toString(),
      newSessions,
    );

    await getAttributes().sendStanza(
      Stanza.message(
        to: toJid.toString(),
        type: 'chat',
        children: [empty],
      ),
      awaitable: false,
      encrypted: true,
    );
  }
  
  Future<StanzaHandlerData> _onOutgoingStanza(Stanza stanza, StanzaHandlerData state) async {
    if (state.encrypted) {
      return state;
    }
    
    final toJid = JID.fromString(stanza.to!).toBare();
    var newSessions = <OmemoBundle>[];
    final result = await _findNewSessions(toJid);
    if (!result.isType<OmemoError>()) {
      newSessions = result.get<List<OmemoBundle>>();
    }
    
    final toEncrypt = List<XMLNode>.empty(growable: true);
    final children = List<XMLNode>.empty(growable: true);
    for (final child in stanza.children) {
      if (!shouldEncrypt(child)) {
        children.add(child);
      } else {
        toEncrypt.add(child);
      }
    }

    try {
      logger.finest('Encrypting stanza');
      final encrypted = await _encryptChildren(
        toEncrypt,
        [ 
          JID.fromString(stanza.to!).toBare().toString(),
          //bareJid.toString(),
        ],
        stanza.to!,
        newSessions,
      );
      logger.finest('Encryption done');

      return state.copyWith(
        stanza: state.stanza.copyWith(
          children: children
            ..add(encrypted)
            ..add(buildEmeElement(ExplicitEncryptionType.omemo2)),
        ),
      );
    } catch (ex) {
      return state.copyWith(
        other: {
          ...state.other,
          'encryption_error': ex,
        },
      );
    }
  }


  Future<StanzaHandlerData> _onIncomingStanza(Stanza stanza, StanzaHandlerData state) async {
    final encrypted = stanza.firstTag('encrypted', xmlns: omemoXmlns);
    if (encrypted == null) return state;

    final header = encrypted.firstTag('header')!;
    final payloadElement = encrypted.firstTag('payload');
    final keys = List<EncryptedKey>.empty(growable: true);
    for (final keysElement in header.findTags('keys')) {
      final jid = keysElement.attributes['jid']! as String;
      for (final key in keysElement.findTags('key')) {
        keys.add(
          EncryptedKey(
            jid,
            int.parse(key.attributes['rid']! as String),
            key.innerText(),
            key.attributes['kex'] == 'true',
          ),
        );
      }
    }

    final fromJid = JID.fromString(stanza.from!).toBare();
    final ourJid = getAttributes().getFullJID();
    final sid = int.parse(header.attributes['sid']! as String);

    String? decrypted;
    try {
      decrypted = await omemoState.decryptMessage(
        payloadElement != null ? base64.decode(payloadElement.innerText()) : null,
        fromJid.toString(),
        sid,
        keys,
      );
    } catch (ex) {
      logger.warning('Error occurred during message decryption: $ex');
      return state.copyWith(
        other: {
          ...state.other,
          'encryption_error': ex,
        },
      );
    }
    
    final isAcked = await omemoState.isRatchetAcknowledged(fromJid.toString(), sid);
    if (!isAcked) {
      // Unacked ratchet decrypted this message
      if (decrypted != null) {
        // The message is not empty, i.e. contains content
        logger.finest('Received non-empty OMEMO encrypted message for unacked ratchet. Acking with empty OMEMO message.');

        await _ackRatchet(fromJid.toString(), sid);
        await sendEmptyMessage(fromJid);

        final envelope = XMLNode.fromString(decrypted);
        final children = stanza.children.where(
          (child) => child.tag != 'encrypted' || child.attributes['xmlns'] != omemoXmlns,
        ).toList()
          ..addAll(envelope.firstTag('content')!.children);

        final other = Map<String, dynamic>.from(state.other);
        if (!checkAffixElements(envelope, stanza.from!, ourJid)) {
          other['encryption_error'] = InvalidAffixElementsException();
        }
          
        return state.copyWith(
          encrypted: true,
          stanza: Stanza(
            to: stanza.to,
            from: stanza.from,
            id: stanza.id,
            type: stanza.type,
            children: children,
            tag: stanza.tag,
            attributes: Map<String, String>.from(stanza.attributes),
          ),
          other: other,
        );
      } else {
        logger.info('Received empty OMEMO message for unacked ratchet. Marking $fromJid:$sid as acked');
        await _ackRatchet(fromJid.toString(), sid);
        return state;
      }
    } else {
      // The ratchet that decrypted the message was acked
      if (decrypted != null) {
        final envelope = XMLNode.fromString(decrypted);

        final children = stanza.children.where(
          (child) => child.tag != 'encrypted' || child.attributes['xmlns'] != omemoXmlns,
        ).toList()
          ..addAll(envelope.firstTag('content')!.children);

        final other = Map<String, dynamic>.from(state.other);
        if (!checkAffixElements(envelope, stanza.from!, ourJid)) {
          other['encryption_error'] = InvalidAffixElementsException();
        }
        
        return state.copyWith(
          encrypted: true,
          stanza: Stanza(
            to: stanza.to,
            from: stanza.from,
            id: stanza.id,
            type: stanza.type,
            children: children,
            tag: stanza.tag,
            attributes: Map<String, String>.from(stanza.attributes),
          ),
          other: other,
        );
      } else {
        logger.info('Received empty OMEMO message on acked ratchet. Doing nothing');
        return state;
      }
    }
  }

  Future<Result<OmemoError, XMLNode>> _retrieveDeviceListPayload(JID jid) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final result = await pm.getItems(jid.toBare().toString(), omemoDevicesXmlns);
    if (result.isType<PubSubError>()) return Result(OmemoUnknownError());
    return Result(result.get<List<PubSubItem>>().first.payload);
  }
  
  /// Retrieves the OMEMO device list from [jid].
  Future<Result<OmemoError, List<int>>> getDeviceList(JID jid) async {
    if (_deviceMap.containsKey(jid)) return Result(_deviceMap[jid]);

    final itemsRaw = await _retrieveDeviceListPayload(jid);
    if (itemsRaw.isType<OmemoError>()) return Result(OmemoUnknownError());

    final ids = itemsRaw.get<XMLNode>().children
      .map((child) => int.parse(child.attributes['id']! as String))
      .toList();
    _deviceMap[jid] = ids;
    return Result(ids);
  }

  Future<Result<OmemoError, List<OmemoBundle>>> retrieveDeviceBundles(JID jid) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    // TODO(PapaTutuWawa): Error handling
    final bundlesRaw = await pm.getItems(jid.toString(), omemoBundlesXmlns);
    if (bundlesRaw.isType<OmemoError>()) return Result(OmemoUnknownError());

    final bundles = bundlesRaw.get<List<PubSubItem>>().map(
      (bundle) => bundleFromXML(jid, int.parse(bundle.id), bundle.payload),
    ).toList();
    
    return Result(bundles);
  }
  
  /// Retrieves a bundle from entity [jid] with the device id [deviceId].
  Future<Result<OmemoError, OmemoBundle>> retrieveDeviceBundle(JID jid, int deviceId) async {
    final pm = getAttributes().getManagerById<PubSubManager>(pubsubManager)!;
    final bareJid = jid.toBare().toString();
    final item = await pm.getItem(bareJid, omemoBundlesXmlns, '$deviceId');
    if (item.isType<PubSubError>()) return Result(OmemoUnknownError());

    return Result(bundleFromXML(jid, deviceId, item.get<PubSubItem>().payload));
  }

  Future<Result<OmemoError, bool>> publishBundle(OmemoBundle bundle) async {
    final attrs = getAttributes();
    final pm = attrs.getManagerById<PubSubManager>(pubsubManager)!;
    final bareJid = attrs.getFullJID().toBare();

    XMLNode? deviceList;
    final deviceListRaw = await _retrieveDeviceListPayload(bareJid);
    if (!deviceListRaw.isType<OmemoError>()) {
      deviceList = deviceListRaw.get<XMLNode>();
    }

    deviceList ??= XMLNode.xmlns(
      tag: 'devices',
      xmlns: omemoDevicesXmlns,
    );

    final newDeviceList = XMLNode.xmlns(
      tag: 'devices',
      xmlns: omemoDevicesXmlns,
      children: [
        ...deviceList.children,
        XMLNode(
          tag: 'device',
          attributes: <String, String>{
            'id': '${bundle.id}',
          },
        ),
      ],
    );
    
    final deviceListPublish = await pm.publish(
      bareJid.toString(),
      omemoDevicesXmlns,
      newDeviceList,
      id: 'current',
      options: const PubSubPublishOptions(
        accessModel: 'open',
      ),
    );
    if (deviceListPublish.isType<PubSubError>()) return const Result(false);

    final deviceBundlePublish = await pm.publish(
      bareJid.toString(),
      omemoBundlesXmlns,
      bundleToXML(bundle),
      id: '${bundle.id}',
      options: const PubSubPublishOptions(
        accessModel: 'open',
        maxItems: 'max',
      ),
    );
    
    return Result(deviceBundlePublish.isType<PubSubError>());
  }
}
