import SpriteKit

// MARK: - Robot Part
struct RobotPart {
    let id: String
    let name: String
    let emoji: String
    let slot: PartSlot
    let portId: String?
}

enum PartSlot: String, CaseIterable {
    case head, torso, leftArm, rightArm, legs, backpack
    var label: String {
        switch self { case .head: return "머리"; case .torso: return "몸통"; case .leftArm: return "왼팔"; case .rightArm: return "오른팔"; case .legs: return "다리"; case .backpack: return "백팩" }
    }
}

// MARK: - Assembly Action
enum AssemblyAction {
    case pickPart([RobotPart])
    case openWorkstation(String)
    case installPart(RobotPart)
    case mergeParts(from: String, to: String)
    case resolveConflict(partA: RobotPart, partB: RobotPart)
    case tagVersion(String)
    case shipRobot
    case cleanupLine(String)
    case emergencyFix(RobotPart)
}

// MARK: - Mission Phase
struct MissionPhase {
    let instruction: String
    let explanation: String
    let assemblyAction: AssemblyAction
    let gitCommand: String
    let branchContext: String
}

// MARK: - Mission
struct Mission {
    let id: Int
    let chapter: Int
    let chapterTitle: String
    let title: String
    let subtitle: String
    let briefing: String
    let gitLesson: String
    let phases: [MissionPhase]
    let rewardEmoji: String
    let rewardName: String
    let stars: Int
}

// MARK: - Game Data (Singleton)
class GameData {
    static let shared = GameData()
    var completedMissions: Set<Int> = []
    var totalStars = 0
    var collectedRobots: [(emoji: String, name: String)] = []
    var devMode: Bool = false

    func isMissionLocked(_ id: Int) -> Bool {
        // Developer mode: unlock all missions
        if devMode { return false }

        return id > 1 && !completedMissions.contains(id - 1) && !completedMissions.contains(id)
    }
    
    // Parts
    static let basicFrame = RobotPart(id: "frame", name: "기본 프레임", emoji: "🦴", slot: .torso, portId: nil)
    static let armor = RobotPart(id: "armor", name: "외부 장갑", emoji: "🛡️", slot: .torso, portId: nil)
    static let power = RobotPart(id: "power", name: "전원 코어", emoji: "🔋", slot: .torso, portId: nil)
    static let motor = RobotPart(id: "motor", name: "관절 모터", emoji: "⚙️", slot: .rightArm, portId: nil)
    static let gripper = RobotPart(id: "gripper", name: "그리퍼 핸드", emoji: "✋", slot: .rightArm, portId: nil)
    static let irSensor = RobotPart(id: "ir", name: "적외선 센서", emoji: "👁️", slot: .head, portId: nil)
    static let calibChip = RobotPart(id: "calib", name: "센서 보정칩", emoji: "🎯", slot: .head, portId: nil)
    static let biped = RobotPart(id: "biped", name: "이족보행 모듈", emoji: "🚶", slot: .legs, portId: nil)
    static let voice = RobotPart(id: "voice", name: "음성 합성", emoji: "🔊", slot: .head, portId: nil)
    static let laser = RobotPart(id: "laser", name: "레이저 발사기", emoji: "💥", slot: .leftArm, portId: "portA")
    static let shield = RobotPart(id: "shield", name: "에너지 실드", emoji: "🔵", slot: .leftArm, portId: "portA")
    static let walkFix = RobotPart(id: "walkfix", name: "보행속도 조정", emoji: "🔧", slot: .legs, portId: nil)
    static let safety = RobotPart(id: "safety", name: "안전장치", emoji: "✅", slot: .torso, portId: nil)
    static let heatPatch = RobotPart(id: "heat", name: "과열 방지", emoji: "🔥", slot: .head, portId: nil)
    static let firmware = RobotPart(id: "fw", name: "펌웨어 업데이트", emoji: "💾", slot: .head, portId: nil)
    static let neural = RobotPart(id: "neural", name: "신경망 프로세서", emoji: "🔮", slot: .head, portId: nil)
    static let selfLearn = RobotPart(id: "learn", name: "자율학습 모듈", emoji: "📚", slot: .head, portId: nil)
    static let jet = RobotPart(id: "jet", name: "제트 엔진", emoji: "✈️", slot: .backpack, portId: nil)
    static let flightFix = RobotPart(id: "ffix", name: "비행 안정성 패치", emoji: "🔧", slot: .backpack, portId: nil)
    
    // All missions
    static let missions: [Mission] = [
        Mission(id: 1, chapter: 1, chapterTitle: "Ch1: 기본 조립", title: "첫 번째 로봇", subtitle: "Commit 배우기",
                briefing: "출하 창고(main)에서 첫 로봇을 만듭니다.\n부품을 골라 장착하면 작업이 기록(commit)됩니다.", gitLesson: "commit = 작업의 스냅샷",
                phases: [
                    MissionPhase(instruction: "부품 선반에서 '기본 프레임'을 골라 장착하세요", explanation: "첫 번째 커밋: 프로젝트의 첫 기록입니다.", assemblyAction: .pickPart([basicFrame, armor, power]), gitCommand: "git commit -m \"로봇 뼈대 설계\"", branchContext: "main"),
                    MissionPhase(instruction: "'외부 장갑'을 프레임에 씌우세요", explanation: "커밋이 쌓이며 히스토리가 만들어집니다.", assemblyAction: .pickPart([armor, power]), gitCommand: "git commit -m \"외부 프레임 장착\"", branchContext: "main"),
                    MissionPhase(instruction: "'전원 코어'를 장착하세요", explanation: "3개의 커밋 완성! Git 히스토리가 생겼습니다.", assemblyAction: .pickPart([power]), gitCommand: "git commit -m \"전원부 연결\"", branchContext: "main"),
                ], rewardEmoji: "🤖", rewardName: "Basic Frame Bot", stars: 1),
        
        Mission(id: 2, chapter: 1, chapterTitle: "Ch1: 기본 조립", title: "부품 워크스테이션", subtitle: "feature branch",
                briefing: "팔 부품은 별도 워크스테이션(feature)에서 만듭니다.\nmain을 건드리지 않는 독립 작업 공간!", gitLesson: "feature branch = 독립 작업 공간",
                phases: [
                    MissionPhase(instruction: "'feature/arm' 워크스테이션을 여세요", explanation: "main에서 분기! 별도 공간이 생깁니다.", assemblyAction: .openWorkstation("feature/arm"), gitCommand: "git checkout -b feature/arm", branchContext: "main → feature/arm"),
                    MissionPhase(instruction: "'관절 모터'를 장착하세요", explanation: "feature에서 작업. main엔 영향 없음!", assemblyAction: .pickPart([motor, gripper]), gitCommand: "git commit -m \"관절 모터 설치\"", branchContext: "feature/arm"),
                    MissionPhase(instruction: "'그리퍼 핸드'를 부착하세요", explanation: "feature에 2번째 커밋 추가.", assemblyAction: .pickPart([gripper]), gitCommand: "git commit -m \"그리퍼 핸드 부착\"", branchContext: "feature/arm"),
                ], rewardEmoji: "💪", rewardName: "Arm Module", stars: 1),
        
        Mission(id: 3, chapter: 1, chapterTitle: "Ch1: 기본 조립", title: "부품 결합", subtitle: "merge",
                briefing: "팔을 메인 라인(main)에 조립합시다.\n이것이 merge입니다!", gitLesson: "merge = 분기된 작업을 합치기",
                phases: [
                    MissionPhase(instruction: "feature/arm을 main으로 머지하세요", explanation: "feature의 모든 커밋이 main에 합쳐집니다!", assemblyAction: .mergeParts(from: "feature/arm", to: "main"), gitCommand: "git checkout main && git merge feature/arm", branchContext: "main"),
                    MissionPhase(instruction: "'feature/arm' 워크스테이션을 정리하세요", explanation: "merge 후 불필요한 브랜치는 정리!", assemblyAction: .cleanupLine("feature/arm"), gitCommand: "git branch -d feature/arm", branchContext: "main"),
                ], rewardEmoji: "🦾", rewardName: "Armed Robot", stars: 2),
        
        Mission(id: 4, chapter: 2, chapterTitle: "Ch2: 조립 라인", title: "조립 메인 라인", subtitle: "develop branch",
                briefing: "출하 창고(main)에 바로 넣는 건 위험!\ndevelop 조립 라인에서 먼저 통합합니다.", gitLesson: "develop = 개발 통합 브랜치. Git Flow의 핵심!",
                phases: [
                    MissionPhase(instruction: "'develop' 조립 라인을 개설하세요", explanation: "develop 생성: 모든 feature가 여기로 모입니다.", assemblyAction: .openWorkstation("develop"), gitCommand: "git checkout -b develop", branchContext: "main → develop"),
                    MissionPhase(instruction: "'feature/sensor' 워크스테이션을 여세요", explanation: "Git Flow: feature는 develop에서 분기!", assemblyAction: .openWorkstation("feature/sensor"), gitCommand: "git checkout -b feature/sensor", branchContext: "develop → feature/sensor"),
                    MissionPhase(instruction: "'적외선 센서'를 장착하세요", explanation: "feature에서 부품 제작 중.", assemblyAction: .pickPart([irSensor, calibChip]), gitCommand: "git commit -m \"적외선 센서\"", branchContext: "feature/sensor"),
                    MissionPhase(instruction: "센서를 develop에 합치세요", explanation: "feature → develop merge!", assemblyAction: .mergeParts(from: "feature/sensor", to: "develop"), gitCommand: "git checkout develop && git merge feature/sensor", branchContext: "develop"),
                ], rewardEmoji: "👀", rewardName: "Sensor Bot", stars: 2),
        
        Mission(id: 5, chapter: 2, chapterTitle: "Ch2: 조립 라인", title: "병렬 부품 제작", subtitle: "다중 feature",
                briefing: "다리팀과 음성팀이 동시에 작업!\n완성 후 순서대로 develop에 합칩니다.", gitLesson: "여러 feature를 병렬 운용하면 개발 속도 UP!",
                phases: [
                    MissionPhase(instruction: "'feature/legs' 워크스테이션을 여세요", explanation: "첫 번째 병렬 feature!", assemblyAction: .openWorkstation("feature/legs"), gitCommand: "git checkout -b feature/legs", branchContext: "develop → feature/legs"),
                    MissionPhase(instruction: "'이족보행 모듈'을 장착하세요", explanation: "다리 작업 중...", assemblyAction: .pickPart([biped]), gitCommand: "git commit -m \"이족보행 모듈\"", branchContext: "feature/legs"),
                    MissionPhase(instruction: "'feature/voice' 워크스테이션을 여세요", explanation: "두 번째 병렬 feature!", assemblyAction: .openWorkstation("feature/voice"), gitCommand: "git checkout -b feature/voice", branchContext: "develop → feature/voice"),
                    MissionPhase(instruction: "'음성 합성 모듈'을 장착하세요", explanation: "feature/legs와 완전히 독립!", assemblyAction: .pickPart([voice]), gitCommand: "git commit -m \"음성 합성\"", branchContext: "feature/voice"),
                    MissionPhase(instruction: "다리를 develop에 합치세요", explanation: "첫 번째 merge.", assemblyAction: .mergeParts(from: "feature/legs", to: "develop"), gitCommand: "git checkout develop && git merge feature/legs", branchContext: "develop"),
                    MissionPhase(instruction: "음성을 develop에 합치세요", explanation: "두 번째 merge! 둘 다 통합 완료.", assemblyAction: .mergeParts(from: "feature/voice", to: "develop"), gitCommand: "git checkout develop && git merge feature/voice", branchContext: "develop"),
                ], rewardEmoji: "🚶‍♂️", rewardName: "Walking Talker", stars: 2),
        
        Mission(id: 6, chapter: 3, chapterTitle: "Ch3: 충돌 해결", title: "배선 충돌!", subtitle: "merge conflict",
                briefing: "⚠️ 레이저와 실드가 같은 포트를 사용!\n공장장이 직접 해결해야 합니다.", gitLesson: "conflict = 같은 곳을 두 브랜치가 수정. 수동 해결 필요!",
                phases: [
                    MissionPhase(instruction: "'feature/laser' 워크스테이션을 여세요", explanation: "레이저팀 시작!", assemblyAction: .openWorkstation("feature/laser"), gitCommand: "git checkout -b feature/laser", branchContext: "develop → feature/laser"),
                    MissionPhase(instruction: "'레이저 발사기'를 포트A에 설치하세요", explanation: "레이저가 포트A를 사용합니다.", assemblyAction: .installPart(laser), gitCommand: "git commit -m \"레이저 포트A\"", branchContext: "feature/laser"),
                    MissionPhase(instruction: "'feature/shield' 워크스테이션을 여세요", explanation: "방어막팀도 시작!", assemblyAction: .openWorkstation("feature/shield"), gitCommand: "git checkout -b feature/shield", branchContext: "develop → feature/shield"),
                    MissionPhase(instruction: "'에너지 실드'를 포트A에 설치하세요", explanation: "실드도 포트A! 나중에 충돌 발생!", assemblyAction: .installPart(shield), gitCommand: "git commit -m \"실드 포트A\"", branchContext: "feature/shield"),
                    MissionPhase(instruction: "레이저를 먼저 develop에 합치세요", explanation: "레이저 먼저 merge. 아직 OK!", assemblyAction: .mergeParts(from: "feature/laser", to: "develop"), gitCommand: "git checkout develop && git merge feature/laser", branchContext: "develop"),
                    MissionPhase(instruction: "⚡ 충돌! 실드를 포트B로 재배선하세요", explanation: "CONFLICT! 포트A 충돌 → 실드를 포트B로.", assemblyAction: .resolveConflict(partA: laser, partB: shield), gitCommand: "# 충돌 해결\ngit add . && git commit", branchContext: "develop"),
                ], rewardEmoji: "⚔️", rewardName: "Battle Bot", stars: 3),
        
        Mission(id: 7, chapter: 4, chapterTitle: "Ch4: 품질 검사", title: "출하 전 검사", subtitle: "release branch",
                briefing: "QA 전용 라인(release)에서 테스트!\n버그 수정만. 새 기능 금지!", gitLesson: "release = 출시 전 안정화. main + develop 양쪽에 merge!",
                phases: [
                    MissionPhase(instruction: "'release/v1.0' QA 라인을 개설하세요", explanation: "release: develop을 얼려서 테스트.", assemblyAction: .openWorkstation("release/v1.0"), gitCommand: "git checkout -b release/v1.0 develop", branchContext: "develop → release/v1.0"),
                    MissionPhase(instruction: "'보행속도 조정' 패치를 적용하세요", explanation: "release에서는 버그 수정만!", assemblyAction: .pickPart([walkFix]), gitCommand: "git commit -m \"보행속도 조정\"", branchContext: "release/v1.0"),
                    MissionPhase(instruction: "QA 통과! main에 출하하세요", explanation: "release → main 배포!", assemblyAction: .shipRobot, gitCommand: "git checkout main && git merge release/v1.0", branchContext: "main"),
                    MissionPhase(instruction: "v1.0 태그를 부착하세요", explanation: "tag: 이 시점을 영구 기록.", assemblyAction: .tagVersion("v1.0"), gitCommand: "git tag v1.0", branchContext: "main"),
                    MissionPhase(instruction: "수정사항을 develop에도 반영하세요", explanation: "중요! release 수정이 develop에도 필요.", assemblyAction: .mergeParts(from: "release/v1.0", to: "develop"), gitCommand: "git checkout develop && git merge release/v1.0", branchContext: "develop"),
                ], rewardEmoji: "📦", rewardName: "v1.0 Bot", stars: 3),
        
        Mission(id: 8, chapter: 5, chapterTitle: "Ch5: 긴급 수리", title: "고객 긴급 호출!", subtitle: "hotfix",
                briefing: "🚨 출하 로봇에서 결함!\nmain에서 직접 긴급 수리합니다.", gitLesson: "hotfix = main에서 직접 분기. main+develop 양쪽 merge!",
                phases: [
                    MissionPhase(instruction: "'hotfix/eye-spark' 긴급 라인 개설", explanation: "hotfix는 main에서 직접 분기!", assemblyAction: .openWorkstation("hotfix/eye-spark"), gitCommand: "git checkout -b hotfix/eye-spark main", branchContext: "main → hotfix/eye-spark"),
                    MissionPhase(instruction: "🔥 '과열 방지 패치' 긴급 적용!", explanation: "빠르게 원인 제거!", assemblyAction: .emergencyFix(heatPatch), gitCommand: "git commit -m \"과열 방지\"", branchContext: "hotfix/eye-spark"),
                    MissionPhase(instruction: "'펌웨어 업데이트' 적용", explanation: "근본 원인까지 해결!", assemblyAction: .emergencyFix(firmware), gitCommand: "git commit -m \"펌웨어 업데이트\"", branchContext: "hotfix/eye-spark"),
                    MissionPhase(instruction: "수리 완료! main에 배포", explanation: "hotfix → main!", assemblyAction: .shipRobot, gitCommand: "git checkout main && git merge hotfix/eye-spark", branchContext: "main"),
                    MissionPhase(instruction: "v1.0.1 핫픽스 태그", explanation: "패치 버전 태깅.", assemblyAction: .tagVersion("v1.0.1"), gitCommand: "git tag v1.0.1", branchContext: "main"),
                    MissionPhase(instruction: "develop에도 반영 (빠뜨리면 재발!)", explanation: "핵심: hotfix는 양쪽에 merge!", assemblyAction: .mergeParts(from: "hotfix/eye-spark", to: "develop"), gitCommand: "git checkout develop && git merge hotfix/eye-spark", branchContext: "develop"),
                ], rewardEmoji: "🩹", rewardName: "Patched v1.0.1", stars: 3),
        
        Mission(id: 9, chapter: 6, chapterTitle: "Ch6: 풀 Git Flow", title: "🏆 Ultimate Robot", subtitle: "Git Flow 완전 정복",
                briefing: "최종 미션! 모든 전략을 총동원하여\n최강의 AI 비행 로봇을 완성하세요!", gitLesson: "Git Flow = main, develop, feature, release, hotfix 5종 브랜치 전략.",
                phases: [
                    MissionPhase(instruction: "'develop' 조립 라인 가동", explanation: "Git Flow: 항상 develop부터!", assemblyAction: .openWorkstation("develop"), gitCommand: "git checkout -b develop", branchContext: "main → develop"),
                    MissionPhase(instruction: "'feature/ai-brain' 워크스테이션 개설", explanation: "feature는 develop에서!", assemblyAction: .openWorkstation("feature/ai-brain"), gitCommand: "git checkout -b feature/ai-brain", branchContext: "develop → feature/ai-brain"),
                    MissionPhase(instruction: "'신경망 프로세서' 설치", explanation: "AI 두뇌 핵심 부품!", assemblyAction: .pickPart([neural, selfLearn]), gitCommand: "git commit -m \"신경망 프로세서\"", branchContext: "feature/ai-brain"),
                    MissionPhase(instruction: "AI 두뇌를 develop에 합치기", explanation: "feature → develop!", assemblyAction: .mergeParts(from: "feature/ai-brain", to: "develop"), gitCommand: "git checkout develop && git merge feature/ai-brain", branchContext: "develop"),
                    MissionPhase(instruction: "'feature/flight' 개설", explanation: "두 번째 feature!", assemblyAction: .openWorkstation("feature/flight"), gitCommand: "git checkout -b feature/flight", branchContext: "develop → feature/flight"),
                    MissionPhase(instruction: "'제트 엔진' 장착", explanation: "비행 능력!", assemblyAction: .pickPart([jet]), gitCommand: "git commit -m \"제트 엔진\"", branchContext: "feature/flight"),
                    MissionPhase(instruction: "비행 모듈을 develop에 합치기", explanation: "두 번째 merge!", assemblyAction: .mergeParts(from: "feature/flight", to: "develop"), gitCommand: "git checkout develop && git merge feature/flight", branchContext: "develop"),
                    MissionPhase(instruction: "'release/v2.0' QA 시작", explanation: "release: develop에서 분기!", assemblyAction: .openWorkstation("release/v2.0"), gitCommand: "git checkout -b release/v2.0", branchContext: "develop → release/v2.0"),
                    MissionPhase(instruction: "'비행 안정성 패치' 적용", explanation: "release에서 버그만 수정.", assemblyAction: .pickPart([flightFix]), gitCommand: "git commit -m \"비행 안정성\"", branchContext: "release/v2.0"),
                    MissionPhase(instruction: "🎉 v2.0 출하!", explanation: "release → main!", assemblyAction: .shipRobot, gitCommand: "git checkout main && git merge release/v2.0", branchContext: "main"),
                    MissionPhase(instruction: "v2.0 태그 부착", explanation: "버전 기록!", assemblyAction: .tagVersion("v2.0"), gitCommand: "git tag v2.0", branchContext: "main"),
                    MissionPhase(instruction: "release 수정 → develop 반영", explanation: "완벽한 Git Flow 사이클 완성!", assemblyAction: .mergeParts(from: "release/v2.0", to: "develop"), gitCommand: "git checkout develop && git merge release/v2.0", branchContext: "develop"),
                ], rewardEmoji: "🤖", rewardName: "Ultimate AI Robot v2.0", stars: 5),
    ]
}
