import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/helpers.dart';

part 'stickers_bloc.freezed.dart';
part 'stickers_event.dart';
part 'stickers_state.dart';

class StickersBloc extends Bloc<StickersEvent, StickersState> {
  StickersBloc() : super(StickersState()) {
    on<StickerPackRemovedEvent>(_onStickerPackRemoved);
    on<StickerPackImportedEvent>(_onStickerPackImported);
    on<StickerPackAddedEvent>(_onStickerPackAdded);
  }

  Future<void> _onStickerPackRemoved(
    StickerPackRemovedEvent event,
    Emitter<StickersState> emit,
  ) async {
    // TODO
    /*final stickerPack = state.stickerPacks.firstWhereOrNull(
      (StickerPack sp) => sp.id == event.stickerPackId,
    )!;
    final sm = Map<StickerKey, Sticker>.from(state.stickerMap);
    for (final sticker in stickerPack.stickers) {
      sm.remove(StickerKey(stickerPack.id, sticker.id));

      // Evict stickers from the cache
      unawaited(FileImage(File(sticker.fileMetadata.path!)).evict());
    }

    emit(
      state.copyWith(
        stickerPacks: List.from(
          state.stickerPacks.where((sp) => sp.id != event.stickerPackId),
        ),
        stickerMap: sm,
      ),
    );*/

    await MoxplatformPlugin.handler.getDataSender().sendData(
          RemoveStickerPackCommand(
            stickerPackId: event.stickerPackId,
          ),
          awaitable: false,
        );
  }

  Future<void> _onStickerPackImported(
    StickerPackImportedEvent event,
    Emitter<StickersState> emit,
  ) async {
    final pickerResult = await safePickFiles(
      FileType.any,
      allowMultiple: false,
    );
    if (pickerResult == null) return;

    emit(
      state.copyWith(
        isImportRunning: true,
      ),
    );

    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          ImportStickerPackCommand(
            path: pickerResult.files.single.path!,
          ),
        );

    if (result is StickerPackImportSuccessEvent) {
      /*final sm = Map<StickerKey, Sticker>.from(state.stickerMap);
      for (final sticker in result.stickerPack.stickers) {
        if (!sticker.isImage) continue;

        sm[StickerKey(result.stickerPack.id, sticker.id)] = sticker;
      }
      emit(
        state.copyWith(
          stickerPacks: List<StickerPack>.from([
            ...state.stickerPacks,
            result.stickerPack,
          ]),
          stickerMap: sm,
          isImportRunning: false,
        ),
      );*/

      await Fluttertoast.showToast(
        msg: t.pages.settings.stickers.importSuccess,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
    } else {
      emit(
        state.copyWith(
          isImportRunning: false,
        ),
      );

      await Fluttertoast.showToast(
        msg: t.pages.settings.stickers.importFailure,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  Future<void> _onStickerPackAdded(
    StickerPackAddedEvent event,
    Emitter<StickersState> emit,
  ) async {
    /*final sm = Map<StickerKey, Sticker>.from(state.stickerMap);
    for (final sticker in event.stickerPack.stickers) {
      if (!sticker.isImage) continue;

      sm[StickerKey(event.stickerPack.id, sticker.id)] = sticker;
    }

    emit(
      state.copyWith(
        stickerPacks: List<StickerPack>.from([
          ...state.stickerPacks,
          event.stickerPack,
        ]),
        stickerMap: sm,
      ),
    );
    */
  }
}
