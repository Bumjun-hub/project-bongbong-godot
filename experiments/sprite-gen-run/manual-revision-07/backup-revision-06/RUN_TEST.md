# SD Run — 새 팔·다리 동작 (revision 6)

확정된 Run의 머리, 안경, 웃는 얼굴, 빨간 옷과 색을 기준으로 8프레임 달리기 동작을 새로 구성했다. 팔과 발끝의 위치를 프레임마다 조절하고, 4번 공중 자세 뒤의 중복 도약 자세를 5번 착지 자세로 바꿨다. 흐릿하게 겹치던 6번 뒷신발은 깨끗한 원본 신발 포즈로 다시 조합했다. 프레임마다 따로 떠 있던 파란 속도선은 제거했다.

GPT로 만든 8칸 후보에는 반복 포즈와 어깨 색 번짐이 있어 게임 에셋으로 채택하지 않았다. 실제 게임 그림은 기존 Run 픽셀을 기준으로 가장자리와 색을 보존해 조정한 결과다. 수정 전 5판의 파일은 `experiments/sprite-gen-run/manual-revision-06/backup-revision-05/`에 있다.

## Godot에서 확인

F5로 실행한 뒤 게임 창에 포커스를 준다.

| 조작 | 동작 |
|---|---|
| Shift + ← / → | 달리기 |
| Shift 놓기 | 걷기로 전환 |
| 방향키 놓기 | 대기 자세 |
| 5 | 자동 왕복 달리기 토글 |
| 4 | 자동 왕복 걷기 토글 |
| F1 | 검수 배경과 기준선 |
| Esc | 종료 |

Run 이동 속도는 기존 **144px/s**다. 192×192 캔버스와 `(95,174)` 기준축을 유지했다. 8프레임의 재생 시간은 **80, 60, 60, 80, 80, 60, 60, 80ms**, 합계 **560ms**다. 길게 보이는 1·5번은 착지, 4번은 공중 자세다.

## 파일

- Godot에서 읽는 파일: `assets/character/run/right_three_quarter/run_01.png`부터 `run_08.png`, `scenes/run_frames.tres`
- 편집 원본: `assets/character/run/right_three_quarter/run_cycle_8.aseprite`
- 가로 시트: `assets/character/run/right_three_quarter/run_cycle_8.png`
- 재생 미리보기: `assets/character/run/right_three_quarter/run_cycle_8_preview.gif`
- 느린 미리보기: `assets/character/run/right_three_quarter/run_cycle_8_slow.gif`
- 전체 자세: `assets/character/run/right_three_quarter/run_contact_sheet.png`
- `run_laugh_speed_*`, `run_speed_effect_*`, `run_crossover_*`는 이전 시도 기록이며 현재 Godot 재생 파일이 아니다.

## 확인 결과

- Aseprite에서 저장한 가로 시트의 8개 프레임이 개별 PNG와 픽셀 단위로 일치한다.
- Aseprite GIF의 각 프레임 시간이 위 8개 값과 일치한다.
- Godot 4.7.2의 에셋 가져오기와 `res://scenes/run_frames.tres` 로드에 성공했다. 가져온 텍스처와 PNG의 모든 픽셀, 8프레임의 시간, 총 560ms를 검사했다.
- 검수 코드는 `.godot/run_work/verify_run_v6.gd`에 있다. Godot가 이 환경에서 사용자 로그와 Windows 인증서 저장소에 관한 오류를 출력했지만, 위 에셋 검사는 성공했다.

발 미끄러짐과 팔 스윙의 느낌은 Godot에서 `5`를 눌러 자동 달리기로도 확인할 수 있다.
