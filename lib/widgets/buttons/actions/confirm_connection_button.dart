import 'package:Openbook/models/circle.dart';
import 'package:Openbook/models/user.dart';
import 'package:Openbook/provider.dart';
import 'package:Openbook/services/bottom_sheet.dart';
import 'package:Openbook/services/httpie.dart';
import 'package:Openbook/services/toast.dart';
import 'package:Openbook/services/user.dart';
import 'package:Openbook/widgets/buttons/button.dart';
import 'package:flutter/material.dart';

class OBConfirmConnectionButton extends StatefulWidget {
  final User user;

  OBConfirmConnectionButton(this.user);

  @override
  OBConfirmConnectionButtonState createState() {
    return OBConfirmConnectionButtonState();
  }
}

class OBConfirmConnectionButtonState extends State<OBConfirmConnectionButton> {
  UserService _userService;
  ToastService _toastService;
  BottomSheetService _bottomSheetService;
  bool _requestInProgress;

  @override
  void initState() {
    super.initState();
    _requestInProgress = false;
  }

  @override
  Widget build(BuildContext context) {
    var openbookProvider = OpenbookProvider.of(context);
    _userService = openbookProvider.userService;
    _toastService = openbookProvider.toastService;
    _bottomSheetService = openbookProvider.bottomSheetService;

    return StreamBuilder(
      stream: widget.user.updateSubject,
      initialData: widget.user,
      builder: (BuildContext context, AsyncSnapshot<User> snapshot) {
        var user = snapshot.data;

        if (user?.isPendingConnectionConfirmation == null || !user.isConnected)
          return const SizedBox();

        return user.isPendingConnectionConfirmation
            ? _buildConfirmConnectionButton()
            : _buildDisconnectButton();
      },
    );
  }

  Widget _buildConfirmConnectionButton() {
    return OBButton(
      child: Text(
        'Confirm',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      isLoading: _requestInProgress,
      onPressed: _onWantsToConnectWithUser,
      type: OBButtonType.success,
    );
  }

  Widget _buildDisconnectButton() {
    return OBButton(
      child: Text(
        'Disconnect',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      isLoading: _requestInProgress,
      onPressed: _disconnectFromUser,
      type: OBButtonType.danger,
    );
  }

  void _onWantsToConnectWithUser() {
    _bottomSheetService.showConnectionsCirclesPicker(
        context: context,
        title: 'Confirm connection',
        actionLabel: 'Connect',
        onPickedCircles: _confirmConnectionWithUser);
  }

  Future _confirmConnectionWithUser(List<Circle> circles) async {
    if (_requestInProgress) return;
    _setRequestInProgress(true);
    try {
      await _userService.confirmConnectionWithUserWithUsername(
          widget.user.username,
          circles: circles);
      if (!widget.user.isFollowing) widget.user.incrementFollowersCount();
      _toastService.success(message: 'Connection confirmed', context: context);
    } on HttpieConnectionRefusedError {
      _toastService.error(message: 'No internet connection', context: context);
    } catch (e) {
      _toastService.error(message: 'Unknown error', context: context);
      rethrow;
    } finally {
      _setRequestInProgress(false);
    }
  }

  Future _disconnectFromUser() async {
    if (_requestInProgress) return;
    _setRequestInProgress(true);
    try {
      await _userService.disconnectFromUserWithUsername(widget.user.username);
      widget.user.decrementFollowersCount();
      _toastService.success(
          message: 'Disconnected successfully', context: context);
    } on HttpieConnectionRefusedError {
      _toastService.error(message: 'No internet connection', context: context);
    } catch (e) {
      _toastService.error(message: 'Unknown error', context: context);
    } finally {
      _setRequestInProgress(false);
    }
  }

  void _setRequestInProgress(bool requestInProgress) {
    setState(() {
      _requestInProgress = requestInProgress;
    });
  }
}
