# 🌏 TabiLenS (타비렌즈)

> **해외 여행자를 위한 실시간 메뉴판 영역 번역, 식문화 가이드 & 주문 도우미 서비스**
>
> *"세로쓰기 일본어 메뉴판부터 낯선 유럽·아시아 현지어 메뉴판까지, 어떤 음식인지 몰라 난감했던 적이 있으신가요? TabiLenS가 해결해 드립니다."*

TabiLenS는 해외 현지를 여행하는 여행자들이 메뉴판이나 간판을 읽을 때 겪는 언어적·문화적 장벽을 해소하기 위해 개발된 **Flutter 기반의 멀티플랫폼(Android / iOS / Web) 애플리케이션**입니다. 

단순히 전체 화면을 기계적으로 직역하는 것을 넘어, **사용자가 원하는 메뉴 영역을 직관적으로 선택(확대/축소 + 사각형 및 자유 곡선)**하여 잘라내고, **Gemini AI**를 통해 영역 내 포함된 여러 메뉴를 정확하게 분리·분석합니다. 또한 **음식의 유래, 맛의 특징, 식재료 및 알레르기 주의 정보**, 현장에서 즉시 활용할 수 있는 **상황별 맞춤 주문 회화와 TTS(Text-to-Speech) 원어민 발음 듣기 기능**까지 원스톱으로 제공합니다.

---

## ✨ 핵심 기능 (Key Features)

### 1. 🔍 사진 확대/축소 기본 & 직관적인 영역 선택 (Pan/Zoom & Toggle Tools)
* **기본 핀치 줌 & 팬 내비게이션 (Default Pan & Zoom)**:
  * 도구를 켜지 않은 기본 상태에서 한 손가락 드래그로 사진을 자유롭게 이동하고, 두 손가락 핀치 제스처로 **최대 6배까지 고해상도 확대/축소**가 가능합니다.
  * 빼곡하거나 작은 메뉴판 글씨도 원하는 배율로 확대한 후 편안하게 확인할 수 있습니다.
* **상호 배타 토글 선택 도구 (Mutual Exclusive Toggles)**:
  * **`[ ⬚ 사각형 ]` 토글 ON**: 터치 시작점에서 대각선으로 드래그하여 깔끔한 사각형 영역을 지정합니다.
  * **`[ 〰️ 자유 곡선 ]` 토글 ON**: 손가락을 따라 실시간으로 곡선 궤적을 그리며 불규칙한 형태의 메뉴 영역을 스케치하듯 자유롭게 선택합니다.
  * **토글 OFF (재탭)**: 활성화된 도구를 한 번 더 누르면 토글이 꺼지며, **선택 영역을 그대로 유지한 채 기본 확대/축소/이동 모드로 복귀**합니다.
* **전체 자동 감지 (Auto Detect All)**:
  * 우측 상단 버튼을 통해 이미지 내 모든 텍스트 블록을 원클릭으로 자동 감지하여 바운딩 박스로 시각화합니다.

### 2. ✂️ 선택 영역 실시간 크롭 & 정밀 복수 메뉴 분석 (Cropped Area Multi-Menu Analysis)
* **무손실 고해상도 크롭 (`ImageUtils`)**:
  * 사용자가 지정한 정규화 좌표(0.0~1.0)를 바탕으로 원본 이미지에서 선택 영역만을 정확히 잘라냅니다.
* **복수 메뉴 자동 분리 파싱**:
  * 선택 영역 내에 여러 개의 메뉴가 포함되어 있어도, Gemini 2.5 Flash가 개별 메뉴 항목으로 자동 분리하여 각각의 상세 정보를 구조화된 카드로 제공합니다.
* **결과 화면 크롭 이미지 표시**:
  * 분석 결과 화면 상단에 내가 실제로 선택하고 잘라낸 메뉴 영역 이미지(`선택 크롭 영역` 배지)가 노출되어 무엇을 번역했는지 직관적으로 대조할 수 있습니다.

### 3. 💡 원어 중심 메뉴 칩 & 현지 식문화 가이드
* **원어(외국어 원문) 우선 표기**:
  * 상단 메뉴 칩 및 대표 제목에 **현지 원어 표기**를 기본으로 노출하고 한국어 번역명을 병기하여, 현지 식당에서 점원과 소통하거나 메뉴판과 대조할 때 혼선이 없습니다.
* **깊이 있는 식문화 해설**:
  * 해당 메뉴의 역사와 유래, 현지 조리 방식, 대표적인 식감과 맛의 조화 등을 친절하게 설명합니다.
* **실전 주문 꿀팁**:
  * 맵기 단계, 추천 소스 조합, 현지인 추천 먹는 방법 등 식당에서 바로 유용하게 활용할 수 있는 팁을 제공합니다.

### 4. ⚠️ 알레르기 및 안전 식재료 정보 (Allergy Information)
* **알레르기 유발 물질 가이드**:
  * 분석 결과 하단에 해당 메뉴에 들어갈 수 있는 대표적인 알레르기 유발 식재료(갑각류, 견과류, 메밀, 글루텐, 계란, 유제품 등) 정보를 눈에 띄는 안전 주의 카드로 명시합니다.
  * 특이 식재료나 체질별 주의 성분을 사전에 파악하여 안심하고 식사할 수 있도록 돕습니다.

### 5. 🗣️ 개인 맞춤형 주문 회화 & 네이티브 TTS (Text-to-Speech)
* **상황별 동적 회화 생성**:
  * 선택한 메뉴 이름을 기반으로 점원에게 바로 말할 수 있는 실전 문장(수량 주문, 추천 요청, 특정 재료 제외 요청 등)을 자동으로 생성합니다.
* **한글 독음 & 뜻 병기**:
  * 현지어 표기와 함께 한국어 한자 독음 및 원어 발음, 번역을 함께 제공합니다.
* **네이티브 오디오 듣기**:
  * 스피커 아이콘을 탭하면 `flutter_tts` 엔진을 통해 원어민 발음 오디오를 재생하여 점원에게 들려주거나 직접 따라 말할 수 있습니다.

### 6. 🌐 여행 국가별 언어 설정 & 다국어 인터페이스
* **여행 국가 맞춤 소스 언어 (`LanguageMode`)**:
  * 자동 감지(Auto)는 물론 일본어, 프랑스어, 이탈리아어, 스페인어, 중국어, 베트남어, 태국어 등 여행하는 국가에 맞춰 소스 언어를 손쉽게 전환할 수 있습니다.
* **다국어 UI 지원 (`AppStrings`)**:
  * 한국어, 영어, 일본어, 중국어, 스페인어, 프랑스어 등 사용자 인터페이스 언어를 완벽하게 지원합니다.

### 7. 📂 이모지 폴더 즐겨찾기 & 영구 로컬 저장
* **이모지 커스텀 폴더**:
  * 🍱, 🍜, 🍣, ☕ 등 원하는 이모지와 폴더명을 매칭하여 관심 메뉴를 카테고리별로 북마크할 수 있습니다.
* **로컬 자동 저장 (`shared_preferences`)**:
  * 디바이스 내부에 즐겨찾기와 최근 번역 히스토리가 안전하게 보관되어 오프라인 상태에서도 확인 가능합니다.

---

## 🏗️ 프로젝트 구조 (Project Directory Structure)

```text
lib/
├── main.dart                             # 앱 진입점 및 환경 초기화
├── core/
│   ├── constants/
│   │   └── env_keys.dart                 # 환경 변수 키 정의
│   ├── localization/
│   │   └── app_strings.dart              # 다국어 리소스 및 시스템 안내 문구
│   ├── theme/
│   │   └── app_theme.dart                # 라이트/다크 하모니 테마 정의
│   └── utils/
│       └── image_utils.dart              # EXIF 회전 보정 및 정규화 좌표 이미지 크롭 유틸리티
├── data/
│   ├── models/
│   │   ├── detected_text_block.dart      # OCR 검출 텍스트 블록 모델
│   │   ├── history_item.dart             # 번역 히스토리 아이템 모델
│   │   └── translation_result.dart       # Gemini 다중 메뉴 분석 및 알레르기 결과 모델
│   └── services/
│       ├── gemini_service.dart           # Gemini 2.5 Flash API 연동 (영역 검출, 크롭 정밀 분석)
│       └── tts_service.dart              # Flutter TTS 엔진 래퍼 서비스
├── providers/
│   ├── favorites_provider.dart           # 즐겨찾기 폴더 및 아이템 상태 관리
│   ├── gemini_provider.dart              # Gemini 분석 상태 관리
│   ├── history_provider.dart             # 번역 히스토리 상태 관리
│   ├── image_provider.dart               # 선택된 이미지 상태 관리
│   ├── language_provider.dart            # 여행 국가(소스 언어) 및 앱 언어 상태 관리
│   ├── shared_preferences_provider.dart  # 로컬 저장소 인스턴스 프로바이더
│   └── text_selection_provider.dart      # 텍스트 블록 선택 상태 관리
└── screens/
    ├── home_screen.dart                  # 메인 홈 화면 (촬영, 갤러리 업로드, 국가 선택, 인트로 애니메이션)
    ├── text_selection_screen.dart        # 사진 확대/이동 및 사각형/자유 곡선 선택 화면
    ├── result_screen.dart                # 크롭 이미지, 다중 메뉴 칩, 문화 가이드, 알레르기 및 주문 회화 화면
    ├── favorites_screen.dart             # 이모지 폴더별 즐겨찾기 관리 화면
    └── history_screen.dart               # 최근 번역 히스토리 화면
```

---

## 🛠️ 기술 스택 (Tech Stack)

* **Framework**: Flutter (Dart SDK `^3.12.1`)
* **State Management**: Flutter Riverpod (`^2.5.1`) — 비즈니스 로직 분리 및 반응형 상태 관리
* **Generative AI**: Google Gemini API (`google_generative_ai ^0.4.0`) — Gemini 2.5 Flash 기반 지능형 OCR & 메뉴 분석
* **Image Processing**: `image ^4.5.4` — EXIF 기반 사진 회전 보정 및 고해상도 바운딩 박스 크롭
* **Text-to-Speech**: `flutter_tts ^4.2.5` — 원어민 오디오 발음 지원
* **Local Persistence**: `shared_preferences ^2.5.5` — 즐겨찾기 및 번역 기록 디바이스 영구 저장
* **Environment Configuration**: `flutter_dotenv ^5.1.0` — API Key 안전 관리
* **CI/CD & Deployment**: GitHub Actions & GitHub Pages (웹 자동 빌드 및 호스팅 연동)

---

## 🚀 시작하기 & 빌드 가이드 (Getting Started & Build Guide)

### 1. 사전 요구사항 (Prerequisites)
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12.1` 이상 권장)
* Google AI Studio에서 발급받은 [Gemini API Key](https://aistudio.google.com/)

### 2. 환경 변수 설정
프로젝트 루트 디렉토리에 `.env` 파일을 생성하고 발급받은 Gemini API 키를 작성합니다.
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```
> **주의**: `.env` 파일은 민감한 정보를 담고 있으므로 버전 관리 시스템(Git)에 커밋되지 않도록 주의하세요. (.gitignore에 기본 등록되어 있습니다.)

### 3. 패키지 설치 및 로컬 실행
```bash
# 의존성 패키지 설치
flutter pub get

# 로컬 시뮬레이터 / 디바이스에서 실행
flutter run
```

---

## 📦 플랫폼별 빌드 방법 (Production Build)

### 🤖 Android (APK Build)
```bash
flutter build apk --release
```
* **결과물 경로:** `build/app/outputs/flutter-apk/app-release.apk`

### 🍎 iOS (IPA Build)
```bash
flutter build ipa --export-method=development
```
* **결과물 경로:** `build/ios/ipa/Runner.ipa`

### 🌐 Web (GitHub Pages Deployment)
본 프로젝트는 GitHub Actions를 통해 `main` 브랜치 푸시 시 웹 빌드가 자동 배포되도록 구성되어 있습니다.
* **CI/CD 워크플로우:** `.github/workflows/deploy.yml`
* **설정 방법**: GitHub 저장소의 **Settings -> Pages -> Build and deployment -> Source** 항목을 **`GitHub Actions`**로 설정하면 자동으로 배포됩니다.
