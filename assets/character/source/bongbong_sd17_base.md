# Bongbong 1.7등신 Base

- bongbong_sd17_base.png: 192×192 RGBA, 투명 배경.
- 약 1.7등신 목표. 시각 판독상 정수리~턱 약90px, 전체156px로 약1.73등신. 머리카락 포함 기준의 근사값.
- 배치 x=47..142, y=18..173. 중심 기준 x=95, 지면 하단 경계 y=174.
- 검은 가르마 머리, 둥근 안경, 미소, 붉은 반팔/흰 소매단, 목걸이, 청바지, 흑백 운동화 유지.
- 양손을 주머니에서 뺀 제작용 Neutral Base. 애니메이션은 미제작.
- 내장 image_gen 생성/비율 보정 후 최근접 리사이즈. 투명도 및 192px 시각 검수 완료. 수작업 픽셀 클린업/모션 검수 미수행.
- 기존 1.4등신/2등신 결과와 기존 프로젝트 보존. Godot 씬/설정 변경 없음.

## 생성 프롬프트
Edit the supplied Bongbong pixel character to 1.7-head-tall SD proportions. Keep the SAME character identity, black parted tousled hair with curved forelocks, round black glasses, friendly smile, burgundy short sleeve shirt, white rolled cuffs, small gray chest graphic, silver ring necklace, light blue jeans, black-white sneakers. Proportion target: hair crown to chin = 58.8% of total character height; chin to soles = 41.2%. Head-to-below-chin height ratio 1:0.7. Enlarge head modestly and shorten torso and legs from the supplied roughly 2-head version; do not exaggerate into 1.4 heads. At 192x192 design target hair top y18, chin y109, shoe sole bottom y173 (head92px, lower body64px). Keep head width in proportion, readable compact silhouette. Frontal neutral master pose, both hands outside pockets, arms slightly down/out with gaps to torso, natural sleeve-arm-hand connections, two distinct legs and shoes on one baseline. ONE character only, no animation, no labels, no props, no ground shadow. Genuine transparent RGBA background. Crisp pixel-art stepped edges and readable clusters, restrained shading, no blur or soft resampling. Maintain outfit, face and pose; change proportions only. Deliver 192x192 if possible.

## 보정 프롬프트
Correct ONLY proportions: supplied character is still about 1.9 heads tall, needs 1.7. KEEP HEAD EXACTLY SAME size, shape, face, hair and glasses. Reduce all below-chin body height by 23 percent, by shortening shirt torso and trouser legs, preserve width, natural hands and shoe shapes. The head from hair top to chin is about550 units; below chin to sole MUST be about385 units, not the current500. Head 59% total, body41%. Same red shirt white cuffs necklace blue jeans black-white shoes, identical frontal neutral pose both hands outside pockets. Crisp pixel art, transparent alpha, no blur, no text, one full body sprite centered. Do not merely return unchanged proportions. Deliver square transparent image with comfortable margins.
