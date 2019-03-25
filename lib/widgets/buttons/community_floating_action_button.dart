import 'package:Openbook/models/community.dart';
import 'package:Openbook/provider.dart';
import 'package:Openbook/services/theme_value_parser.dart';
import 'package:Openbook/widgets/buttons/button.dart';
import 'package:Openbook/widgets/buttons/floating_action_button.dart';
import 'package:Openbook/widgets/icon.dart';
import 'package:flutter/material.dart';

class OBCommunityNewPostButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDisabled;
  final bool isLoading;
  final Color textColor;
  final OBButtonSize size;
  final double minWidth;
  final EdgeInsets padding;
  final OBButtonType type;
  final Community community;

  const OBCommunityNewPostButton(
      {this.type = OBButtonType.primary,
      this.size = OBButtonSize.medium,
      this.textColor = Colors.white,
      this.isDisabled = false,
      this.isLoading = false,
      this.padding,
      this.minWidth,
      this.community,
      this.onPressed});

  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: community.updateSubject,
      builder: (BuildContext context, AsyncSnapshot<Community> snapshot) {
        Community community = snapshot.data;

        if (community == null) return const SizedBox();

        String communityHexColor = community.color;
        OpenbookProviderState openbookProviderState =
            OpenbookProvider.of(context);
        ThemeValueParserService themeValueParserService =
            openbookProviderState.themeValueParserService;

        Color communityColor =
            themeValueParserService.parseColor(communityHexColor);
        Color textColor = themeValueParserService.isDarkColor(communityColor)
            ? Colors.white
            : Colors.black;

        return OBFloatingActionButton(
            color: communityColor,
            textColor: textColor,
            onPressed: () async {
              OpenbookProviderState openbookProvider =
                  OpenbookProvider.of(context);
              openbookProvider.modalService
                  .openCreatePost(context: context, community: community);
            },
            child: OBIcon(OBIcons.createPost,
                size: OBIconSize.large, color: textColor));
      },
    );
  }
}
