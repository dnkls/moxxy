import "package:flutter/material.dart";

class PlayButton extends StatelessWidget {
  final double size;
  const PlayButton({
      Key? key,
      this.size = 64.0
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black45
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.play_arrow,
          size: size
        )
      )
    );
  }
}
