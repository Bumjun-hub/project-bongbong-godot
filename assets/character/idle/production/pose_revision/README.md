# Special Idle pose revision

기본 IDLE_DEFAULT는 유지하고 POCKETS / ARMS_CROSSED의 팔 자세만 수정했다.

- POCKETS: 밖으로 둥글게 벌어졌던 팔꿈치를 몸에 가깝게 내리고, 손끝은 청바지 입구로 가렸다. 소매와 전완에 기존 SD 그림과 어울리는 두께를 부여했다.
- ARMS_CROSSED: 배 앞의 긴 두 띠 모양을 가슴 높이에서 접힌 짧은 팔로 교체했다. 한 손은 반대쪽 팔 아래로 가리고, 다른 손의 일부만 위쪽에 보이게 했다. 소매도 앞으로 접힌 팔에 맞게 그렸다.
- 내장 image_gen으로 자세 참고 그림을 만든 뒤, 필요한 팔/소매/주머니 영역만 Aseprite에서 정수 픽셀로 재배치했다. 얼굴/머리와 하체/발은 확정 Base의 원본 픽셀을 유지했다. PNG 참조에서 최근접 샘플링하였고 프레임별 리사이즈는 없다.
- 기본 Idle PNG 7개/GIF 1개/Aseprite 1개(총9개)의 SHA-256이 작업 전과 동일하다.
- 기존 6프레임, 주머니3.6초/팔짱3.3초, 1px 호흡 유지. 하체/발 y153..191 고정, 첫/마지막 프레임 동일, 머리 모양 보존 검증 통과.
- 저장된 PNG/스프라이트시트/Aseprite를 다시 열어 픽셀 및 시간 일치 확인.
- arms_before_after_4x.png: 위=주머니, 아래=팔짱, 왼쪽=수정 전, 오른쪽=수정 후.

## 팔짱 참고 그림 프롬프트
Edit this exact character into a relaxed natural ARMS CROSSED idle standing pose. Keep the 1.7-heads-tall proportions, full front facing view, identical head size, face, hair, round glasses, red short-sleeve shirt with white cuffs, silver necklace, blue jeans and white-black shoes. Cross his SHORT arms comfortably over the middle chest, not low over his belly. His elbows stay tucked inward below shoulders, small hands nest under opposite upper arms; one small hand partially visible resting on the opposite upper arm. Compact readable folded arms, not two long thin parallel noodles or an X of rods. Red sleeves must change orientation naturally with the folded upper arms, the forearms have soft volume and clear overlap with the shirt. Do not widen shoulders. Keep same head, legs and planted feet. Crisp pixel art matching reference, restrained highlight clusters, transparent RGBA background, one character, no shadows, no text. 192x192 target full canvas, centerx95, crown18, ground174. Only change arms/sleeves pose.

## 주머니 참고 그림 프롬프트
Edit ONLY arm pose of this exact pixel character to a relaxed BOTH HANDS IN JEANS POCKETS idle. Same 1.7-head SD character and all proportions: black parted tousled hair, round glasses, friendly face, red short sleeve shirt with white cuffs and ring necklace, light blue jeans and black-white shoes. Frontal planted feet. Short upper arms hang down naturally almost against torso, elbows very slightly out, forearms slope gently inward DOWN into the front jeans pockets. Fingers are INSIDE pockets fully hidden by blue denim, only small thumb corners may peek at the pocket opening. Do NOT put hands on hips, do NOT form circular outward elbows, no U-shaped noodle arms, no long arms. Make anatomically plausible compact SD arms with volume and short wrists. Keep shoulders narrow and relaxed, same leg lengths and head size as image. Preserve face, hair, legs and feet. Crisp pixel clusters, transparent RGBA, one full body centered character, no labels or shadow, 192x192 target crown18 chin110 soles173 center95.
