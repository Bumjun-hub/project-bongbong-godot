# 스프라이트 제작 기록

생성 프롬프트, 파이프라인 보고서, 편집 스크립트와 검증 코드를 보관한다.
영상 및 중간 프레임은 용량이 커서 이 폴더의 Git 제외 규칙으로 로컬에만 보관한다.
중간물을 읽는 제작 스크립트는 해당 생성 결과가 있어야 실행할 수 있다.

Godot 실행에 필요한 최종 PNG와 Aseprite 원본은 `assets/character/`에 포함되어 있다.
현재 가벼운 달리기는 `sprite-gen-run/grok-light-jog-02/`에서 제작했으며,
`verify.gd`는 저장소의 최종 에셋과 메인 씬을 검증한다.

현재 적용 내용과 조작 방법은 루트의 `IDLE_TEST.md`, `WALK_TEST.md`,
`RUN_TEST.md`, `DESKTOP_WINDOW_TEST.md`를 참고한다.
