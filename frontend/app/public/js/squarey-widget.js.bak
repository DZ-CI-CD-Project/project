/* Floating squarey widget injector */
(function () {
  const WIDGET_SRC = '/chrism-site/index.html';
  const state = {
    iframeWindow: null,
    pending: [],
  };

  function clamp01(value) {
    return Math.min(1, Math.max(0, value));
  }

  function buildPointerPayload(x, y) {
    return {
      type: 'squareyPointer',
      ratioX: clamp01(x / window.innerWidth),
      ratioY: clamp01(y / window.innerHeight),
    };
  }

  function sendMessage(payload) {
    if (!payload) return;
    if (state.iframeWindow) {
      state.iframeWindow.postMessage(payload, '*');
    } else {
      state.pending.push(payload);
    }
  }

  function flushQueue() {
    if (!state.iframeWindow || !state.pending.length) return;
    state.pending.forEach((payload) => state.iframeWindow.postMessage(payload, '*'));
    state.pending = [];
  }

  function attachPointerListeners() {
    let lastPointerTime = Date.now();
    let leaveTimeout = null;

    const handleMouseMove = (event) => {
      // 마우스가 문서 영역 밖으로 나갔는지 체크 (주소창, 작업표시줄 등)
      const isOutside = event.clientX < 0 || event.clientY < 0 || 
                       event.clientX > window.innerWidth || event.clientY > window.innerHeight;
      
      if (isOutside) {
        if (leaveTimeout) clearTimeout(leaveTimeout);
        leaveTimeout = setTimeout(() => {
          sendMessage({ type: 'squareySad' });
        }, 100);
        return;
      }

      if (leaveTimeout) {
        clearTimeout(leaveTimeout);
        leaveTimeout = null;
      }

      lastPointerTime = Date.now();
      sendMessage(buildPointerPayload(event.clientX, event.clientY));
    };

    const handleTouchMove = (event) => {
      const touch = event.touches && event.touches[0];
      if (!touch) return;
      
      const isOutside = touch.clientX < 0 || touch.clientY < 0 || 
                       touch.clientX > window.innerWidth || touch.clientY > window.innerHeight;
      
      if (isOutside) {
        if (leaveTimeout) clearTimeout(leaveTimeout);
        leaveTimeout = setTimeout(() => {
          sendMessage({ type: 'squareySad' });
        }, 100);
        return;
      }

      if (leaveTimeout) {
        clearTimeout(leaveTimeout);
        leaveTimeout = null;
      }

      lastPointerTime = Date.now();
      sendMessage(buildPointerPayload(touch.clientX, touch.clientY));
    };

    const handleLeave = () => {
      sendMessage({ type: 'squareySad' });
    };

    // 문서 레벨에서 mouseleave 감지 (주소창, 작업표시줄 등으로 나갈 때)
    document.addEventListener('mouseleave', handleLeave, { passive: true });
    window.addEventListener('mouseleave', handleLeave, { passive: true });
    window.addEventListener('blur', handleLeave);
    
    window.addEventListener('mousemove', handleMouseMove, { passive: true });
    window.addEventListener('touchmove', handleTouchMove, { passive: true });
    
    window.addEventListener('mouseenter', (event) => {
      sendMessage(buildPointerPayload(event.clientX, event.clientY));
    });

    // 마우스가 멈춰있을 때도 주기적으로 체크 (창 밖으로 나갔는지 확인)
    setInterval(() => {
      if (Date.now() - lastPointerTime > 2000) {
        // 2초간 마우스 움직임이 없으면 체크
        const mouseCheck = (e) => {
          if (e.clientX < 0 || e.clientY < 0 || 
              e.clientX > window.innerWidth || e.clientY > window.innerHeight) {
            sendMessage({ type: 'squareySad' });
          }
        };
        document.addEventListener('mousemove', mouseCheck, { once: true, passive: true });
      }
    }, 500);
  }

  function createWidget() {
    if (document.querySelector('.floating-squarey')) return;

    const container = document.createElement('div');
    container.className = 'floating-squarey';

    const iframe = document.createElement('iframe');
    iframe.src = WIDGET_SRC;
    iframe.loading = 'lazy';
    iframe.title = 'Happy cube animation';
    iframe.setAttribute('aria-hidden', 'true');
    iframe.allow = 'autoplay';
    container.appendChild(iframe);

    iframe.addEventListener('load', () => {
      state.iframeWindow = iframe.contentWindow;
      flushQueue();
      sendMessage(buildPointerPayload(window.innerWidth / 2, window.innerHeight / 2));
    });

    document.body.appendChild(container);
    attachPointerListeners();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createWidget, { once: true });
  } else {
    createWidget();
  }
})();