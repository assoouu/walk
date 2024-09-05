import 'package:flutter/material.dart';

class RankingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 여기에 랭킹 정보를 불러오는 로직을 구현합니다.
    return ListView.builder(
      itemCount: 20, // 예시 데이터의 수
      itemBuilder: (context, index) {
        int rank = index + 1; // 순위
        String rankImage = rank <= 10 ? 'assets/ranking/place$rank.gif' : 'assets/ranking/default_place.gif'; // 랭킹 이미지 경로
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Row(
            children: [
              Image.asset(
                rankImage,
                width: 24,
                height: 24,
              ),
              SizedBox(width: 8), // 이미지와 텍스트 사이의 간격 조정
              Text('사용자 이름 $index'),
            ],
          ),
          subtitle: Text('추가 정보, 예: 사용자 점수'),
        );
      },
    );
  }
}
