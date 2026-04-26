function setStreakCount(count) {
  const streakCountEl = document.getElementById("streakCount");
  const fireIconEl = document.getElementById("fireIcon");

  if (!streakCountEl || !fireIconEl) return;

  const n = Number.isFinite(count) ? count : Number.parseInt(String(count), 10);
  const safe = Number.isFinite(n) && n > 0 ? n : 0;

  streakCountEl.textContent = String(safe);
  fireIconEl.classList.toggle("nav__fire--lit", safe > 0);
}

// Demo default. In your real app, set window.streakCount from server/user data.
window.streakCount = window.streakCount ?? 0;
setStreakCount(window.streakCount);

// Optional helper for console testing: setStreakCount(5)
window.setStreakCount = setStreakCount;

