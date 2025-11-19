// SonarQube 보안 테스트를 위한 의도적인 취약 패턴 (eval)
function runFromHash() {
  const untrustedCode = window.location.hash.substring(1);
  // 의도적으로 사용자 입력을 eval로 실행
  // 실제 코드에서는 절대 사용하지 말 것!
  eval(untrustedCode);
}

runFromHash();

