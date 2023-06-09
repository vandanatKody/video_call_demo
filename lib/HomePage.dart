import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_call_demo/login_service.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'constant.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController singleInviteeUserIDTextCtrl =
  TextEditingController();
  final TextEditingController groupInviteeUserIDsTextCtrl =
  TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: 10,
                child: logoutButton(),
              ),
              Positioned(
                top: 50,
                left: 10,
                child: Text('Your Phone Number: ${currentUser.id}'),
              ),
              userListView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget logoutButton() {
    return Ink(
      width: 35,
      height: 35,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.redAccent,
      ),
      child: IconButton(
        icon: const Icon(Icons.exit_to_app_sharp),
        iconSize: 20,
        color: Colors.white,
        onPressed: () {
          logout().then((value) {
            onUserLogout();

            Navigator.pushNamed(
              context,
              PageRouteNames.login,
            );
          });
        },
      ),
    );
  }

  Widget userListView() {

    return Center(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 1,
        itemBuilder: (context, index) {
          late TextEditingController inviteeUsersIDTextCtrl;
          late List<Widget> userInfo;

          inviteeUsersIDTextCtrl = singleInviteeUserIDTextCtrl;
          userInfo = [
            const Text('invitee name ('),
            InviteeIDFormField(
              textCtrl: inviteeUsersIDTextCtrl,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9,]')),
              ],
              labelText: "invitee ID",
              hintText: "plz enter invitee ID",
            ),
            const Text(')'),
          ];
          return Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 20),
                  ...userInfo,
                  Expanded(child: Container()),
                  SendCallButton(
                    isVideoCall: false,
                    inviteeUsersIDTextCtrl: inviteeUsersIDTextCtrl,
                    onCallFinished: onSendCallInvitationFinished,
                  ),
                  SendCallButton(
                    isVideoCall: true,
                    inviteeUsersIDTextCtrl: inviteeUsersIDTextCtrl,
                    onCallFinished: onSendCallInvitationFinished,
                  ),
                  const SizedBox(width: 20),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: Divider(height: 1.0, color: Colors.grey),
              ),
            ],
          );
        },
      ),
    );
  }

  void onSendCallInvitationFinished(
      String code,
      String message,
      List<String> errorInvitees,
      ) {
    if (errorInvitees.isNotEmpty) {
      String userIDs = "";
      for (int index = 0; index < errorInvitees.length; index++) {
        if (index >= 5) {
          userIDs += '... ';
          break;
        }

        var userID = errorInvitees.elementAt(index);
        userIDs += userID + ' ';
      }
      if (userIDs.isNotEmpty) {
        userIDs = userIDs.substring(0, userIDs.length - 1);
      }

      var message = 'User doesn\'t exist or is offline: $userIDs';
      if (code.isNotEmpty) {
        message += ', code: $code, message:$message';
      }
      showToast(
        message,
        position: StyledToastPosition.top,
        context: context,
      );
    } else if (code.isNotEmpty) {
      showToast(
        'code: $code, message:$message',
        position: StyledToastPosition.top,
        context: context,
      );
    }
  }
}

Widget InviteeIDFormField({
  required TextEditingController textCtrl,
  List<TextInputFormatter>? formatters,
  String hintText = '',
  String labelText = '',
}) {
  const textStyle = TextStyle(fontSize: 12.0);
  return Expanded(
    flex: 100,
    child: SizedBox(
      height: 30,
      child: TextFormField(
        style: textStyle,
        controller: textCtrl,
        inputFormatters: formatters,
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: textStyle,
          labelText: labelText,
          labelStyle: textStyle,
          border: const OutlineInputBorder(),
        ),
      ),
    ),
  );
}

Widget SendCallButton({
  required bool isVideoCall,
  required TextEditingController inviteeUsersIDTextCtrl,
  void Function(String code, String message, List<String>)? onCallFinished,
}) {
  return ValueListenableBuilder<TextEditingValue>(
    valueListenable: inviteeUsersIDTextCtrl,
    builder: (context, inviteeUserID, _) {
      var invitees = getInvitesFromTextCtrl(inviteeUsersIDTextCtrl.text);

      return ZegoSendCallInvitationButton(
        isVideoCall: isVideoCall,
        invitees: invitees,
        resourceID: "zego_data",
        iconSize: const Size(40, 40),
        buttonSize: const Size(50, 50),
        onPressed: onCallFinished,
      );
    },
  );
}

List<ZegoUIKitUser> getInvitesFromTextCtrl(String textCtrlText) {
  List<ZegoUIKitUser> invitees = [];

  var inviteeIDs = textCtrlText.trim().replaceAll('，', '');
  inviteeIDs.split(",").forEach((inviteeUserID) {
    if (inviteeUserID.isEmpty) {
      return;
    }

    invitees.add(ZegoUIKitUser(
      id: inviteeUserID,
      name: 'user_$inviteeUserID',
    ));
  });

  return invitees;
}