import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/message/base.dart';
import 'package:moxxyv2/ui/widgets/chat/message/file.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';

class ImageChatWidget extends StatelessWidget {
  const ImageChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent, {
    super.key,
  });
  final Message message;
  final BorderRadius radius;
  final double maxWidth;
  final bool sent;

  Widget _buildUploading() {
    return MediaBaseChatWidget(
      Image.file(File(message.fileMetadata!.path!)),
      MessageBubbleBottom(message, sent),
      radius,
      extra: ProgressWidget(message.id),
    );
  }

  Widget _buildDownloading() {
    if (message.fileMetadata!.thumbnailData != null) {
      final size = getMediaSize(message, maxWidth);

      return MediaBaseChatWidget(
        SizedBox(
          width: size.width,
          height: size.height,
          child: BlurHash(
            hash: message.fileMetadata!.thumbnailData!,
            decodingWidth: size.width.toInt(),
            decodingHeight: size.height.toInt(),
          ),
        ),
        MessageBubbleBottom(message, sent),
        radius,
        extra: ProgressWidget(message.id),
      );
    } else {
      return FileChatBaseWidget(
        message,
        message.fileMetadata!.filename,
        radius,
        maxWidth,
        sent,
        mimeType: message.fileMetadata!.mimeType,
        downloadButton: ProgressWidget(message.id),
      );
    }
  }

  /// The image exists locally
  Widget _buildImage() {
    final size = getMediaSize(message, maxWidth);

    Widget image;
    if (message.fileMetadata!.width != null &&
        message.fileMetadata!.height != null) {
      image = SizedBox(
        width: size.width,
        height: size.height,
        child: Image.file(
          File(message.fileMetadata!.path!),
          cacheWidth: size.width.toInt(),
          cacheHeight: size.height.toInt(),
        ),
      );
    } else {
      // TODO(Unknown): Somehow have sensible defaults here
      image = Image.file(
        File(message.fileMetadata!.path!),
        // cacheWidth: size.width.toInt(),
        // cacheHeight: size.height.toInt(),
      );
    }

    return MediaBaseChatWidget(
      image,
      MessageBubbleBottom(
        message,
        sent,
      ),
      radius,
      onTap: () => openFile(message.fileMetadata!.path!),
    );
  }

  Widget _buildDownloadable() {
    if (message.fileMetadata!.thumbnailData != null) {
      final size = getMediaSize(message, maxWidth);

      return MediaBaseChatWidget(
        SizedBox(
          width: size.width,
          height: size.height,
          child: BlurHash(
            hash: message.fileMetadata!.thumbnailData!,
            decodingWidth: size.width.toInt(),
            decodingHeight: size.height.toInt(),
          ),
        ),
        MessageBubbleBottom(message, sent),
        radius,
        extra: DownloadButton(
          onPressed: () => requestMediaDownload(message),
        ),
      );
    } else {
      return FileChatBaseWidget(
        message,
        message.fileMetadata!.filename,
        radius,
        maxWidth,
        sent,
        mimeType: message.fileMetadata!.mimeType,
        downloadButton: DownloadButton(
          onPressed: () {
            MoxplatformPlugin.handler.getDataSender().sendData(
                  RequestDownloadCommand(message: message),
                  awaitable: false,
                );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUploading) {
      return _buildUploading();
    }
    if (message.isFileUploadNotification || message.isDownloading) {
      return _buildDownloading();
    }

    // TODO(PapaTutuWawa): Maybe use an async builder
    if (message.fileMetadata!.path != null &&
        File(message.fileMetadata!.path!).existsSync()) {
      return _buildImage();
    }

    return _buildDownloadable();
  }
}
