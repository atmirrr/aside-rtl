/* aside-rtl: right-to-left support (Persian, Arabic, Hebrew) for Aside's chat UI.
 * A text block gets dir="rtl" when it has more Persian/Arabic/Hebrew letters than Latin letters
 * (code, math and URLs don't count), a majority-letter rule. Blocks are Markdown blocks
 * in replies, plain-text messages and previews, one-line labels such as chat titles (.truncate),
 * the message box and text fields. The script only sets
 * the dir attribute, plus a data-aside-rtl marker so it can undo its own changes; it never touches
 * anything else. */
(() => {
  'use strict';
  if (window.__asideRtl) return;
  window.__asideRtl = true;

  const RTL = /[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]/g;
  const HAS_RTL = /[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]/;
  const LTR = /[A-Za-z\u00C0-\u024F\u0370-\u03FF\u0400-\u04FF]/g;
  const URLS = /(?:https?:\/\/|www\.)\S+/g;
  const BLOCKS = 'p,li,ul,ol,h1,h2,h3,h4,h5,h6,blockquote,table,th,td,dt,dd,summary,figcaption';
  const TARGET = `.streamdown :is(${BLOCKS}), :is(div,p).whitespace-pre-wrap, .truncate`;
  const AREAS = '.streamdown,[data-agent-session-ui],.whitespace-pre-wrap,.truncate';
  const EDITOR = '[contenteditable="true"],[contenteditable=""],[contenteditable="plaintext-only"]';
  const NOT_TEXT = 'pre,code,kbd,samp,.katex,.font-mono,svg,style,script';
  const SKIP = `${NOT_TEXT},textarea,input,${EDITOR}`;
  const FIELD = 'textarea,input:not([type]),input[type=text],input[type=search]';

  // 'rtl', 'ltr', or '' when there are no letters.
  function textDir(s) {
    s = s.replace(URLS, ' ');
    const r = (s.match(RTL) || []).length, l = (s.match(LTR) || []).length;
    return !r && !l ? '' : r > l ? 'rtl' : 'ltr';
  }

  function visibleText(el) {
    let s = '';
    const w = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    for (let n = w.nextNode(); n; n = w.nextNode()) {
      const skip = n.parentElement && n.parentElement.closest(NOT_TEXT);
      if (!skip || !el.contains(skip)) s += n.data;
    }
    return s;
  }

  function setDir(el, d) {
    const own = el.hasAttribute('data-aside-rtl');
    if (!d) {
      if (own) { el.removeAttribute('dir'); el.removeAttribute('data-aside-rtl'); }
      return;
    }
    if (!own && el.hasAttribute('dir')) return; // direction set by Aside itself: leave it
    if (el.getAttribute('dir') !== d) el.setAttribute('dir', d);
    if (!own) el.setAttribute('data-aside-rtl', '');
  }

  function applyBlock(el) {
    if (!el.isConnected || el.closest(SKIP)) return;
    const inRtl = !!(el.parentElement && el.parentElement.closest('[dir="rtl"]'));
    if (!inRtl && !el.hasAttribute('data-aside-rtl') && !HAS_RTL.test(el.textContent)) return;
    let d = textDir(visibleText(el));
    if (d === 'ltr' && !inRtl) d = ''; // left-to-right is the default; only say it inside a Persian block
    setDir(el, d);
  }

  // The message box: the editor's own root element gets the direction (its paragraphs inherit it).
  function applyEditor(el) {
    if (!el.isConnected) return;
    setDir(el, textDir(visibleText(el)) === 'rtl' ? 'rtl' : '');
  }

  function applyField(el) {
    setDir(el, textDir(el.value || '') === 'rtl' ? 'rtl' : '');
  }

  const pending = new Set();
  let scheduled = false;
  function queue(el) {
    pending.add(el);
    if (!scheduled) { scheduled = true; requestAnimationFrame(flush); }
  }
  const depth = (el) => { let d = 0; for (let a = el; a; a = a.parentElement) d++; return d; };
  function flush() {
    scheduled = false;
    const list = [...pending];
    pending.clear();
    list.sort((a, b) => depth(a) - depth(b)); // a list before its items
    for (const el of list) {
      try { if (el.matches(EDITOR)) applyEditor(el); else applyBlock(el); } catch (e) { /* never break the app */ }
    }
  }

  // The blocks a changed node sits in (a word streaming into a list item also changes the list).
  function collect(node) {
    const el = node.nodeType === 1 ? node : node.parentElement;
    if (!el) return;
    const ed = el.closest(EDITOR);
    if (ed) { queue(ed); return; }
    if (!el.closest(AREAS)) return;
    for (let a = el; a && a !== document.body; a = a.parentElement) {
      if (a.matches(TARGET)) queue(a);
      if (a.classList.contains('streamdown') || a.hasAttribute('data-agent-session-ui')) break;
    }
  }

  function scan(root) {
    if (root.nodeType === 1 && (root.matches(TARGET) || root.matches(EDITOR))) queue(root);
    root.querySelectorAll(TARGET).forEach(queue);
    root.querySelectorAll(EDITOR).forEach(queue);
  }

  new MutationObserver((muts) => {
    for (const m of muts) {
      try {
        collect(m.target);
        if (m.type === 'childList') for (const n of m.addedNodes) if (n.nodeType === 1) scan(n);
      } catch (e) { /* never break the app */ }
    }
  }).observe(document.documentElement, { childList: true, subtree: true, characterData: true });

  const onField = (e) => {
    const t = e.target;
    if (t instanceof Element && t.matches(FIELD)) applyField(t);
  };
  document.addEventListener('input', onField, true);
  document.addEventListener('focusin', onField, true);
  scan(document);
})();
