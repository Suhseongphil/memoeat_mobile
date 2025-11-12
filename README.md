# MemoEat Mobile

MemoEat의 모바일 앱 버전입니다. Flutter로 개발되었으며, 웹 버전과 동일한 Supabase 데이터베이스를 공유합니다.

## 주요 기능

- ✅ 인증 시스템 (로그인, 회원가입, 비밀번호 재설정)
- ✅ 관리자 승인 시스템
- ✅ 폴더 기반 메모 관리
- ✅ 리치 텍스트 에디터 (Flutter Quill)
- ✅ 다중 탭 지원
- ✅ 자동 저장 (2초 디바운스)
- ✅ 즐겨찾기, 검색, 휴지통
- ✅ 다크 모드 지원 (웹 버전과 동일한 테마)
- ✅ 드래그 앤 드롭 (폴더/메모 이동)

## 설정

### 1. 환경 변수 파일 생성

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
ADMIN_EMAIL=admin@example.com
```

**중요**: `.env` 파일은 `.gitignore`에 포함되어 있어 Git에 커밋되지 않습니다. 실제 값은 각자 설정해야 합니다.

### 2. Supabase 설정

1. [Supabase](https://supabase.com)에서 프로젝트를 생성합니다.
2. 프로젝트 설정에서 URL과 Anon Key를 확인합니다.
3. `.env` 파일에 위 값들을 입력합니다.

### 3. 관리자 이메일 설정

`.env` 파일의 `ADMIN_EMAIL`에 관리자 이메일을 설정하면, 해당 이메일로 회원가입한 사용자는 자동으로 승인됩니다.

## 실행

### 패키지 설치

```bash
flutter pub get
```

### 에뮬레이터로 실행

#### 1. 사용 가능한 에뮬레이터 확인

```bash
flutter emulators
```

#### 2. 에뮬레이터 실행

```bash
# Android 에뮬레이터 실행
flutter emulators --launch <emulator_id>

# 예시
flutter emulators --launch Medium_Phone_API_36.1
```

또는 Android Studio에서 직접 에뮬레이터를 실행할 수도 있습니다.

#### 3. 앱 실행

에뮬레이터가 실행된 후:

```bash
# 자동으로 연결된 디바이스에 실행
flutter run

# 특정 디바이스 지정
flutter run -d <device_id>

# 실행 중인 디바이스 확인
flutter devices
```

### 웹 브라우저로 실행

```bash
flutter run -d chrome
# 또는
flutter run -d edge
```

### Windows 데스크톱으로 실행

```bash
flutter run -d windows
```

## 프로젝트 구조

```
lib/
├── config/          # 설정 파일 (테마, Supabase)
├── models/          # 데이터 모델
├── services/        # 비즈니스 로직 (Supabase 통신)
├── providers/       # 상태 관리 (Provider)
├── screens/         # 화면
├── widgets/         # 재사용 가능한 위젯
│   ├── editor/      # 에디터 관련 위젯
│   ├── sidebar/     # 사이드바 관련 위젯
│   ├── folder_tree/ # 폴더 트리 위젯
│   └── note_list/   # 메모 목록 위젯
└── utils/           # 유틸리티 함수
```

## 기술 스택

- **Flutter**: 모바일 앱 프레임워크
- **Supabase**: 백엔드 (인증, 데이터베이스)
- **Provider**: 상태 관리
- **GoRouter**: 라우팅
- **Flutter Quill**: 리치 텍스트 에디터
- **SharedPreferences**: 로컬 저장소

## 데이터베이스 스키마

웹 버전과 동일한 Supabase 데이터베이스를 사용합니다:

- `user_approvals`: 사용자 승인 정보
- `folders`: 폴더 정보
- `notes`: 메모 정보

## 라이선스

이 프로젝트는 MemoEat 프로젝트의 일부입니다.
