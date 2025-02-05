import 'dart:async';
import 'package:logging/logging.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';

class UIAvatarsService {
  /// Logger
  final Logger _log = Logger('UIAvatarsService');

  /// Mapping between a JID and whether we have requested an avatar for the
  /// JID already in the session (from login until stream resumption failure).
  final Map<String, bool> _avatarRequested = {};

  final StreamController<AvatarUpdatedEvent> _updatedController =
      StreamController.broadcast();
  Stream<AvatarUpdatedEvent> get stream => _updatedController.stream;

  void requestAvatarIfRequired(String jid, String? hash, bool ownAvatar) {
    if (_avatarRequested[jid] ?? false) return;

    _log.finest('Requesting avatar for $jid');
    _avatarRequested[jid] = true;
    MoxplatformPlugin.handler.getDataSender().sendData(
          RequestAvatarForJidCommand(
            jid: jid,
            hash: hash,
            ownAvatar: ownAvatar,
          ),
        );
  }

  void resetCache() {
    _avatarRequested.clear();
  }

  void notifyAvatars(AvatarUpdatedEvent event) {
    _updatedController.add(event);
  }
}
