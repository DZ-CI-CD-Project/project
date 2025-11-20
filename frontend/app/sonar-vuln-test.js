// // 테스트용 취약 코드 - 실제 서비스에서는 절대 사용 금지!

// const searchParams = new URLSearchParams(window.location.search);
// const payload = searchParams.get('payload');

// if (payload) {
//   // 사용자 입력을 그대로 eval에 전달 (CWE-95)
//   eval(payload);
// }

// const serializedFunction = searchParams.get('fn');
// if (serializedFunction) {
//   // Function 생성자를 통한 동적 실행 (CWE-96)
//   const dynamicFunc = new Function(serializedFunction);
//   dynamicFunc();
// }

// function insecureTemplate(user) {
//   const template = `<div>${user}</div>`;
//   document.body.insertAdjacentHTML('beforeend', template);
// }

// // 사용되지 않는 변수와 함수를 다수 정의하여 Code Smell을 의도적으로 유발
// function smell1() { var unusedVar1; }
// function smell2() { var unusedVar2; }
// function smell3() { var unusedVar3; }
// function smell4() { var unusedVar4; }
// function smell5() { var unusedVar5; }
// function smell6() { var unusedVar6; }
// function smell7() { var unusedVar7; }
// function smell8() { var unusedVar8; }
// function smell9() { var unusedVar9; }
// function smell10() { var unusedVar10; }
// function smell11() { var unusedVar11; }
// function smell12() { var unusedVar12; }
// function smell13() { var unusedVar13; }
// function smell14() { var unusedVar14; }
// function smell15() { var unusedVar15; }
// function smell16() { var unusedVar16; }

