import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/media.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';

class QuotedVideoWidget extends StatelessWidget {
  const QuotedVideoWidget(
    this.message,
    this.sent, {
      this.resetQuote,
      super.key,
    }
  );
  final Message message;
  final bool sent;
  final void Function()? resetQuote;

  @override
  Widget build(BuildContext context) {
    return QuotedMediaBaseWidget(
      message,
      SharedVideoWidget(
        message.mediaUrl!,
        message.conversationJid,
        size: 48,
        borderRadius: 8,
      ),
      'Video',
      sent,
      resetQuote: resetQuote,
    );
  }
}
