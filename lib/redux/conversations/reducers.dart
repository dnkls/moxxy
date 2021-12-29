import "dart:collection";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

List<Conversation> conversationReducer(List<Conversation> state, dynamic action) {
  if (action is AddConversationAction) {
    state.add(Conversation(
        title: action.title,
        lastMessageBody: action.lastMessageBody,
        avatarUrl: action.avatarUrl,
        jid: action.jid,
        // TODO: Correct?
        unreadCounter: 0,
        sharedMediaPaths: action.sharedMediaPaths,
        lastChangeTimestamp: action.lastChangeTimestamp,
        open: action.open,
        id: action.id
    ));
  } else if (action is SendMessageAction) {
    return state.map((element) {
        if (element.jid == action.jid) {
          return element.copyWith(lastMessageBody: action.body, lastChangeTimestamp: action.timestamp);
        }

        return element;
    }).toList();
  } else if (action is CloseConversationAction) {
    // TODO: Yikes.
    return state.map((element) => element.jid == action.jid ? element.copyWith(open: false) : element).toList().where((element) => element.open).toList();
  }

  return state;
}
