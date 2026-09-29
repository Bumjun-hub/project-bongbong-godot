# Windows 창 위치 도구

`bin/Bongbong.WindowBounds.exe`는 봉봉이에게 실제 창의 윗면 위치를 알려주는 작은 .NET Framework 프로그램입니다. 현재 프로젝트 실행에 필요한 빌드 결과를 함께 보관합니다.

## 다시 빌드하기

프로젝트 폴더의 PowerShell에서 다음을 실행합니다.

```powershell
& .\native\windows\build.ps1
```

Windows의 .NET Framework C# 컴파일러를 사용합니다. 별도 .NET SDK나 NuGet 패키지는 필요하지 않습니다. 관리자 권한을 요청하지 않으며, 콘솔 창이 뜨지 않는 프로그램으로 빌드합니다.

## 전달하는 정보

- `EnumWindows`로 보이는 최상위 창을 확인하고, DWM의 실제 테두리 경계를 읽습니다.
- 최소화·숨김·클로킹된 창, 셸 배경·작업표시줄·투명 장식, 호출한 봉봉이 창은 제외합니다.
- 기본 제목 표시줄이 있는 일반 창을 발판 후보로 표시합니다. 카카오톡처럼 자체 제목 표시줄을 쓰는 창도 크기 조절 테두리와 시스템 메뉴 또는 앱 창 표시가 있으면 포함합니다. 도구 창과 클릭 통과 창은 제외하며, 나머지 불투명 창도 뒤쪽 발판을 가리는 계산에는 사용합니다.
- `GetTopWindow`/`GetWindow`의 앞뒤 순서로 배열을 전달합니다. 순회에는 개수 제한과 중복 검사로 종료 조건을 둡니다.
- 창 핸들, 경계 좌표, 발판 여부, 봉봉이 창의 실제 클라이언트 영역과 현재 Windows 세션의 마지막 키보드·마우스 입력 이후 시간(`idle_ms`)을 전달합니다. 창 제목, 문서 내용, 입력한 키나 마우스 위치는 수집하지 않습니다.

PerMonitor DPI 설정을 사용하며, 봉봉이 창의 실제 화면 좌표를 함께 보내 Godot의 모니터 기준점과 맞춥니다. Godot 쪽에서는 네이티브 클라이언트 크기와 Godot 창 크기의 비율도 적용합니다.

## 실행과 종료

Godot가 자신의 창 핸들을 첫 인수로 전달해 `OS.execute_with_pipe()`로 실행합니다. 표준 입력의 `snapshot`마다 JSON 한 줄을 반환합니다. `quit` 또는 입력 파이프 종료 시 함께 종료됩니다. 네트워크, 입력 후킹, 다른 프로세스의 메모리 접근은 사용하지 않습니다.

`scripts/windows_platforms.gd`가 약 33ms 간격으로 요청하며, 응답을 기다리는 동안 애니메이션을 계속 처리합니다. 창 핸들·전체 경계·보이는 윗면 구간을 함께 보관해, 봉봉이가 서 있는 창의 이동을 추적합니다. `GetLastInputInfo`로 받은 경과 시간은 창 위에서 오래 쉬다 잠드는 동작에 사용합니다. 응답 실패 시 실제 창 발판을 비우고 기존 바닥 동작을 유지합니다.

현재 실행은 프로젝트 폴더의 실행 파일을 사용합니다. 향후 Godot 배포본을 만들 때에는 이 실행 파일을 PCK 내부가 아닌 실제 파일로 포함하고 경로를 연결해야 합니다.

## 확인

- `tests/WindowStyleChecks.cs`: 일반 창, 실제 카카오톡 기본·대화 창의 스타일, 자체 테두리·반투명 앱 창, 보조 패널·도구 창·클릭 통과 장식 등 13개 조건을 검사합니다. `WindowBounds.cs`와 함께 `/main:WindowStyleChecks`로 빌드합니다.
- 카카오톡의 표시 중인 기본·대화 창에서 기본 제목 표시줄 비트가 빠져 있던 것을 확인했습니다. 수정한 실행 파일의 실제 Windows 스냅샷에서는 두 창 모두 `platform: true`가 되고, 별도 보조 패널은 계속 `false`입니다. 창 내용이나 대화 내용은 읽지 않았습니다.
- `tests/window_surfaces_smoke.gd`: 겹친 윗면, 음수 좌표, 배율 변환, 전체 화면 가림, 위쪽 공간 검사.
- `tests/window_follow_smoke.gd`: 창 이동·크기 변경, 걷기·인사 유지, 가림·제거에 따른 낙하, 드래그·공중에서 분리, 위쪽 공간 검사.
- `tests/side_grab_smoke.gd`: 보이는 양쪽 옆면, 손 접촉 기준점, 잡기·유지·드래그/Space 해제, 이동·크기 변경·가림·삭제 검사.
- `tests/native_windows_smoke.gd`: 실제 Windows 테스트 창의 경계, 착지·걷기·옆면 붙잡기, 이동·축소·숨김·최소화·닫힘·가림, 자기 창 제외, 보조 프로그램 종료 검사. Windows 화면 환경에서 실행합니다.
- `tests/desktop_screen_smoke.gd`: 전체 바탕화면 범위·클릭 영역·이동과 실제 IDLE 신발 밑면의 작업표시줄 위 접촉 검사.

API 설명: [Godot 프로세스 파이프](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-execute-with-pipe), [EnumWindows](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-enumwindows), [DwmGetWindowAttribute](https://learn.microsoft.com/en-us/windows/win32/api/dwmapi/nf-dwmapi-dwmgetwindowattribute), [GetLastInputInfo](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getlastinputinfo).
