import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/gradient.dart';

/// A base container allowing to embed a child in a borderless ChatBubble. If onTap is
/// set, then it will be called as soon as the bubble is tapped. If extra is set, then
/// it will be put on top of the bubble in the center.
class MediaBaseChatWidget extends StatelessWidget {
  const MediaBaseChatWidget(
    this.background,
    this.bottom,
    this.radius, {
    this.onTap,
    this.extra,
    this.gradient = true,
    super.key,
  });
  final Widget background;
  final Widget? extra;
  final MessageBubbleBottom bottom;
  final BorderRadius radius;
  final void Function()? onTap;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: radius,
          child: background,
        ),
        if (gradient) BottomGradient(radius),
        if (extra != null) extra!,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3, right: 6),
            child: bottom,
          ),
        ),
      ],
    );

    return IntrinsicWidth(
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: content,
            )
          : content,
    );
  }
}
