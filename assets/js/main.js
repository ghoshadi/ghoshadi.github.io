(function () {
  const root = document.documentElement;
  const savedTheme = localStorage.getItem("theme");

  if (savedTheme === "dark" || savedTheme === "light") {
    root.setAttribute("data-theme", savedTheme);
  } else {
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    root.setAttribute("data-theme", prefersDark ? "dark" : "light");
  }

  function toggleTheme() {
    const current = root.getAttribute("data-theme");
    const next = current === "dark" ? "light" : "dark";
    root.setAttribute("data-theme", next);
    localStorage.setItem("theme", next);
  }

  document.addEventListener("DOMContentLoaded", function () {
    const button = document.getElementById("theme-toggle");
    if (button) {
      button.addEventListener("click", toggleTheme);
    }
  });
})();

document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll(".pub-summary-toggle").forEach(function (button) {
    button.addEventListener("click", function () {
      const targetId = button.getAttribute("data-target");
      const target = document.getElementById(targetId);
      if (!target) return;

      const isHidden = target.classList.toggle("hidden");
      button.textContent = isHidden ? "Summary" : "Hide summary";
    });
  });
});

/* Normalize accidental CV-link casing on the client side.
   GitHub Pages is case-sensitive; the canonical path is /files/Aditya_CV.pdf. */
document.addEventListener("DOMContentLoaded", function () {
  const canonicalCV = "/files/Aditya_CV.pdf";

  document.querySelectorAll("a[href]").forEach(function (a) {
    try {
      const url = new URL(a.getAttribute("href"), window.location.origin);
      const path = url.pathname.toLowerCase();

      const looksLikeCV =
        path.endsWith("/aditya_cv.pdf") ||
        path.endsWith("/aditya-cv.pdf") ||
        path.endsWith("/cv.pdf") ||
        path.includes("aditya_cv");

      if (looksLikeCV) {
        a.setAttribute("href", canonicalCV);
      }
    } catch (_) {
      // Ignore malformed hrefs.
    }
  });
});

document.addEventListener("DOMContentLoaded", function () {
  document.querySelectorAll(".copy-email").forEach(function (link) {
    link.addEventListener("click", function () {
      const email = link.getAttribute("data-email");
      const hint = link.parentElement.querySelector(".copy-hint");

      if (!email || !navigator.clipboard) return;

      navigator.clipboard.writeText(email).then(function () {
        if (hint) {
          hint.textContent = "Copied";
          window.setTimeout(function () {
            hint.textContent = "";
          }, 1600);
        }
      }).catch(function () {
        // Fall back silently; mailto still works.
      });
    });
  });
});
