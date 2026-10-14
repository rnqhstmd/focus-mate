# 커밋 훅 차단

- 실제 대상 브랜치 codex/feat-preparation-tags-sound, 실제 workdir은 W03 전용 worktree.
- main 채팅에서 exec_command(workdir=...)와 git -C 대상 모두 hook G1에 차단됨.
- 설치 pre-tool-guard.sh:145-151은 현재 cwd의 branch가 비어 있을 때만 git -C 경로를 참조. current cwd가 main이므로 대상 path를 무시하고 main 커밋으로 잘못 판정.
- 훅 무력화·환경변수 disable·다른 명령명으로 우회하지 않음. plan staged만, 커밋 안됨.
- 구현·검증 이후 실제 대상 저장소 컨텍스트를 검사하도록 훅 수정 또는 올바른 thread cwd 설정이 필요.

## 해소

사용자 최종 제출·머지 지시 후 준비한 대상 경로 판정 수정 적용. 설치된 훅의 문법 및 6개 회귀 PASS. main 보호와 TDD 검증 게이트 유지. 프로젝트 코드 지문 8ac11c3:35c701670524 일치.
