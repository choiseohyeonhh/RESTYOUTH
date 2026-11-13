# 쉬었음

하루 24시간 중 기본값은 '쉼'. 일한 시간과 잔 시간만 기록하는 자학 개그형 iOS 타임트래커.

- 기획서: [docs/PRD.md](docs/PRD.md)
- Mac에서 실행하기: [docs/SETUP.md](docs/SETUP.md)

## 폴더 구조

```
project.yml              XcodeGen 설정 (Xcode 프로젝트는 여기서 생성)
App/                     iOS 앱 (SwiftUI + SwiftData)
  Models/Session.swift   저장 모델
  Services/              버튼 동작, 설정값
  Views/                 메인 화면, 24시간 바, 색
Packages/RestCore/       계산 로직 (UI 없음, `swift test`로 검증)
  Sources/RestCore/
    RestCalculator.swift 쉼/일함/잠, 24시간 바, 무사고 쉼, 날린 일당, 등급
    RestConstants.swift  최저시급·공휴일·등급 기준 (매년 갱신)
    SessionRules.swift   버튼 규칙
docs/                    기획서, 실행 방법
```
