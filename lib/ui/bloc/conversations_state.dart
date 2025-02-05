part of 'conversations_bloc.dart';

@freezed
class ConversationsState with _$ConversationsState {
  factory ConversationsState({
    @Default(<Conversation>[]) List<Conversation> conversations,
    @Default('') String displayName,
    @Default('') String avatarPath,
    @Default('') String jid,
  }) = _ConversationsState;
}
