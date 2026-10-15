# T3 RED report
Status: DONE
Files: ios/FocusMateTests/JourneyLifecycleModelTests.swift (new, 31 cases), JourneyLifecycleTestDoubles.swift (+LifecycleProbe), BoardingModelTests.swift (AC27 two cases replaced + one added: startTripFromMain false/0 writes, confirmNewJourney done, confirmNewJourney saveFailed).
Code: see the files above (full text lives there).
Cases: AC4 save(90,false), AC31 records unchanged, AC5 double resume, consumeResumeEntry true/false, AC35 fail + retry, AC23 awaiting resume (0 writes), AC24 arrived resume rejected, AC8, AC10 fail + retry, AC11, AC12 x2, AC23/AC24 confirm, no-active confirm rejected, mainStartTitle x2, AC16, AC19, AC20 fail + retry, BR6 x4 (timerPaused false, not on journey, awaiting, arrived), BR10 x2 (open, beginCardCustomization).
Command: cd /Users/bonseung/Documents/ChatGPT/new-w07 && FOCUSMATE_SIMULATOR_ID=113C1ABE-9FC9-48F7-9CA5-60498418C2F1 python3 scripts/check-ios.py test ios/FocusMateTests/JourneyLifecycleModelTests.swift ios/FocusMateTests/BoardingModelTests.swift
Failure: compile errors only for undefined symbols: resumeJourney, consumeResumeEntry, confirmNewJourney, abandonJourney, abandonNotice, mainStartTitle (and derived LifecycleActionResult member inference). No other errors.
Not covered (view/UI layer or not model): AC-7 (no model call), AC-17/18 boundary (JourneyReachTests covers), AC-9/22/28-30 (restart, UI/other).
Referenced: prd.md, design.md (C, T4, R1), JourneyTimerModelTests, BoardingModelTests, BoardingTestDoubles, StorageTestSupport, JourneyReachTests:100-130, CardCustomizationAppModelTests, JourneyLifecycleTestDoubles.
