import 'dart:async';

import 'package:Openbook/models/community.dart';
import 'package:Openbook/models/user.dart';
import 'package:Openbook/models/users_list.dart';
import 'package:Openbook/services/modal_service.dart';
import 'package:Openbook/services/navigation_service.dart';
import 'package:Openbook/services/toast.dart';
import 'package:Openbook/widgets/http_list.dart';
import 'package:Openbook/widgets/icon.dart';
import 'package:Openbook/widgets/icon_button.dart';
import 'package:Openbook/widgets/nav_bars/themed_nav_bar.dart';
import 'package:Openbook/widgets/page_scaffold.dart';
import 'package:Openbook/provider.dart';
import 'package:Openbook/services/user.dart';
import 'package:Openbook/widgets/theming/primary_color_container.dart';
import 'package:Openbook/widgets/theming/text.dart';
import 'package:Openbook/widgets/tiles/user_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OBCommunityBannedUsersPage extends StatefulWidget {
  final Community community;

  const OBCommunityBannedUsersPage({Key key, @required this.community})
      : super(key: key);

  @override
  State<OBCommunityBannedUsersPage> createState() {
    return OBCommunityBannedUsersPageState();
  }
}

class OBCommunityBannedUsersPageState
    extends State<OBCommunityBannedUsersPage> {
  UserService _userService;
  ModalService _modalService;
  NavigationService _navigationService;
  ToastService _toastService;

  OBHttpListController _httpListController;
  bool _needsBootstrap;

  @override
  void initState() {
    super.initState();
    _httpListController = OBHttpListController();
    _needsBootstrap = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_needsBootstrap) {
      var provider = OpenbookProvider.of(context);
      _userService = provider.userService;
      _modalService = provider.modalService;
      _navigationService = provider.navigationService;
      _toastService = provider.toastService;
      _needsBootstrap = false;
    }

    return OBCupertinoPageScaffold(
      navigationBar: OBThemedNavigationBar(
        title: 'Banned users',
        trailing: OBIconButton(
          OBIcons.add,
          themeColor: OBIconThemeColor.primaryAccent,
          onPressed: _onWantsToAddNewBannedUser,
        ),
      ),
      child: OBPrimaryColorContainer(
        child: OBHttpList<User>(
          controller: _httpListController,
          listItemBuilder: _buildCommunityBannedUserListItem,
          searchResultListItemBuilder: _buildCommunityBannedUserListItem,
          listRefresher: _refreshCommunityBannedUsers,
          listOnScrollLoader: _loadMoreCommunityBannedUsers,
          listSearcher: _searchCommunityBannedUsers,
          resourceSingularName: 'banned user',
          resourcePluralName: 'banned users',
        ),
      ),
    );
  }

  Widget _buildCommunityBannedUserListItem(BuildContext context, User user) {
    bool isLoggedInUser = _userService.isLoggedInUser(user);

    return OBUserTile(
      user,
      onUserTilePressed: _onCommunityBannedUserListItemPressed,
      onUserTileDeleted:
          isLoggedInUser ? null : _onCommunityBannedUserListItemDeleted,
      trailing: isLoggedInUser
          ? OBText(
              'You',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          : null,
    );
  }

  void _onCommunityBannedUserListItemPressed(User communityBannedUser) {
    _navigationService.navigateToUserProfile(
        user: communityBannedUser, context: context);
  }

  void _onCommunityBannedUserListItemDeleted(User communityBannedUser) async {
    try {
      await _userService.unbanCommunityUser(
          community: widget.community, user: communityBannedUser);
      _httpListController.removeListItem(communityBannedUser);
    } on HttpieConnectionRefusedError {
      _toastService.error(message: 'No internet connection', context: context);
    } catch (error) {
      _toastService.error(message: 'Unknown error.', context: context);
      rethrow;
    }
  }

  Future<List<User>> _refreshCommunityBannedUsers() async {
    UsersList communityBannedUsers =
        await _userService.getBannedUsersForCommunity(widget.community);
    return communityBannedUsers.users;
  }

  Future<List<User>> _loadMoreCommunityBannedUsers(
      List<User> communityBannedUsersList) async {
    var lastCommunityBannedUser = communityBannedUsersList.last;
    var lastCommunityBannedUserId = lastCommunityBannedUser.id;
    var moreCommunityBannedUsers =
        (await _userService.getBannedUsersForCommunity(
      widget.community,
      maxId: lastCommunityBannedUserId,
      count: 20,
    ))
            .users;
    return moreCommunityBannedUsers;
  }

  Future<List<User>> _searchCommunityBannedUsers(String query) async {
    UsersList results = await _userService.searchCommunityBannedUsers(
        query: query, community: widget.community);

    return results.users;
  }

  void _onWantsToAddNewBannedUser() async {
    User addedCommunityBannedUser = await _modalService.openBanCommunityUser(
        context: context, community: widget.community);

    if (addedCommunityBannedUser != null) {
      _httpListController.insertListItem(addedCommunityBannedUser);
    }
  }
}
