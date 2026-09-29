# Walk 애니메이션

## 현재 적용: Grok 차분한 오른쪽 걷기

- 재생 리소스: `scenes/walk_frames.tres`
- 최종 프레임: `assets/character/detail_matched_motions/walk/frame_01.png` ~ `frame_24.png`
- 편집 원본: `assets/character/detail_matched_motions/walk/walk.aseprite`
- 미리보기: `assets/character/detail_matched_motions/walk/walk.gif`
- 검증: `experiments/sprite-gen-walk/grok-walk-02/verify_godot.gd`

24프레임을 24fps로 재생하며 한 바퀴는 1초다. 현재 이동 속도는 60px/s다. 오른쪽 3/4 방향 원본을 왼쪽으로 이동할 때 좌우 반전한다.

Grok 원본의 머리·턱·목·몸통을 한 장면으로 유지하고, 최종 프레임은 Idle과 같은 192×192 캔버스 및 `(95,174)` 발 기준을 사용한다. 머리와 몸을 따로 움직이지 않는다. `←/→`로 걷고, `4`로 자동 왕복 걷기를 켜거나 끈다. 멈추면 기본 Idle로 돌아간다.

2026-09-27에 사용하지 않는 이전 프레임과 생성 중간물을 정리했다. 현재 프레임과 Aseprite 원본, 시트·GIF 미리보기는 유지한다. 제작 기록의 이전 입력 파일을 사용하는 검증은 중간물 재생성이 필요하다.
