# OpenGL → Metal 마이그레이션 계획

## 📋 현재 상황 분석

### 현재 OpenGL 사용 방식

**주요 렌더링 함수**: `MyDrawWithOpenGL()` (OSGLUCCO.m:1785)
- **즉시 모드 렌더링**: `glDrawPixels()` 사용
- **픽셀 포맷**: 
  - Grayscale: `GL_LUMINANCE` + `GL_UNSIGNED_BYTE`
  - Color: `GL_RGBA` + `GL_UNSIGNED_INT_8_8_8_8`
- **Retina 디스플레이**: `glPixelZoom()` + `backingScaleFactor` 사용
- **픽셀 데이터 소스**: `ScalingBuff` (업데이트된 스크린 버퍼)

**OpenGL 컨텍스트 관리**:
- `NSOpenGLContext` 사용
- `makeCurrentContext()` / `update()` / `clearCurrentContext()`
- `NSOpenGLPixelFormat` 생성

**주요 OpenGL 함수들**:
```c
glPixelZoom(scaleFactor, -scaleFactor)      // 픽셀 확대/축소
glRasterPos2i(x, y)                         // 그리기 위치
glDrawPixels(width, height, format, type, data)  // 픽셀 데이터 그리기
glViewport(x, y, width, height)              // 뷰포트 설정
glFlush()                                   // 렌더링 완료
```

### 화면 버퍼 구조

- **원본 버퍼**: `GetCurDrawBuff()` - Mac 에뮬레이션의 메모리에서 읽음
- **스케일링 버퍼**: `ScalingBuff` - 렌더링용으로 변환된 데이터
- **업데이트 함수**: `UpdateLuminanceCopy()` - 변경된 영역만 업데이트

---

## 🎯 Metal 마이그레이션 전략

### 1. 아키텍처 설계

#### 옵션 A: CAMetalLayer 기반 (추천)
- **장점**: 
  - NSView에 직접 통합 가능
  - Retina 디스플레이 자동 처리
  - 간단한 구현
- **구현**: `NSView`의 `layer`를 `CAMetalLayer`로 교체

#### 옵션 B: MTKView 사용
- **장점**: 
  - 더 높은 수준의 추상화
  - 자동 프레임 관리
- **단점**: 
  - 기존 NSView 구조와의 통합 필요

**→ 옵션 A 선택 권장** (기존 구조 유지 용이)

### 2. 렌더링 파이프라인

```
Mac Screen Buffer → ScalingBuff → Metal Texture → Shader → Drawable
     (512x342)        (512x342)      (GPU Memory)    (GPU)    (Screen)
```

**단계별 구현**:
1. **텍스처 생성**: `ScalingBuff` → `MTLTexture`
2. **셰이더 작성**: 
   - Vertex Shader: 사각형 그리기
   - Fragment Shader: 텍스처 샘플링 (필터링 옵션)
3. **렌더링**: Command Buffer + Render Pass
4. **Retina 지원**: `drawableSize` 조정

### 3. 주요 변경 사항

#### 3.1 컨텍스트 관리
**기존 (OpenGL)**:
```objc
NSOpenGLContext *MyNSOpnGLCntxt;
[MyNSOpnGLCntxt makeCurrentContext];
```

**변경 (Metal)**:
```objc
id<MTLDevice> metalDevice;
id<MTLCommandQueue> commandQueue;
CAMetalLayer *metalLayer;
```

#### 3.2 렌더링 함수
**기존 (OpenGL)**:
```objc
glDrawPixels(width, height, GL_LUMINANCE, GL_UNSIGNED_BYTE, ScalingBuff);
```

**변경 (Metal)**:
```objc
// 1. 텍스처 업데이트
[texture replaceRegion:region mipmapLevel:0 withBytes:ScalingBuff bytesPerRow:bytesPerRow];

// 2. 렌더링 인코딩
[renderEncoder setFragmentTexture:texture atIndex:0];
[renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip ...];
```

#### 3.3 Retina 디스플레이 지원
**기존 (OpenGL)**:
```objc
CGFloat scaleFactor = [[window] backingScaleFactor];
glPixelZoom(scaleFactor, -scaleFactor);
```

**변경 (Metal)**:
```objc
CGFloat scaleFactor = [[window] backingScaleFactor];
metalLayer.drawableSize = CGSizeMake(width * scaleFactor, height * scaleFactor);
// 셰이더에서 자동으로 처리됨
```

---

## 📝 구현 계획

### Phase 1: 기본 구조 설정 (1-2일)

1. **Metal 초기화**
   - `MTLDevice` 생성
   - `MTLCommandQueue` 생성
   - `CAMetalLayer` 설정
   - Makefile에 Metal 프레임워크 추가

2. **기존 OpenGL 코드 조건부 컴파일**
   ```objc
   #if USE_METAL
   // Metal 코드
   #else
   // 기존 OpenGL 코드
   #endif
   ```

3. **텍스처 관리 구조**
   - `MTLTexture` 생성/업데이트 함수
   - 픽셀 포맷 매핑 (Luminance ↔ RGBA)

### Phase 2: 셰이더 구현 (1일)

1. **Metal Shading Language 셰이더 작성**
   - `shaders.metal` 파일 생성
   - Vertex Shader: 전체 화면 사각형
   - Fragment Shader: 텍스처 샘플링
   - Retina 스케일링 처리

2. **셰이더 컴파일**
   - Xcode 빌드 단계에 추가
   - 또는 런타임 컴파일 (선택사항)

### Phase 3: 렌더링 파이프라인 (2-3일)

1. **Render Pipeline State 생성**
   - Vertex/Fragment 셰이더 연결
   - 픽셀 포맷 설정

2. **렌더링 함수 구현**
   - `MyDrawWithMetal()` 구현
   - `MyDrawWithOpenGL()` 대체
   - Command Buffer 관리
   - Present Drawable

3. **성능 최적화**
   - 텍스처 업데이트 최소화 (변경된 영역만)
   - 삼중 버퍼링 (선택사항)

### Phase 4: 통합 및 테스트 (1-2일)

1. **기존 기능 검증**
   - Grayscale 렌더링
   - Color 렌더링 (vMacScreenDepth > 0)
   - Retina 디스플레이
   - Magnify 모드
   - Fullscreen 모드

2. **성능 비교**
   - OpenGL vs Metal 벤치마크
   - CPU/GPU 사용률 측정

3. **에러 처리**
   - Metal 초기화 실패 시 fallback
   - 디바이스 지원 확인

---

## 🔧 기술적 세부사항

### Metal 텍스처 포맷 매핑

| OpenGL 포맷 | Metal 포맷 |
|------------|-----------|
| `GL_LUMINANCE` + `GL_UNSIGNED_BYTE` | `MTLPixelFormatR8Unorm` |
| `GL_RGBA` + `GL_UNSIGNED_INT_8_8_8_8` | `MTLPixelFormatRGBA8Unorm` |

### 셰이더 구조

**Vertex Shader**:
```metal
vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    // 전체 화면 사각형 (2 triangles)
    float2 positions[4] = {
        float2(-1,  1),  // top-left
        float2( 1,  1),  // top-right
        float2(-1, -1),  // bottom-left
        float2( 1, -1)   // bottom-right
    };
    VertexOut out;
    out.position = float4(positions[vertexID], 0, 1);
    out.texCoord = float2((positions[vertexID].x + 1) * 0.5,
                          (1 - positions[vertexID].y) * 0.5);
    return out;
}
```

**Fragment Shader**:
```metal
fragment float4 fragment_main(VertexOut in [[stage_in]],
                               texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    return texture.sample(textureSampler, in.texCoord);
}
```

### Retina 디스플레이 처리

```objc
// Metal Layer 설정
CAMetalLayer *metalLayer = (CAMetalLayer *)view.layer;
metalLayer.device = metalDevice;
metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;

// Retina 스케일링
CGFloat scaleFactor = [[view window] backingScaleFactor];
metalLayer.contentsScale = scaleFactor;
metalLayer.drawableSize = CGSizeMake(
    view.bounds.size.width * scaleFactor,
    view.bounds.size.height * scaleFactor
);
```

---

## 📊 예상 효과

### 성능 향상
- **GPU 활용**: Metal은 더 효율적인 GPU 사용
- **낮은 오버헤드**: OpenGL 대비 더 낮은 드라이버 오버헤드
- **Apple Silicon 최적화**: M1/M2/M3에서 네이티브 성능

### 호환성
- **macOS 10.11+**: Metal 지원
- **Deprecation 해결**: OpenGL 경고 제거
- **미래 호환성**: Apple의 장기 지원 기술

### 유지보수성
- **현대적 API**: 더 명확한 구조
- **디버깅 도구**: Metal Debugger, Xcode Instruments
- **코드 품질**: 명시적 리소스 관리

---

## ⚠️ 주의사항 및 고려사항

### 1. 호환성
- **최소 macOS 버전**: macOS 10.11 (El Capitan)
- **하드웨어 요구사항**: Metal 지원 GPU (2012년 이후 Mac)

### 2. 점진적 마이그레이션
- OpenGL과 Metal 병행 지원 (컴파일 타임 선택)
- 사용자 선택 옵션 제공 가능

### 3. 테스트 환경
- 다양한 디스플레이 (Retina/Non-Retina)
- 다양한 Mac 모델
- 다양한 macOS 버전

### 4. 성능 비교
- OpenGL vs Metal 벤치마크 필수
- 실제 사용 시나리오 테스트

---

## 📅 추정 일정

- **Phase 1**: 1-2일
- **Phase 2**: 1일
- **Phase 3**: 2-3일
- **Phase 4**: 1-2일

**총 예상 시간**: 5-8일 (부분 시간 작업 기준)

---

## 🚀 시작하기

### 첫 번째 단계
1. 새 브랜치 생성: `git checkout -b feature/metal-rendering`
2. Metal 프레임워크 추가: Makefile 수정
3. 기본 Metal 초기화 코드 작성
4. OpenGL 코드와 병행 테스트

### 다음 단계
- Phase 1부터 순차적으로 진행
- 각 Phase 완료 후 커밋
- 지속적인 테스트 및 검증

---

## 📚 참고 자료

- [Metal Programming Guide](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf)
- [Metal Best Practices Guide](https://developer.apple.com/metal/Metal-Best-Practices-Guide.pdf)
- [CAMetalLayer Documentation](https://developer.apple.com/documentation/quartzcore/cametallayer)
- [Apple's Metal Sample Code](https://developer.apple.com/metal/sample-code/)

---

**작성일**: 2024-11-05  
**작성자**: Mini vMac ARM 프로젝트 팀  
**버전**: 1.0

