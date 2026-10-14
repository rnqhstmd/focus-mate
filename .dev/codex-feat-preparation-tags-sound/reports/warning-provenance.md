# 기존 경고 재출력 근거

최종GREEN baseline 숫자0 유지. 초기 전체 build(동일명령)에서 이미 관측된 CardIssuanceView.swift14 actor warning. T2재컴파일 출력에도동일라인, 해당원본파일W03 diff 없음. cache재출력은 신규경고로판정하지않되 W03신규경고는별도차단.
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMate/CardIssuanceView.swift:14:52: warning: main actor-isolated static property 'failedAnnouncement' can not be referenced from a nonisolated context; this is an error in the Swift 6 language mode
    |                                                    `- warning: main actor-isolated static property 'failedAnnouncement' can not be referenced from a nonisolated context; this is an error in the Swift 6 language mode
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMate/CardIssuanceView.swift:14:52: warning: main actor-isolated static property 'failedAnnouncement' can not be referenced from a nonisolated context; this is an error in the Swift 6 language mode
    |                                                    `- warning: main actor-isolated static property 'failedAnnouncement' can not be referenced from a nonisolated context; this is an error in the Swift 6 language mode
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMate/CardIssuanceView.swift:14:52: warning: main actor-isolated static property 'failedAnnouncement' can not be referenced from a nonisolated context; this is an error in the Swift 6 language mode
    |                                                    `- warning: main actor-isolated static property 'failedAnnouncement' can not be referenced from a nonisolated context; this is an error in the Swift 6 language mode
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMate/CardIssuanceView.swift:14:52: warning: main actor-isolated static property 'failedAnnouncement' can not be referenced from a nonisolated context; this is an error in the Swift 6 language mode
    |                                                    `- warning: main actor-isolated static property 'failedAnnouncement' can not be referenced from a nonisolated context; this is an error in the Swift 6 language mode
2026-10-14 09:17:36.591 appintentsmetadataprocessor[43951:20171512] warning: Metadata extraction skipped, no AppIntents.framework dependency found
