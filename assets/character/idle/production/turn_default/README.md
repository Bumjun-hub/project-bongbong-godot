# 기본 Idle — 오른쪽 3/4 자세

정면 응시를 줄이기 위해 머리/몸/발/시선이 함께 화면 오른쪽을 향하는 정지 자세를 제작했다. 회전 동작이나 걷기 애니메이션이 아니다.

- 런타임 후보 폴더: ../../default_three_quarter_right/
- 192×192 RGBA, 중심 기준 x95, 발바닥 마지막 행 y173(지면 경계174).
- 원본과 같은 약1.7등신, 양손을 내린 편한 자세. 원근에 따른 얼굴/안경/몸통 형태는 새로 그렸다.
- 6프레임, 600/400/500/450/450/600ms, 총3초 반복.
- 상체/어깨가 먼저1px, 정점에서 머리가1px 따라오며 원래 위치로 복귀한다. y138이하 하체/손/발은 루프 전체에서 동일하다.
- 눈 깜빡임 없음. 전체 스프라이트 이동/확대축소/회전 없이 완성된 픽셀 프레임을 저장했다.
- 생성: 내장 image_gen으로 방향 변경 및 비율 보정. Aseprite에서 최근접 정렬, 투명 경계 잡픽셀 정리, 호흡 프레임 편집/내보내기.
- 개별PNG, 가로6칸시트, GIF, 실제 .aseprite 원본과 manifest 저장.
- 검증: 6프레임/3초, Aseprite 저장 후 픽셀 대조, 머리 그림/발/하체 고정, 첫/마지막 프레임 일치.
- 기존3종 Idle의27개 파일 해시 동일. 기존정면Base와 참고프로젝트는 보존. 루프간 방향전환용 연결프레임과 Godot로직은 미구현.
- 시각검수: 192px 결과 및2배 정면/측면 비교. front_and_right_2x.png의 왼쪽은 기존정면, 오른쪽은 이번결과.

## 생성 프롬프트
Edit this exact Bongbong default idle character into a relaxed shallow THREE-QUARTER VIEW FACING SCREEN RIGHT, about 30 degrees away from frontal. This is a still standing idle direction, NOT a walking pose and NOT an animation of turning. Turn HEAD, FACE, SHOULDERS, TORSO and FEET together coherently. Eyes look calmly in the same screen-right direction as the face, not back toward the viewer. Both round glasses lenses remain visible in perspective; the far lens and far side of the face are slightly narrower. Visible near cheek and ear, gentle natural perspective. Avoid full profile.
Preserve the same recognizable 1.7-head-tall SD character: large black parted tousled hair and curled forelock, round black glasses, friendly understated mouth, red/burgundy short-sleeve shirt with white cuffs and small gray chest graphic, silver ring pendant, light blue jeans, white-black sneakers. The head-to-body height ratio stays 1:0.7, NOT 2-head or 2.5-head. No new design details.
Maintain the approved default IDLE: both arms resting loosely down beside body, hands OUTSIDE pockets, no folded arms, no gesture, no walking stride. Both feet planted at the same ground level, one foot naturally foreshortened, legs gently apart. No lean or large asymmetrical pose. Character is still comfortable, only facing direction changes.
Crisp readable pixel art with restrained shading and clear pixel clusters, same palette as the reference, no antialias blur. One full-body character only on genuinely transparent RGBA. No ground shadow, labels, background, multiple views. Target192x192 canvas, center anchor x95 ground y174, hair y18, chin abouty109, sole pixels y173. Keep generous margins, never crop the head or feet.

## 비율 보정 프롬프트
Keep EXACT same right-facing three-quarter pose, gaze away from viewer, face, hair, glasses, outfit and arm position. Correct ONLY body length to true 1.7-head SD proportion. Current crown-to-chin about520 and chin-to-sole440. Keep entire head shape and size UNCHANGED; shorten below-chin region by about17 percent so chin-to-sole is about364, 0.7 times head. Shorten torso and trouser legs without squashing shoes/hands. BOTH shoe soles planted on exactly one horizontal ground baseline; this is standing, not a stride. Arms relaxed down, no pockets. Preserve pixel-art style and all clothing. One character transparent RGBA no shadow, no text, comfortable square canvas margins. Do not return original longer body. Head+body ratio1:0.7.
