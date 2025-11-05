# Metal 렌더링 테스트 방법

## 로그 확인 방법

### 방법 1: 터미널에서 직접 실행
```bash
./minivmac.app/Contents/MacOS/minivmac
```

### 방법 2: 콘솔 앱에서 확인
1. 앱을 Finder에서 실행
2. "콘솔" 앱 실행 (Applications > Utilities > Console)
3. 왼쪽 사이드바에서 디바이스 선택
4. 검색창에 "Metal" 또는 "RENDERER" 입력

### 방법 3: 테스트 스크립트 사용
```bash
./test_metal.sh
```

## 확인할 로그 메시지

Metal이 활성화되면:
```
=== Metal Rendering Enabled ===
Metal Device: Apple M1 (또는 사용 중인 GPU 이름)
=== RENDERER INFO ===
Active Renderer: METAL
Metal Device: Apple M1
Metal Layer: Initialized
Metal Pipeline: Ready
===================
```

OpenGL이 활성화되면:
```
=== RENDERER INFO ===
Active Renderer: OPENGL
OpenGL Context: Initialized
===================
```

## Metal/OpenGL 전환 방법

Makefile을 수정:
- Metal 사용: `mk_COptionsOSGLU = $(mk_COptionsCommon) -Os -flto -DUSE_METAL=1`
- OpenGL 사용: `mk_COptionsOSGLU = $(mk_COptionsCommon) -Os -flto -DUSE_METAL=0`
