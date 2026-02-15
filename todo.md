# GitRobotFactory TODO

## 현재 작업

## 완료 (최근)
- [x] 깔끔한 레이아웃 및 디자인 개선 (2026-02-15)
  - [x] 패널 폭 조정
    - leftWidth: 500 → 600 (+100px)
    - rightWidth: 700 → 600 (-100px)
  - [x] Y 위치 재조정 (더 여유롭게)
  - [x] UI 스타일 개선
    - Goal Label: 전체 폭 활용, 둥근 배경
    - Instruction: 높이 증가, 더 진한 배경
    - TODO Checklist: 패널 배경, 진행률 퍼센트 표시
    - File System: 섹션별 배경 색상, 상태 뱃지
    - File Row: 배경, 상태 뱃지, 큰 버튼
  - [x] 색상 일관성
    - Working Directory: 오렌지
    - Staging Area: 초록
    - Commit: 파랑
- [x] 왼쪽 패널 레이아웃 재조정 (2026-02-15)
  - [x] Y 위치 상수 정의
    - goalLabelY: -20
    - instructionY: -75
    - todoChecklistY: -165
    - fileSystemY: -285
    - assemblyZoneY: terminal + 150
  - [x] 모든 UI 요소에 적용
  - [x] 겹침 방지
- [x] 페이즈 진행 TODO 체크리스트 (2026-02-15)
  - [x] Phase별 TODO 항목 정의
    - [x] dragPart, stage, commitMessage, commit
  - [x] TODO UI 표시 (instruction 영역 하단)
  - [x] 완료 시 체크 표시 (⬜ → ✅)
  - [x] 진행률 표시 (N/4)
  - [x] 모든 TODO 완료 시 완료 알림
  - [x] 각 행동 완료 시 자동 체크

## 완료 (최근)
- [x] 클릭으로 튜토리얼 닫기 (2026-02-14)
  - [x] 화면 아무 곳이나 클릭하면 포커싱 제거
  - [x] "클릭하면 닫을 수 있어요" 힌트 추가
  - [x] 메시지 박스 높이 증가 (80 → 90)
- [x] 튜토리얼 인터랙션 개선 (2026-02-14)
  - [x] hideTutorial() 메서드 추가 (페이드 아웃)
  - [x] 사용자가 행동 **시작**하면 포커싱 제거
    - [x] 드래그 시작 시 (mouseDown)
    - [x] Stage 버튼 클릭 시
    - [x] 커밋 메시지 박스 클릭 시
    - [x] Commit 버튼 클릭 시
  - [x] 사용자가 행동 **완료**하면 다음 단계 표시
    - [x] 드롭 완료 → Step 2
    - [x] Stage 완료 → Step 4
    - [x] 메시지 입력 → Step 6
    - [x] Commit 완료 → 튜토리얼 종료
- [x] Mission 1 튜토리얼 시스템 (2026-02-14)
  - [x] 6단계 튜토리얼 구현
    - [x] Step 1: 부품 드래그 앤 드롭
    - [x] Step 2: Working Directory 확인
    - [x] Step 3: Stage 버튼 클릭
    - [x] Step 4: Staging Area 확인
    - [x] Step 5: 커밋 메시지 입력
    - [x] Step 6: Commit 버튼 클릭
  - [x] 단계별 가이드 UI (메시지 박스)
  - [x] UI 요소 하이라이트 (노란색 테두리 + Glow)
  - [x] 반투명 오버레이로 포커스
  - [x] 애니메이션 화살표 (펄스 효과)
  - [x] 사용자 행동 감지 및 자동 진행
  - [x] Mission 1 전용 활성화

## 완료 (최근)
- [x] Clean Working Tree 구현 (2026-02-14)
  - [x] 파일 초기 상태를 committed로 설정 (clean state)
  - [x] Working Directory는 변경된 파일만 표시
  - [x] 변경사항 없을 때 "✓ 변경사항 없음 (clean)" 표시
  - [x] Staging Area 메시지 개선
- [x] Staging Area 버그 수정 (2026-02-14)
  - [x] handleDrop에서 파일 상태 업데이트 추가
  - [x] 드래그 앤 드롭 후 Working Directory에 변경사항 표시
  - [x] 커밋 후 자동으로 다음 phase 진행
- [x] Git 파일 시스템 & Staging Area UI (2026-02-14)
  - [x] 파일 목록 패널 (머리.txt, 몸통.txt, 팔.txt, 다리.txt, 백팩.txt)
  - [x] Working Directory 섹션 (변경된 파일 표시)
  - [x] Staging Area 섹션 (Stage된 파일 표시)
  - [x] 파일 상태 표시 (M: Modified, A: Added, ??: Untracked)
  - [x] Stage ↑ / Unstage ↓ 버튼
  - [x] 커밋 메시지 입력 다이얼로그
  - [x] Commit 버튼 (Stage된 파일이 있을 때만 활성화)
  - [x] git add, git restore --staged 명령어 터미널 표시
  - [x] 실제 Git 워크플로우 시뮬레이션

## 완료 (최근)
- [x] 드래그 앤 드롭 전용 모드 (2026-02-14)
  - [x] 클릭/탭으로 부품 설치 비활성화
  - [x] 드래그 앤 드롭만으로 부품 설치 가능
  - [x] 힌트 텍스트 업데이트
- [x] UI 레이아웃 정리 (2026-02-14)
  - [x] Top bar 높이 증가 (50 → 80)
  - [x] Git 툴바를 top bar 안으로 이동
  - [x] Goal indicators 위치 조정
  - [x] Instruction area 위치 조정
  - [x] Git workflow UI 위치 조정
  - [x] Assembly zone 위치 조정
  - [x] Branch badge, phase counter, stars 위치 재배치
  - [x] 버튼 크기 및 간격 최적화
- [x] Git 고급 기능 추가 (2026-02-14)
  - [x] 상단 Git 툴바 UI 추가 (7개 버튼)
  - [x] Undo (git reset) - 마지막 작업 취소
  - [x] Redo (git reset HEAD@{1}) - 취소한 작업 복구
  - [x] Pull (git pull) - 원격 저장소에서 가져오기
  - [x] Push (git push) - 원격 저장소에 올리기
  - [x] Branch (git checkout -b) - 브랜치 생성 UI
  - [x] Stash (git stash) - 작업 임시 저장
  - [x] Pop (git stash pop) - 임시 저장 복원
  - [x] 알림 시스템 추가
  - [x] Git history 트래킹
  - [x] 버튼 활성화/비활성화 상태 관리

- [x] Git Staging Area 개념 추가
  - [x] Git 상태 관리 (waiting/modified/staged/committed)
  - [x] 부품 선택 시 Working Directory 상태로 표시
  - [x] "Stage" 버튼 추가 (git add)
  - [x] "Commit" 버튼 추가 (git commit)
  - [x] 상태 시각화 (Modified → Staged → Committed)
  - [x] Terminal에 git add, git commit 각각 표시
  - [x] handlePartSelected, handleEmergencyFix에 적용

## 완료 (최근)
- [x] 미션 목표 지점 시각화 (2026-02-14)
  - [x] 목표 슬롯에 노란색 펄스 하이라이트
  - [x] 슬롯을 가리키는 화살표 애니메이션
  - [x] 상단에 목표 라벨 표시 ("🎯 목표: ...")
  - [x] 액션별 목표 표시 (부품 장착, 워크스테이션, 병합 등)
- [x] 드래그 앤 드롭 버그 수정 (2026-02-14)
  - [x] PartCardNode의 isUserInteractionEnabled 비활성화
  - [x] GameScene의 드래그 앤 드롭 로직 우선 사용
  - [x] 클릭과 드래그 모두 지원하도록 개선
  - [x] 힌트 텍스트 변경 (클릭 → 드래그)

## 완료
- [x] Git Graph 브랜치 분기 시각화 개선
  - [x] 브랜치별 lane (x 위치) 할당
  - [x] 분기/병합 시 곡선 연결선 추가
  - [x] 브랜치 생명주기 추적
- [x] 개발자 모드 추가
  - [x] GameData에 devMode 플래그 추가
  - [x] TitleScene에서 로봇 5번 탭으로 개발자 모드 토글
  - [x] 개발자 모드 활성화 시 모든 미션 잠금 해제
  - [x] 시각적 인디케이터 표시
- [x] 드래그 앤 드롭으로 부품 조립 기능 추가
  - [x] Phase 1: 기본 드래그 감지
  - [x] Phase 2: Ghost 카드 생성
  - [x] Phase 3: 슬롯 판정 및 하이라이트
  - [x] Phase 4: 드롭 처리
  - [x] Phase 5: 빌드 테스트 완료
