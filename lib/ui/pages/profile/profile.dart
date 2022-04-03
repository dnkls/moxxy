import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/sharedmedia.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/bloc/profile_bloc.dart";
import "package:moxxyv2/ui/pages/profile/selfheader.dart";
import "package:moxxyv2/ui/pages/profile/conversationheader.dart";
import "package:moxxyv2/shared/models/conversation.dart";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ProfilePage extends StatelessWidget {
  const ProfilePage({ Key? key }) : super(key: key);

  Widget _buildHeader(ProfileState state) {
    if (state.isSelfProfile) {
      return SelfProfileHeader(
        state.jid,
        state.avatarUrl,
        state.displayName
      );
    }

    return ConversationProfileHeader(state.conversation!);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) => Stack(
            alignment: Alignment.center,
            children: [
              ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: _buildHeader(state)
                  ),
                  // TODO: Maybe don't show this conditionally but always
                  Visibility(
                    visible: !state.isSelfProfile && state.conversation!.sharedMedia.isNotEmpty,
                    child: state.isSelfProfile ? const SizedBox() : SharedMediaDisplay(
                      state.conversation!.sharedMedia
                    )
                  )
                ]
              ),
              const Positioned(
                top: 8.0,
                left: 8.0,
                child: BackButton()
              )
            ]
          )
        )
      )
    );
  }
}
