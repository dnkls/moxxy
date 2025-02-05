import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/startchat_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/button.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class StartChatPage extends StatefulWidget {
  const StartChatPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (_) => const StartChatPage(),
        settings: const RouteSettings(
          name: addContactRoute,
        ),
      );

  @override
  StartChatPageState createState() => StartChatPageState();
}

class StartChatPageState extends State<StartChatPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartChatBloc, StartChatState>(
      builder: (context, state) => WillPopScope(
        onWillPop: () async {
          if (state.isWorking) {
            return false;
          }

          context.read<StartChatBloc>().add(
                PageResetEvent(),
              );
          return true;
        },
        child: Scaffold(
          appBar: BorderlessTopbar.title(t.pages.startchat.title),
          body: Column(
            children: [
              Visibility(
                visible: state.isWorking,
                child: const LinearProgressIndicator(),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: CustomTextField(
                  labelText: t.pages.startchat.xmppAddress,
                  onChanged: (value) => context.read<StartChatBloc>().add(
                        JidChangedEvent(value),
                      ),
                  controller: _controller,
                  enabled: !state.isWorking,
                  cornerRadius: textfieldRadiusRegular,
                  borderColor: primaryColor,
                  borderWidth: 1,
                  errorText: state.jidError,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: () async {
                      final jid = await scanXmppUriQrCode(context);
                      if (jid == null) return;

                      _controller.text = jid.path;
                      // ignore: use_build_context_synchronously
                      context.read<StartChatBloc>().add(
                            JidChangedEvent(jid.path),
                          );
                    },
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 8)),
                child: Text(t.pages.startchat.subtitle),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: paddingVeryLarge)
                        .add(const EdgeInsets.only(top: 32)),
                child: Row(
                  children: [
                    Expanded(
                      child: RoundedButton(
                        cornerRadius: 32,
                        onTap: () => context
                            .read<StartChatBloc>()
                            .add(AddedContactEvent()),
                        enabled: !state.isWorking,
                        child: Text(t.pages.startchat.buttonAddToContact),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
