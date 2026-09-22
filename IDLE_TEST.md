# Idle 3종 테스트

Godot 4.7.2에서 오른쪽 3/4 방향 Idle 3종을 원본 크기로 비교하는 최소 씬이다.

## 실행과 조작

1. 이 폴더의 `project.godot`을 Godot 4.7.2로 연다.
2. 에셋 가져오기가 끝나면 F5로 실행한다. Main Scene은 `scenes/main.tscn`이다.
3. 현재 씬만 실행하려면 `scenes/main.tscn`을 열고 F6을 누른다.
4. 실행 화면을 클릭해 키보드 포커스를 준 뒤 1 / 2 / 3을 누른다. 숫자 키패드도 지원한다.

| 키 | 애니메이션 | 자세 |
|---|---|---|
| 1 | `idle_default` | 양팔을 내린 기본 자세 |
| 2 | `idle_pockets` | 주머니에 손을 넣은 자세 |
| 3 | `idle_arms_crossed` | 팔짱을 낀 자세 |

실행하면 `idle_default`가 시작된다. 같은 키를 다시 눌러도 1번 프레임부터 재생한다. 키를 누른 채 유지할 때 발생하는 반복 입력은 무시한다. 자세 사이의 전환 애니메이션은 없다.

## 씬과 표시 기준

```text
Main (Node2D, scripts/main.gd)
├─ Bongbong (AnimatedSprite2D, scenes/idle_frames.tres)
└─ Help (Label)
```

- 창/뷰포트: 640×400, stretch 비활성화, 창 크기 고정.
- Sprite: scale `(1, 1)`, Nearest, `centered=false`. 192×192 전체 PNG를 그대로 사용한다.
- 공통 원본 발 기준점 `(95, 174)`을 화면 `(320, 320)`에 놓는다. Sprite offset은 `(-95, -174)`이다.
- 사각형은 원본 캔버스 영역, 가로선은 발 기준선, 세로선은 공통 중심축이다. Main이 선만 그리며 추가 노드는 없다.
- 18개 PNG의 Import 설정은 lossless, mipmap 생성 비활성화, size limit 0이다.
- Godot 에디터의 내장 실행 화면을 확대·축소하면 화면 미리보기 배율이 달라질 수 있다. 픽셀 검수는 100% 배율이나 별도 실행 창에서 한다.

## 확인한 원본 에셋

아래 경로는 프로젝트 루트 기준이다. 각 폴더의 `manifest.json`과 `.aseprite` 프레임 지속시간을 서로 대조했다.

| 애니메이션 | 폴더 | 사용 PNG |
|---|---|---|
| `idle_default` | `assets/character/idle/default_three_quarter_right/` | `idle_default_three_quarter_right_01.png` ~ `_06.png` |
| `idle_pockets` | `assets/character/idle/pockets_three_quarter_right/` | `idle_pockets_three_quarter_right_01.png` ~ `_06.png` |
| `idle_arms_crossed` | `assets/character/idle/arms_crossed_three_quarter_right/` | `idle_arms_crossed_three_quarter_right_01.png` ~ `_06.png` |

각각 192×192 RGBA PNG 6장이다. 같은 이름의 가로 1152×192 SpriteSheet, 6프레임 `.aseprite`, 미리보기 GIF도 존재한다. 이번 씬은 개별 PNG를 01→06 순서로 사용한다. 시트의 각 칸과 개별 PNG가 같은 픽셀인지도 확인했다. 상위 `idle/manifest.json`은 정면 에셋 정보이므로 이번 구성에는 사용하지 않는다.

## SpriteFrames와 시간

세 애니메이션 모두 6프레임, 기준 FPS 2.0, 순방향 Loop이다. 동일한 0.5초씩 재생하는 것이 아니라 각 프레임의 상대 duration으로 제작 당시 시간을 보존한다. `duration = 원본 밀리초 / 500`이며 실제 재생 초는 `duration / FPS`이다. 임의의 임시 속도는 사용하지 않았다.

| 애니메이션 | 01→06 지속시간(ms) | 한 바퀴 |
|---|---|---|
| `idle_default` | 600, 400, 500, 450, 450, 600 | 3.0초 |
| `idle_pockets` | 750, 500, 450, 650, 550, 700 | 3.6초 |
| `idle_arms_crossed` | 650, 450, 500, 600, 450, 650 | 3.3초 |

호흡 단계는 `0, 1, 2, 2, 1, 0`이다. 3·4번은 같은 정점 자세를 유지하고, 6→1도 같은 이미지다. 중복 프레임을 자동 제거하거나 시간을 균등화하지 않았다.

공식 API: [SpriteFrames의 프레임 duration과 FPS](https://docs.godotengine.org/en/latest/classes/class_spriteframes.html).

## 검수 결과와 직접 확인할 점

2026-09-23, 실제 Godot `4.7.2.stable.official.ed1daf0bf`에서 확인했다.

- Windows / D3D12 / Forward+ 창을 렌더링하고 3종의 화면을 캡처해 확인했다.
- 실제 씬의 키 입력 경로로 1→2→3→1 전환, 안내 문구 갱신, 같은 키로 처음부터 재시작을 확인했다.
- 각 애니메이션의 여섯 프레임 진행과 한 바퀴 반복, manifest 및 Aseprite 원본 지속시간 일치를 확인했다.
- 세 자세의 대응 프레임에서 머리·얼굴 영역(y=0~111)이 픽셀 단위로 일치한다. 발 영역(y=160~191)은 18프레임 모두 같다. 육안으로 몸통이 다른 방향으로 돌아서는 문제는 보이지 않았다.
- 모든 프레임의 가로 범위는 x=44~145, 발바닥 최하단은 y=173이다. 1·2·5·6번의 머리 최상단은 y=18, 3·4번은 y=17이다. 원본 호흡에 포함된 1px 상승이며 발은 고정되어 있다.
- 세 애니메이션 모두 6번과 1번의 전체 픽셀이 같다. 루프 연결부에서 별도의 위치 튐은 없다.
- PNG / Aseprite / GIF / manifest 파일은 수정하지 않았다.

직접 실행할 때에는 기준선에 발이 붙어 있는지, 얼굴 방향·머리 크기·몸통 실루엣이 자연스러운지, 3~3.6초의 호흡 속도가 적절한지 확인한다. 특히 팔짱→기본 전환에서 팔을 포함한 폭의 변화가 과하게 느껴지는지 살펴본다.

호흡 3·4번 프레임 중 다른 자세로 전환하면 새 자세의 1번 프레임으로 돌아가므로 머리가 1px 내려갈 수 있다. 이는 현재 요청한 즉시 전환/처음부터 재생 방식의 결과다. 이미지 오류로 판단해 고치거나 호흡 위상 동기화를 추가하지 않았다.

## 실행 환경과 Git

코드·리소스 검증은 통과했다. 자동 검증 환경에서는 Windows 인증서 저장소 읽기와 사용자 폴더의 셰이더 캐시 생성 권한 관련 엔진 메시지가 발생했지만 렌더링·입력·재생 검사는 완료됐다. Headless 에디터의 Import 종료 시 사용자 전역 editor_settings 저장 권한 오류도 있었다. 사용자 환경 설정이나 인증서 설정은 변경하지 않았다.

검증용 스크립트·로그·화면 캡처는 기존 `.gitignore`가 제외하는 `.godot/idle_test/`에 보관했다. `.godot/`은 커밋하지 않는다. 반면 Godot이 생성한 PNG 옆 `.import` 설정과 GDScript `.uid` 파일은 프로젝트와 함께 버전 관리할 파일이다. `.gitignore` 변경은 없다.
