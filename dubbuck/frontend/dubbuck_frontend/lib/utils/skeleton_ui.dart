import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';

class SkeletonUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SkeletonListView(
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.all(8.0),
        child: SkeletonItem(
          child: Row(
            children: <Widget>[
              SkeletonAvatar(style: SkeletonAvatarStyle(width: 60, height: 60)),
              SizedBox(width: 10),
              Expanded(
                child: SkeletonParagraph(
                  style: SkeletonParagraphStyle(
                    lines: 3,
                    spacing: 6,
                    lineStyle: SkeletonLineStyle(randomLength: true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
