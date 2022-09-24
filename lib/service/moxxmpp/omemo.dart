import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/omemo.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0384/xep_0384.dart';
import 'package:omemo_dart/omemo_dart.dart';

class MoxxyOmemoManager extends OmemoManager {

  MoxxyOmemoManager() : super();

  @override
  Future<OmemoSessionManager> getSessionManager() async {
    final os = GetIt.I.get<OmemoService>();
    await os.ensureInitialized();
    return os.omemoState;
  }

  @override
  Future<bool> shouldEncryptStanza(JID toJid) async {
    final cs = GetIt.I.get<ConversationService>();
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    final conversation = await cs.getConversationByJid(toJid.toString());
    return conversation?.encrypted ?? prefs.enableOmemoByDefault;
  }
}

class MoxxyBTBVTrustManager extends BlindTrustBeforeVerificationTrustManager {
  MoxxyBTBVTrustManager(
    Map<RatchetMapKey, BTBVTrustState> trustCache,
    Map<RatchetMapKey, bool> enablementCache,
    Map<String, List<int>> devices,
  ) : super(trustCache: trustCache, enablementCache: enablementCache, devices: devices);

  @override
  Future<void> commitState() async {
    await GetIt.I.get<OmemoService>().commitTrustManager(await toJson());
  }
}
