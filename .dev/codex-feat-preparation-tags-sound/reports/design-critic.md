# 설계 비판 검토

MUST-ADDRESS2:
1. confirm후시간/선택변경시oldrequestconsume가능. computedread API및consumefreshpayloadguard로보강필요.
2. 시트마다controller생성하면old60msfade종료전새시트previewoverlap. AppModel수명단일controllerowner로보강필요.
CONSIDER: stalefactorythrow는currentphase/error변경안함,stop멱등성/oldstopTask비취소,한줄UI표현은새newline정책없음,consume후동일payload재confirm은새request.
architect2차보강중. design-critic 읽기전용gpt-6-astra/low.

## 2차 재확인
MUST2모두설계수준해소. freshpayloadgetter/consumeguard,AppModelsingleowner+oldstopTask유지. 근본문제없음. 구현통과판정아님.
