# 부드러운 IDLE 비교 후보

- 목적: 기존 IDLE보다 외곽선과 명암 경계를 부드럽게 했을 때 RUN / DRAG와 어울리는지 확인하는 단일 프레임 시안.
- 원본: `assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png`
- 후보: `idle_soft_01.png` (192×192, RGBA 투명 배경)
- 편집용: `idle_soft_01.aseprite`
- 비교: `comparison.png` — 왼쪽부터 원본 IDLE / 부드러운 후보 / Light Run / DRAG.
- 생성 원본: `idle_soft_generated.png` — 원본 IDLE을 참조해 이미지 편집 도구로 생성.
- Aseprite MCP에서 미세한 배경 잔여 알파를 제외하고 축소, 원본과 동일한 캐릭터 경계 (44,18)–(146,174) 및 발 위치에 정렬.
- 원본과 같은 자세와 비율을 목표로 한 시안이며 재생성에 따른 작은 선·색 차이가 있음.
- 기존 IDLE 파일 및 Godot 리소스는 변경하지 않음. 전체 IDLE 애니메이션 적용 전 비교용.

검증: 192×192 크기와 투명 배경 확인, 어두운 배경에서 비교 이미지 확인. 원본 PNG SHA256: 36458D21FCE150D0B48BBF19CDE26F7C5DA4957BF2322A28A7B2A9E8328B3761.

## 적용 완료 (2026-09-25)

사용자 승인 후 기본·주머니·팔짱 세 애니메이션을 `assets/character/idle/soft_three_quarter_right/`로 만들고 `scenes/idle_frames.tres`에 연결했다. 위의 미적용 표기는 최초 시안 단계 기록이다. 기존 자산은 보존했다.

`motion_maps.json`은 기존 18프레임을 정확히 재현하는 행 이동과 프레임 시간이며, `apply_soft_idle.lua`로 Aseprite에서 승인 후보에 호흡을 적용한다. 주머니·팔짱은 같은 후보의 머리와 신발을 사용하고 기존 자세의 몸통을 부드럽게 처리한다. 세 자세의 머리 픽셀 동일, 1=6 / 2=5 / 3=4 프레임 동일, 기본 1번이 승인 PNG와 동일함을 검증했다.

Godot 검증: `verify_godot.gd` 통과. 18개 텍스처의 로드 및 192×192 크기, 기존 3.0/3.6/3.3초 반복 시간, 실제 Main 씬에서 새 텍스처 사용을 확인했다.
