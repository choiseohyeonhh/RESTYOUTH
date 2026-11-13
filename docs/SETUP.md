# Mac에서 실행하기

처음 한 번만 하면 되는 준비(1–3)와, 코드가 바뀔 때마다 하는 일(4–6)로 나뉩니다.
명령어는 **터미널** 앱(Spotlight에서 "터미널" 검색)에 한 줄씩 붙여 넣고 Enter를 누르면 됩니다.

---

## 처음 한 번만

### 1. Xcode 설치

1. Mac App Store에서 **Xcode**를 검색해 설치합니다. 용량이 커서 시간이 꽤 걸려요.
2. Xcode를 한 번 실행합니다. 추가 구성요소를 설치하라고 하면 설치합니다.
3. 플랫폼 선택 화면이 나오면 **iOS**를 체크합니다. 시뮬레이터가 함께 설치됩니다.

### 2. Homebrew와 XcodeGen 설치

XcodeGen은 `project.yml`을 읽어 Xcode 프로젝트 파일을 만들어 주는 도구입니다.

Homebrew가 없다면 먼저 설치합니다. 안내에 따라 Mac 비밀번호를 입력하고, 마지막에 출력되는 "Next steps" 명령어 두 줄도 그대로 실행하세요.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```bash
brew install xcodegen
```

### 3. 코드 받기

```bash
cd ~/Documents
```

```bash
git clone https://github.com/choiseohyeonhh/RESTYOUTH.git
```

```bash
cd RESTYOUTH
```

---

## 코드가 바뀔 때마다

### 4. 최신 코드 받기

```bash
cd ~/Documents/RESTYOUTH
```

```bash
git fetch origin && git checkout claude/optimistic-keller-xy25hm && git pull
```

### 5. 계산 로직 테스트

```bash
cd Packages/RestCore && swift test; cd ../..
```

마지막에 `Test run with N tests passed`가 나오면 성공입니다.
실패하면 출력 전체를 복사해서 Claude에게 붙여 넣어 주세요.

### 6. 앱 실행

```bash
xcodegen generate
```

```bash
open RestYouth.xcodeproj
```

Xcode가 열리면:

1. 상단 가운데에서 실행 대상을 **iPhone 16** 같은 시뮬레이터로 고릅니다.
2. **⌘R**(또는 왼쪽 위 ▶︎ 버튼)을 누릅니다.
3. 시뮬레이터에 "쉬었음" 앱이 뜨면 성공입니다.

빨간 에러가 나면 왼쪽 패널의 ⚠️ 탭(Issue navigator)에 있는 메시지를 복사해서 Claude에게 보내 주세요.

> `project.yml`이 바뀐 경우에는 꼭 `xcodegen generate`를 다시 실행하세요. 헷갈리면 매번 실행해도 괜찮습니다.

---

## 1단계에서 확인할 것

- [ ] 처음 열면 "쉬는 중 · 0분째"가 표시되고, 바가 지금 시각까지 연두색으로 채워진다
- [ ] **일했음**을 누르면 "일하는 중 · 00:00:01"처럼 초 단위로 올라가고, 버튼이 **일 끝**으로 바뀐다
- [ ] 1분 안에 **일 끝**을 누르면 "1분이 안 돼서 기록하지 않았어요" 토스트가 뜬다
- [ ] 1분 넘게 기다렸다가 **일 끝**을 누르면 바에 회색 칸이 생긴다
- [ ] 일하는 중에 **잠잤음**을 누르면 일이 끝나고 잠이 시작된다
- [ ] 앱을 완전히 껐다 켜도 기록이 남아 있다

> 시뮬레이터에서 시간을 빨리 감을 수는 없어서, 결산·등급 같은 긴 기간 계산은 5번의 테스트로 확인합니다.
