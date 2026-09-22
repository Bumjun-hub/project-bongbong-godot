# 오른쪽 3/4 특수 Idle

확정된 오른쪽 3/4 기본 Idle과 같은 방향으로 팔짱과 주머니 자세를 제작했다.

## 결과
- ../../arms_crossed_three_quarter_right/: PNG6장, 가로6칸시트, GIF, 실제 Aseprite 원본, manifest.
- ../../pockets_three_quarter_right/: 동일 구성.
- 192×192 투명RGBA, 중심x95, 지면경계y174. 프레임별 자동자르기 없음.
- 팔짱: 650/450/500/600/450/650ms, 총3.3초.
- 주머니: 750/500/450/650/550/700ms, 총3.6초.
- 기본 → 가슴/어깨 상승 → 머리 연동 → 유지 → 어깨 단계 → 기본. 최대1px, 전체 Sprite scale/회전 없음. 눈 깜빡임 제외.

## 제작 및 보존
내장 image_gen에서 자세 참고 그림을 생성한 뒤 Aseprite의 정수 픽셀 편집으로 필요한 팔/소매/주머니 영역을 정렬했다. 기본3/4 Idle의 머리/얼굴/안경/시선과 하체/발은 원본픽셀을 유지했다. 팔짱은 원근에 맞춰 전완과 손을 겹쳤고, 주머니는 손이 청바지입구에 가려지도록 했다. 비교판 right_idle_set_2x.png의 왼쪽부터 기본/팔짱/주머니다.

## 확인
- 머리그림(호흡1px 위치변화 제외), y153이하 하체/발의 기본3/4 Idle과 픽셀일치.
- 첫/마지막 프레임 동일, 호흡 중 발고정.
- 재개방한 Aseprite/개별PNG/시트 셀 픽셀일치, GIF6프레임 및 시간일치.
- 기존 Idle36개 파일 SHA-256 동일.
- 192px 시트와2배 비교판 정적 시각검수. 실제 Godot 데스크톱 실행은 미검증. 자세 전환 프레임/로직은 미제작.
- 기존참고프로젝트, 확정Base, 정면Idle과 기본3/4 Idle은 변경하지 않았다.

## 팔짱 프롬프트
Edit ONLY the arm/sleeve pose of this exact RIGHT-FACING THREE-QUARTER Bongbong pixel character. Keep the head, face, eyes looking screen-right, hair, glasses, 30-degree body angle, clothing, legs, shoes, stance and full-body proportions identical to the supplied image. Do NOT turn him toward the viewer. This is a 1.7-head-tall SD character: crown-to-chin is59% of full height, below-chin41%; short compact torso and legs.
Make a comfortable ARMS CROSSED idle pose appropriate for this tiny SD body. Short, softly rounded forearms fold over the middle chest, elbows tucked under shoulders. One hand nests invisibly beneath the opposite upper arm; the other small hand may rest partially visible on the far upper arm. Correct perspective: the near forearm overlaps the far forearm; short sleeves with WHITE rolled cuffs change orientation with upper arms. No long thin X rods, no fingers crowded at center, no widened shoulders, no crossed hands at waist. Keep silver necklace visible above folded arms, red shirt hem below them, blue jeans and planted white-black shoes unchanged.
One full-body pixel-art sprite on true transparent RGBA, no shadow, no text, no additional views. Clean pixel clusters matching the reference, no blur. Target192x192, crown18, chin109, sole bottom173, centeranchor95. Both soles same baseline. The only design change is arms/sleeves folded across chest.

## 주머니 프롬프트
Edit ONLY arms/sleeves/jeans pocket entry of this exact Bongbong RIGHT-FACING THREE-QUARTER pixel character into a natural BOTH HANDS IN POCKETS idle. KEEP his right-facing head, eyes looking right rather than at viewer, hair, round glasses, face, 30-degree body perspective, outfit and planted stance identical. Preserve 1.7-head SD proportions: crown-to-chin59% total, below-chin41%, short torso and short jeans legs, not taller.
Both short arms hang relaxed close to the torso, elbows only slightly bent; forearms slope inward/downward into FRONT JEANS POCKETS. Hands/fingers disappear INSIDE the blue denim at hip level, only tiny thumb corners possibly visible. Near arm is more visible than far arm due to the existing right-facing perspective. No hands-on-hips pose, no big outward elbow loops, no noodle arms, no pockets in shirt, no walking. Red shirt with white rolled sleeve cuffs, silver ring necklace and small gray shirt graphic preserved. Light blue jeans and white-black sneakers preserved. Both shoe soles on same baseline.
One full-body pixel-art sprite, crisp clusters and restrained shading matching reference. Actual transparent RGBA background, no ground shadow, labels or extra views. Target192x192 centered x95 crown18 chin109 sole bottom173. Only arms/sleeves and pocket openings change.
