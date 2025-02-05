import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/reactions/list.dart';

/// When the corresponding message contains more than one reaction, this widget will display
/// the preview and open the reaction overview when tapped. If the message has no reactions
/// attached to it, then this widget is equal to a SizedBox.
class ReactionsPreview extends StatelessWidget {
  const ReactionsPreview(this.message, this.sentBySelf, {super.key});

  /// The message to display the reactions of.
  final Message message;

  /// True if [message] was sent by one self. False, if not.
  final bool sentBySelf;

  @override
  Widget build(BuildContext context) {
    if (message.reactionsPreview.isEmpty) {
      return const SizedBox();
    }

    return InkWell(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(textfieldRadiusRegular),
            ),
          ),
          builder: (context) {
            return ReactionList(
              message.id,
            );
          },
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: reactionColorReceived.withOpacity(0.65),
          borderRadius: BorderRadius.only(
            topLeft: sentBySelf ? const Radius.circular(40) : Radius.zero,
            topRight: sentBySelf ? Radius.zero : const Radius.circular(40),
            bottomLeft: const Radius.circular(40),
            bottomRight: const Radius.circular(40),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 4,
            left: 10,
            right: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Only show 5 reactions. The last one is just for indicating that
                // there are more reactions.
                message.reactionsPreview.length == 6
                    ? message.reactionsPreview.sublist(0, 5).join(' ')
                    : message.reactionsPreview.join(' '),
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
              if (message.reactionsPreview.length == 6)
                const Padding(
                  padding: EdgeInsets.only(
                    left: 8,
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
