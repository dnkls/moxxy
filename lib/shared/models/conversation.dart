import "package:moxxyv2/shared/models/media.dart";

import "package:freezed_annotation/freezed_annotation.dart";

part "conversation.freezed.dart";
part "conversation.g.dart";

@freezed
class Conversation with _$Conversation {
  factory Conversation(
    String title,
    String lastMessageBody,
    String avatarUrl,
    String jid,
    int unreadCounter,
    // NOTE: In milliseconds since Epoch or -1 if none has ever happened
    int lastChangeTimestamp,
    // TODO: Maybe have a model for this, but this should be enough
    List<SharedMedium> sharedMedia,
    int id,
    // Indicates if the conversation should be shown on the homescreen
    bool open,
    // Indicates, if [jid] is a regular user, if the user is in the roster.
    bool inRoster
  ) = _Conversation;

  // JSON
  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
}

/// Sorts conversations in descending order by their last change timestamp.
int compareConversation(Conversation a, Conversation b) {
  return -1 * Comparable.compare(a.lastChangeTimestamp, b.lastChangeTimestamp);
}
