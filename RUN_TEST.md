# Run 애니메이션

## 두 번째 변형: 양팔을 들고 통통 튀는 달리기 (`run_bouncy`)

선택한 세 번째 첫 자세 PNG를 192×192 영상 입력으로 맞춘 뒤 Sprite gen과 Grok 영상 생성으로 새 달리기를 만들었다. 화면 가장자리에 머리가 닿는 원본 구간을 제외하고, 양발이 교대하는 68–95번 연속 28프레임을 사용한다. 몸과 머리가 함께 부드럽게 오르내리고 양팔은 어깨 위에 둔다. 원본은 24fps, 약 1.167초 루프이며 연결 비율은 1.0648로 기준 2.0 이내다. 완전히 같거나 실루엣이 거의 같은 프레임은 없고, 최종 192×192 프레임은 화면 가장자리에 닿지 않는다. 접지 속도는 별도 검증되지 않았다. Idle과 비교해 모든 프레임의 피부색을 맞추고, Aseprite에서 머리의 가로 볼륨을 늘리고 올라간 양팔을 어깨 쪽으로 압축했다. 다리와 바닥 기준은 유지했다. 비율 보정 후 실루엣의 루프 연결 비율은 1.100이다. Godot에서는 다른 동작과 같은 1:1 스케일로 표시한다.

머리 비율을 키울 때 눈과 안경 도트가 함께 늘어난 문제를 수정했다. 눈 중심부는 비율 변경 전의 첫 달리기 픽셀을 28프레임 모두 복원했고, 화면 왼쪽 큰 눈의 7·27번 프레임만 앞뒤 눈꺼풀 선에 맞춰 각각 16px·20px을 정리했다. 다리와 발 위치는 유지했다.

- Godot: `6`으로 자동 왕복하는 새 달리기를 켜거나 끈다. `5`는 기존 가벼운 달리기다. 두 변형 모두 이동 속도 135px/s, 원본 대비 재생 속도 1.25배다. 새 달리기의 화면 재생은 30fps, 한 바퀴 약 0.933초다.
- 편집 원본: `assets/character/run/bouncy_arms_up_01/run_bouncy_01.aseprite`
- PNG 프레임: `assets/character/run/bouncy_arms_up_01/run_01.png`부터 `run_28.png`
- 재생 리소스: `scenes/run_bouncy_frames.tres`
- 미리보기: `assets/character/run/bouncy_arms_up_01/run_bouncy_01_preview.gif`
- 제작·검증 기록: `experiments/sprite-gen-run/grok-bouncy-arms-up-01/`

## 첫 번째 변형: 가볍게 뛰기 (`run_light`)

Grok에서 새로 생성한 6초 영상 중 양발이 교대하는 연속 18프레임(50–67번)을 사용한다. 전체 캐릭터의 원본 동작을 유지하고 모든 프레임을 50ms씩 재생한다. 총 길이는 0.9초이며, 중간 프레임 삭제나 개별 높이 수정은 없다. 자동 선택의 9프레임은 한쪽 걸음만 포함해 제외하고, 시각 검수한 두 걸음 구간을 선택했다. 루프 연결 비율은 1.2603으로 기준 2.0 이내이고 정확한/유사 실루엣 중복은 검출되지 않았다. 접지 속도는 별도 검증되지 않았다.

- Godot: Shift + ←/→ 또는 `5`로 자동 왕복 달리기. 18프레임, 원본 20fps를 1.25배로 재생해 화면에서는 25fps, 이동은 135px/s다.
- 편집 원본: `assets/character/run/light_jog_02/run_light_02.aseprite`
- PNG 프레임: `assets/character/run/light_jog_02/run_01.png`부터 `run_18.png`
- 재생 리소스: `scenes/run_light_frames.tres`
- 미리보기: `assets/character/run/light_jog_02/run_light_02_preview.gif`
- 검증: `experiments/sprite-gen-run/grok-light-jog-02/verify.gd` (프레임 픽셀, 속도, 방향 전환, Walk/Idle 전환)

기존의 양팔 뒤로 달리는 `run` 애니메이션은 별도 리소스로 보존했다. 현재 Shift + 방향키와 `5`는 첫 번째 변형인 `run_light`를 재생하고, `6`은 두 번째 변형인 `run_bouncy`를 재생한다. 랜덤 선택은 아직 연결하지 않았다.

## 기존 빠른 Run: 양팔 뒤로 달리기와 다리 잔상 (revision 8)

장난스러운 표정과 안경, 머리 모양을 살리고 양팔을 뒤로 뻗는 자세로 바꿨다. 상체는 정수 픽셀 이동으로 앞으로 기울였다. 소매와 손은 Aseprite에서 다시 그렸다.

수정된 다리 자세를 사용하고 이전 프레임의 다리 실루엣을 10px·18px 뒤에 옅게 배치했다. 잔상은 Aseprite의 `Leg afterimages` 레이어에서 독립적으로 조절할 수 있다. 이전 7판은 `experiments/sprite-gen-run/manual-revision-08/backup-revision-07/`에 보관했다.

### 기존 Run 제작 당시 기록

기존 `run` 리소스는 192×192 캔버스와 `(95,174)` 기준축을 사용한다. 8프레임은 각각 **60ms**, 합계 **480ms**다. 제작 당시 이동 속도는 **144px/s**였다. 현재 Shift와 `5`는 위의 `run_light`를 재생한다.

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
- 검수 코드는 `experiments/sprite-gen-run/manual-revision-08/verify_run_v8.gd`에 있다. 가져온 텍스처와 PNG의 모든 픽셀, 8프레임의 시간, 총 480ms 및 메인 씬의 Run 연결을 검사한다.

기존 Run의 프레임과 검증 자료는 보관되어 있으며, 추후 다른 Run 변형과 함께 선택하는 방식에 사용할 수 있다.
