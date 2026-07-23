# Agents Status Bar

[English](README.md) | **한국어**

AI 코딩 에이전트의 남은 쿼터, 계정 또는 로컬 토큰 사용량, API 단가 기준 참고 비용을 한곳에서 확인하는 개인정보 보호 중심의 macOS 메뉴바 앱입니다.

<p align="center">
  <img src="docs/agents-status-bar.png" width="450" alt="Codex, Claude Code 및 Gemini CLI 사용량을 보여주는 Agents Status Bar" />
</p>

> 현재 `main` UI를 기준으로 샘플 값만 사용한 이미지이며 실제 계정정보는 포함하지 않습니다.

## 한눈에 보기

| 영역 | 제공 기능 |
| --- | --- |
| 쿼터 | 남은 비율, 초기화 시각, 제공자 상태, 모델별 한도 및 Codex 한도 초기화 충전권 확인 |
| 토큰과 비용 | Codex 계정의 최신 일일·이번 달·누적 토큰과 제공자별 로컬 사용량을 확인하고, API 환산 참고 비용을 달러 또는 원화로 표시 |
| 메뉴바 | 아이콘, 가장 낮은 잔여량, 월 예상 비용 또는 선택한 제공자 잔여량 표시. Claude는 5시간·일주일·Fable 쿼터 중 선택 가능 |
| 활성 세션 | 알려진 로컬 세션 파일이 갱신되는 동안 메뉴바에서 고정 폭 파형 아이콘 표시 |
| 사용량 기록 | 24시간, 7일 또는 30일 범위의 쿼터와 누적 예상 비용 비교 |
| 알림과 예산 | 제공자별 경고·위험 기준과 선택 가능한 월 예산 알림 |
| 사용자 설정 | 제공자, 언어, 컴팩트 모드, 활동 감지 시간, 통화 및 로그인 시 실행 설정 |
| 유지 관리 | GitHub 릴리스 확인, 모델 가격표 갱신 및 민감정보가 제거된 진단 정보 복사 |

모든 쿼터 비율은 사용한 비율이 아닌 **남은 비율**(`% 남음`)로 표시합니다.

## 설치

현재 배포된 미리보기 버전은 `v0.5.1`입니다. macOS 14 이상과 Apple Silicon이 필요합니다.

### Homebrew

```bash
brew tap 90ms/agents-status-bar https://github.com/90ms/agents-status-bar
brew install --cask 90ms/agents-status-bar/agents-status-bar
open -a "Agents Status Bar"
```

삭제 방법:

```bash
brew uninstall --cask agents-status-bar
brew untap 90ms/agents-status-bar
```

### GitHub Release

[Releases](https://github.com/90ms/agents-status-bar/releases)에서 `AgentsStatusBar-0.5.1.zip`을 내려받아 압축을 풀고 `Agents Status Bar.app`을 `/Applications`로 옮깁니다.

현재 미리보기는 Developer ID 인증서를 사용하지 않는 ad-hoc 서명 빌드입니다. 처음 실행할 때 **시스템 설정 → 개인정보 보호 및 보안**에서 실행을 허용해야 할 수 있습니다.

### 최신 `main` 브랜치 빌드

```bash
git clone https://github.com/90ms/agents-status-bar.git
cd agents-status-bar
./Scripts/test.sh
./Scripts/package_app.sh
open "dist/Agents Status Bar.app"
```

`Scripts/package_app.sh`는 기본적으로 ad-hoc 서명을 사용합니다. 다른 로컬 서명 인증서를 사용하려면 `APP_SIGN_IDENTITY`를 설정하세요.

## 처음 실행하기 전에

모니터링할 커맨드라인 에이전트에 먼저 로그인하세요.

```bash
codex
claude
grok
gemini
opencode
```

설치되어 있고 로그인된 제공자만 데이터를 표시할 수 있습니다. 사용하지 않는 제공자는 **설정 → 일반**에서 끌 수 있습니다.

Claude Code는 OAuth 인증정보를 macOS 키체인에 보관할 수 있습니다. **설정 → 일반 → 제공자 연결 → Claude Code → 연결**에서 사용자가 직접 접근을 승인하세요. 백그라운드 갱신은 키체인 인증 UI를 열지 않으므로 Mac을 잠갔다 풀어도 승인 창이 반복되지 않습니다. 승인한 인증정보는 만료되거나 앱이 종료될 때까지만 메모리에 유지합니다.

## 제공자 지원 현황

| 제공자 | 계정 쿼터 | 토큰 사용량 및 비용 데이터 |
| --- | --- | --- |
| Codex | 주간·모델별 한도와 사용 가능한 한도 초기화 충전권 및 만료일 | 실험적인 Codex app-server에서 가져온 최신 일일·이번 달·누적 계정 토큰과 API 환산 참고 비용 |
| Claude Code | 5시간, 주간 및 모델별 한도 | `~/.claude/projects`에서 오늘의 중복 제거 토큰을 집계하고 캐시 유형별 비용 추정 |
| Grok | 계정 쿼터 미지원 | `~/.grok/sessions`의 현재 컨텍스트 사용량, 비용 추정 미지원 |
| Gemini CLI | 계정 쿼터 미지원 | `~/.gemini/tmp/*/chats`의 최근 세션 토큰, 비용 추정 미지원 |
| OpenCode | 계정 쿼터 미지원 | `~/.local/share/opencode/opencode*.db`의 집계 토큰과 기록된 비용 |

Codex와 Claude는 기존 CLI 로그인을 재사용해 계정 사용량 API를 조회합니다. Codex 계정 토큰 사용량은 실험적인 `codex app-server`의 `account/usage/read` 메서드로 가져오므로, 같은 Codex 계정과 워크스페이스를 사용한 두 Mac에서는 같은 사용량이 표시되어야 합니다. Claude 키체인 접근은 설정에서 사용자가 직접 시작하며 인증정보는 메모리에만 캐시합니다. 계정 조회가 실패하면 임의의 값을 만들지 않고 오래된 상태나 사용 불가 상태를 표시하거나, 검증 가능한 로컬 데이터로 대체합니다.

각 CLI의 파일 형식과 사용량 API는 공개 호환성 규격이 아니므로 변경될 수 있습니다.

## 갱신과 활성 세션 표시

- 쿼터와 사용량은 1분마다 자동으로 갱신합니다.
- 새로고침 버튼은 지원하는 제공자의 캐시를 우회합니다.
- 백그라운드 갱신 중에는 키체인 승인 창을 표시하지 않습니다.
- Codex 계정 응답은 최대 1분만 캐시하며, 확인된 초기화 시각이 지나면 즉시 무효화합니다.
- 설치된 CLI가 실험적인 app-server 메서드를 지원하면 Codex 계정의 최신 일일 버킷·이번 달 버킷·누적 토큰을 로컬 세션 파일과 독립적으로 가져옵니다.
- 최신 일일 행에는 계정 버킷 날짜를 함께 표시하고 로컬 날짜가 바뀐 뒤에도 유지하므로, 지연 도착한 Codex 일일 버킷이 계속 `집계 대기 중`으로 가려지지 않습니다.
- Codex 한도 초기화 충전권은 별도로 갱신하고 최대 5분간 캐시하며, 계정 API가 반환한 보유 수량·종류·만료일을 표시합니다.
- 활성 세션 감지는 3초마다 알려진 세션 파일의 변경 시각만 확인합니다.
- 마지막 쓰기 이후 10초, 15초 또는 30초 동안 활동 상태를 유지하도록 설정할 수 있습니다.
- 메뉴바 파형은 활동 확인 직후 한 번씩 짧게 움직이며 macOS의 동작 줄이기 사용 시 정적으로 표시됩니다.

활동 표시는 로컬 파일 변경 신호입니다. 제공자가 현재 응답을 생성 중임을 보장하지는 않습니다.

## 비용, 환율, 기록 및 예산

비용은 확인 가능한 계정 또는 로컬 토큰 합계를 공개 API 단가로 사용했을 때의 참고 추정액입니다. Codex, Claude, Grok, ChatGPT 또는 Claude 구독의 실제 청구액이나 API 결제 명세가 아닙니다.

Codex 계정 사용량은 정확한 API 비용 계산에 필요한 과거 모델, 입력·출력, 캐시 및 추론 토큰 구분 없이 총 토큰만 제공합니다. 따라서 최신 일일·이번 달·누적 비용은 거친 API 환산 참고값이며, 이 영역에서는 토큰 합계가 기준 데이터입니다.

현재 참고 프로필은 검증된 `gpt-5-codex` 가격표와 캐시되지 않은 입력 80%·출력 20% 가정을 사용합니다. 이 버전 관리되는 가정은 모든 Mac에서 동일하게 적용되지만, 계정의 실제 과거 모델이나 토큰 구성을 의미하지 않습니다.

- 설정에서 USD 또는 KRW를 선택할 수 있습니다.
- USD/KRW는 [Frankfurter](https://frankfurter.dev/)의 ECB 제공자를 통해 한국 시간 기준 하루 한 번 확인합니다.
- 적용 환율과 기준일을 설정에서 확인할 수 있으며 주말과 휴일에는 가장 최근 ECB 환율이 사용될 수 있습니다.
- 버전 관리되는 가격표를 하루 한 번 확인하고 잘못된 스키마, 비정상 가격, 신뢰하지 않는 출처 및 다운그레이드를 거부합니다.
- 쿼터, 토큰 및 예상 비용의 집계 샘플을 15분마다 기록하고 로컬에 30일 동안 보관합니다.
- 메뉴바와 예산의 월 합계는 Codex의 현재 계정 월 참고 비용에 다른 제공자의 로컬 관측 비용 변화를 더합니다.
- 사용량 알림을 켜면 선택한 월 예산의 50%, 80%, 100%에서 알려줍니다.

알 수 없는 모델은 임의의 단가에 연결하지 않고 비용을 표시하지 않습니다. 앱 내장 가격표는 공식 [OpenAI 모델 가격](https://developers.openai.com/api/docs/models)과 [Anthropic 가격](https://platform.claude.com/docs/en/about-claude/pricing)을 기준으로 합니다.

## 설정

| 탭 | 설정 항목 |
| --- | --- |
| 일반 | UI 언어, 제공자, 제공자 연결, 메뉴바 표시, 선택 제공자, Claude 메뉴바 쿼터(5시간/일주일/Fable), 컴팩트 모드, 활동 애니메이션과 감지 시간, 로그인 시 실행, 업데이트 확인 |
| 알림 | 사용량 부족 알림, 경고·위험 기준, 알림 제공자, 테스트 알림 |
| 사용량 | USD/KRW 표시, 적용 환율, 가격표 갱신, 월 예산, 사용량 기록 창 |
| 개인정보 | 로컬 데이터 처리 설명 및 복사 가능한 제공자 진단 정보 |

UI 언어는 시스템 설정을 따르거나 한국어 또는 English로 직접 고정할 수 있습니다.

Codex 버킷과 Claude 메뉴바 선택 동작의 자세한 기준은 [사용량 표시 안내](docs/usage.ko.md)를 참고하세요.

## 업데이트

앱은 6시간마다 GitHub Releases에서 새 안정 버전을 확인하고 사용 가능한 릴리스 링크를 표시합니다. 현재 릴리스는 ad-hoc 서명이므로 다운로드와 설치는 직접 진행합니다. Developer ID 서명, 공증 및 서명된 업데이트 피드를 준비하면 이후 앱 내 자동 설치를 추가할 수 있습니다.

## 개인정보 보호 및 보안

- 프롬프트와 모델 응답을 표시하거나 보관하지 않습니다.
- 액세스 토큰, 리프레시 토큰 및 쿠키를 로그에 남기거나 앱 저장소로 복사하지 않습니다.
- 명시적 승인으로 가져온 Claude 인증정보는 만료되거나 앱이 종료될 때까지만 메모리에 캐시합니다.
- 로컬 파싱은 알려진 집계 사용량 필드, 활동 파일 메타데이터 및 OpenCode 데이터베이스의 집계 열로 제한합니다. Codex 토큰 통계는 로컬 세션 토큰 합계가 아닌 계정 사용량에서 가져옵니다.
- 활동 감지는 프롬프트나 응답 내용이 아닌 파일 메타데이터만 확인합니다.
- 기록에는 집계 비율, 토큰 합계 및 예상 비용만 포함하며 30일 동안 보관합니다.
- 환율과 가격표 캐시에는 공개 데이터와 검증 메타데이터만 저장합니다.
- 한도 초기화 충전권 이력은 저장하지 않고 현재 계정 응답만 표시합니다.
- 진단 정보에서 프롬프트, 응답, 인증정보, 쿠키, 제공자 상세 내용 및 파일 경로를 제외합니다.
- 분석 도구나 텔레메트리를 사용하지 않습니다.

## 구조와 제공자 확장

```text
ProviderRegistry
    ├── CodexUsageProvider    ── 계정 쿼터 + app-server 토큰 사용량
    ├── ClaudeUsageProvider   ── 계정 사용량 + ~/.claude/projects
    ├── GrokUsageProvider     ── ~/.grok/sessions
    ├── GeminiUsageProvider   ── ~/.gemini/tmp/*/chats
    └── OpenCodeUsageProvider ── SQLite 집계 열
               │
               ▼
        ProviderSnapshot
               │
               ▼
           UsageStore
               │
               ▼
       SwiftUI MenuBarExtra
```

`ProviderID`는 확장 가능한 문자열 기반 타입입니다. 새로운 플랫폼을 추가하려면 `UsageProviding`을 구현하고, 인증과 파싱을 제공자 디렉터리에 두고, 민감정보가 제거된 fixture 테스트를 추가한 다음 `ProviderRegistry`에 등록하면 됩니다.

## 개발

```bash
./Scripts/test.sh
swift build
./Scripts/package_app.sh
```

프로젝트에는 fixture 기반 파서 테스트와 macOS GitHub Actions 빌드가 포함되어 있습니다. 기여 규칙은 [AGENTS.md](AGENTS.md)를 참고하세요. README 미리보기의 편집 가능한 원본은 [docs/agents-status-bar.svg](docs/agents-status-bar.svg)입니다.

## 라이선스

[MIT](LICENSE)
