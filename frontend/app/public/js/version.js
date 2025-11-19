// 버전 정보를 VERSION.txt에서 읽어와서 표시
async function loadVersion() {
  try {
    const response = await fetch('/VERSION.txt');
    if (response.ok) {
      const version = await response.text();
      const versionElement = document.getElementById('appVersion');
      if (versionElement) {
        versionElement.textContent = version.trim();
      }
      
      // 모든 버전 요소에 적용
      document.querySelectorAll('#appVersion').forEach(el => {
        el.textContent = version.trim();
      });
    }
  } catch (e) {
    console.warn('버전 정보를 불러올 수 없습니다:', e);
  }
}

document.addEventListener('DOMContentLoaded', loadVersion);

