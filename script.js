document.addEventListener('DOMContentLoaded', () => {
  if (window.lucide) lucide.createIcons();

  const themeToggle = document.getElementById('theme-toggle');
  const themeIcon = document.getElementById('theme-toggle-icon');
  const themeMeta = document.querySelector('meta[name="theme-color"]');

  const getSystemTheme = () => window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  const getStoredTheme = () => localStorage.getItem('portfolio-theme');
  const setThemeMeta = (theme) => {
    if (themeMeta) themeMeta.content = theme === 'dark' ? '#101418' : '#17233A';
  };
  const applyTheme = (theme) => {
    document.documentElement.setAttribute('data-theme', theme);
    if (themeIcon) themeIcon.setAttribute('data-lucide', theme === 'dark' ? 'sun' : 'moon');
    if (window.lucide) lucide.createIcons();
    setThemeMeta(theme);
  };
  const initTheme = () => {
    const storedTheme = getStoredTheme();
    const theme = storedTheme || getSystemTheme();
    applyTheme(theme);
    if (!storedTheme) {
      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (event) => {
        applyTheme(event.matches ? 'dark' : 'light');
      });
    }
  };

  if (themeToggle) {
    themeToggle.addEventListener('click', () => {
      const current = document.documentElement.getAttribute('data-theme') || getSystemTheme();
      const nextTheme = current === 'dark' ? 'light' : 'dark';
      localStorage.setItem('portfolio-theme', nextTheme);
      applyTheme(nextTheme);
    });
  }

  initTheme();

  /* mobile nav */
  const toggle = document.getElementById('nav-toggle');
  const navLinks = document.getElementById('nav-links');
  const toggleIcon = document.getElementById('nav-toggle-icon');
  toggle.addEventListener('click', () => {
    const isOpen = navLinks.classList.toggle('is-open');
    toggle.setAttribute('aria-expanded', String(isOpen));
    toggleIcon.setAttribute('data-lucide', isOpen ? 'x' : 'menu');
    if (window.lucide) lucide.createIcons();
  });
  navLinks.querySelectorAll('a').forEach(a => a.addEventListener('click', () => {
    navLinks.classList.remove('is-open');
    toggle.setAttribute('aria-expanded', 'false');
    toggleIcon.setAttribute('data-lucide', 'menu');
    if (window.lucide) lucide.createIcons();
  }));

  /* project filters */
  const filterButtons = document.querySelectorAll('.filter-btn');
  const projectCards = document.querySelectorAll('.project-card');

  filterButtons.forEach((button) => {
    button.addEventListener('click', () => {
      const filter = button.dataset.filter;

      filterButtons.forEach((btn) => {
        const isActive = btn === button;
        btn.classList.toggle('is-active', isActive);
        btn.setAttribute('aria-pressed', String(isActive));
      });

      projectCards.forEach((card) => {
        const matches = filter === 'all' || card.dataset.category === filter;
        card.classList.toggle('is-hidden', !matches);
      });
    });
  });

  /* scroll reveal */
  const revealEls = document.querySelectorAll('.reveal');
  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry, i) => {
      if (entry.isIntersecting) {
        setTimeout(() => entry.target.classList.add('is-visible'), i * 60);
        revealObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.15 });
  revealEls.forEach(el => revealObserver.observe(el));

  /* hero KPI cards + count-up */
  const kpis = [
    document.getElementById('kpi-1'),
    document.getElementById('kpi-2'),
    document.getElementById('kpi-3'),
    document.getElementById('kpi-4'),
  ];

  const animateCount = (el) => {
    const target = parseFloat(el.dataset.target);
    const decimals = parseInt(el.dataset.decimals, 10) || 0;
    const duration = 1100;
    const start = performance.now();
    const step = (now) => {
      const p = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - p, 3);
      const val = target * eased;
      el.textContent = decimals > 0
        ? val.toFixed(decimals)
        : Math.round(val).toLocaleString('en-US');
      if (p < 1) requestAnimationFrame(step);
      else el.textContent = decimals > 0 ? target.toFixed(decimals) : target.toLocaleString('en-US');
    };
    requestAnimationFrame(step);
  };

  const heroVisual = document.querySelector('.hero-visual');
  if (heroVisual) {
    const kpiObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          kpis.forEach((card, i) => {
            setTimeout(() => {
              card.classList.add('is-in');
              const counter = card.querySelector('.count');
              if (counter) animateCount(counter);
            }, 350 + i * 220);
          });
          kpiObserver.disconnect();
        }
      });
    }, { threshold: 0.3 });
    kpiObserver.observe(heroVisual);
  }

  /* ============ scroll progress + scrollspy + back-to-top ============ */
  const scrollProgress = document.getElementById('scroll-progress');
  const backToTop = document.getElementById('back-to-top');
  const ringFg = document.getElementById('progress-ring-fg');
  const RING_CIRC = 2 * Math.PI * 19;
  if (ringFg) {
    ringFg.style.strokeDasharray = `${RING_CIRC}`;
    ringFg.style.strokeDashoffset = `${RING_CIRC}`;
  }

  const spySections = document.querySelectorAll('main section[id]');
  const spyLinks = document.querySelectorAll('.nav-links a[href^="#"]');
  const spyObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (!entry.isIntersecting) return;
      const id = entry.target.getAttribute('id');
      spyLinks.forEach((link) => {
        link.classList.toggle('is-active', link.getAttribute('href') === `#${id}`);
      });
    });
  }, { rootMargin: '-45% 0px -50% 0px', threshold: 0 });
  spySections.forEach((section) => spyObserver.observe(section));

  let scrollTicking = false;
  const onScroll = () => {
    if (scrollTicking) return;
    scrollTicking = true;
    requestAnimationFrame(() => {
      const scrollTop = window.scrollY;
      const docHeight = document.documentElement.scrollHeight - window.innerHeight;
      const pct = docHeight > 0 ? Math.min(scrollTop / docHeight, 1) : 0;
      if (scrollProgress) scrollProgress.style.width = `${pct * 100}%`;
      if (ringFg) ringFg.style.strokeDashoffset = `${RING_CIRC * (1 - pct)}`;
      if (backToTop) backToTop.classList.toggle('is-visible', scrollTop > 500);
      scrollTicking = false;
    });
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  if (backToTop) {
    backToTop.addEventListener('click', () => {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
  }

  /* ============ rotating headline word ============ */
  const rotateWord = document.getElementById('rotate-word');
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (rotateWord && !reduceMotion) {
    const words = ['decisions', 'dashboards', 'insights', 'strategy'];
    let wordIndex = 0;
    setInterval(() => {
      rotateWord.classList.add('is-swapping');
      setTimeout(() => {
        wordIndex = (wordIndex + 1) % words.length;
        rotateWord.textContent = words[wordIndex];
        rotateWord.classList.remove('is-swapping');
      }, 350);
    }, 2800);
  }

  /* ============ project card tilt + cursor spotlight ============ */
  const supportsHover = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
  if (supportsHover && !reduceMotion) {
    document.querySelectorAll('.project-card:not(.placeholder)').forEach((card) => {
      let tiltRaf = null;
      card.addEventListener('mouseenter', () => card.classList.add('is-tilting'));
      card.addEventListener('mousemove', (e) => {
        const rect = card.getBoundingClientRect();
        const px = (e.clientX - rect.left) / rect.width;
        const py = (e.clientY - rect.top) / rect.height;
        const rotateY = (px - 0.5) * 10;
        const rotateX = (0.5 - py) * 8;
        if (tiltRaf) cancelAnimationFrame(tiltRaf);
        tiltRaf = requestAnimationFrame(() => {
          card.style.transform = `perspective(900px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-6px)`;
          card.style.setProperty('--mx', `${px * 100}%`);
          card.style.setProperty('--my', `${py * 100}%`);
        });
      });
      card.addEventListener('mouseleave', () => {
        card.classList.remove('is-tilting');
        card.style.transform = '';
      });
    });
  }

  /* ============ copy email to clipboard ============ */
  const toast = document.getElementById('toast');
  let toastTimer = null;
  const showToast = (msg) => {
    if (!toast) return;
    toast.textContent = msg;
    toast.classList.add('is-visible');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('is-visible'), 2200);
  };
  document.querySelectorAll('.copy-btn[data-copy]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const value = btn.dataset.copy;
      try {
        await navigator.clipboard.writeText(value);
        showToast('Email copied to clipboard');
        btn.classList.add('is-copied');
        setTimeout(() => btn.classList.remove('is-copied'), 1500);
      } catch (err) {
        showToast(`Copy this: ${value}`);
      }
    });
  });

  /* contact form -> mailto */
  const form = document.getElementById('contact-form');
  const note = document.getElementById('form-note');
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    if (!form.checkValidity()) {
      form.reportValidity();
      return;
    }
    const name = document.getElementById('cf-name').value.trim();
    const email = document.getElementById('cf-email').value.trim();
    const message = document.getElementById('cf-message').value.trim();
    const subject = encodeURIComponent(`Portfolio enquiry from ${name}`);
    const body = encodeURIComponent(`${message}\n\n— ${name} (${email})`);
    window.location.href = `mailto:khantlynn2012@gmail.com?subject=${subject}&body=${body}`;
    note.textContent = 'Opening your email client…';
  });
});
