export const PreviewScrollAnimation = {
  mounted() {
    this.lastAnimationKey = this.el.dataset.animationKey;
    this.applyAnimation();
  },

  updated() {
    const currentAnimationKey = this.el.dataset.animationKey;

    if (currentAnimationKey !== this.lastAnimationKey) {
      this.lastAnimationKey = currentAnimationKey;
      this.applyAnimation();
    }
  },

  applyAnimation() {
    const content = this.el;
    const container = content.parentElement.parentElement;
    const contentHeight = content.scrollHeight;
    const containerHeight = container.clientHeight;
    const speed = parseFloat(this.el.dataset.speed);
    const basePixelsPerSecond = 100;
    const totalDistance = contentHeight + containerHeight;
    const duration = totalDistance / (basePixelsPerSecond * speed);

    content.style.animation = "none";

    const key = Date.now();
    const style = document.createElement("style");
    style.innerHTML = `
      @keyframes scroll-vertical-${key} {
        0% { transform: translateY(${containerHeight}px); }
        100% { transform: translateY(-${contentHeight}px); }
      }
    `;
    document.head.appendChild(style);

    content.style.animation = `scroll-vertical-${key} ${duration}s linear infinite`;
  },
};

export const ManualTeleprompterScrollAnimation = {
  mounted() {
    this.calculateScrollDuration();
    this.handleResize = () => this.calculateScrollDuration();
    window.addEventListener("resize", this.handleResize);
  },

  destroyed() {
    window.removeEventListener("resize", this.handleResize);
  },

  updated() {
    this.calculateScrollDuration();
  },

  calculateScrollDuration() {
    const container = this.el;
    const content = container.querySelector("#teleprompter-content");

    if (!content) return;

    const contentHeight = content.scrollHeight;
    const viewportHeight = window.innerHeight;

    const totalScrollDistance = contentHeight + viewportHeight;
    const basePixelsPerSecond = 100;
    const baseDuration = totalScrollDistance / basePixelsPerSecond;

    container.style.setProperty("--base-scroll-duration", `${baseDuration}s`);
    container.style.setProperty(
      "--total-scroll-distance",
      `${totalScrollDistance}px`
    );
    container.style.setProperty("--content-height", `${contentHeight}px`);
    container.style.setProperty("--viewport-height", `${viewportHeight}px`);

    content.style.setProperty("--base-scroll-duration", `${baseDuration}s`);
    content.style.setProperty(
      "--total-scroll-distance",
      `${totalScrollDistance}px`
    );
    content.style.setProperty("--content-height", `${contentHeight}px`);
    content.style.setProperty("--viewport-height", `${viewportHeight}px`);
  },
};

export const VoiceTeleprompterScrollAnimation = {
  mounted() {
    this.mediaStream = null;
    this.microphoneActive = false;
    this.recognition = null;
    this.spokenIndex = 0;
    this.scriptWords = [];
    this.scrollSpeed = 0.3;
    this.lastSpokenTime = Date.now();

    this.autoScrollActive = false;
    this.scrollStartTime = null;
    this.scrollAnimationFrame = null;
    this.wordsPerSecond = 2.3;
    this.currentScrollPosition = 0;

    this.handleEvent("request_microphone_permission", () => {
      this.requestMicrophoneAccess();
    });

    this.handleEvent("activate_microphone", () => {
      this.activateMicrophone();
    });

    this.handleEvent("deactivate_microphone", () => {
      this.deactivateMicrophone();
    });

    window.addEventListener("beforeunload", () => {
      this.cleanup();
    });
  },

  destroyed() {
    this.cleanup();
  },

  disconnected() {
    this.cleanup();
  },

  async requestMicrophoneAccess() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: false,
      });
      stream.getTracks().forEach((track) => track.stop());
      this.pushEvent("microphone_permission_granted", {});
    } catch (error) {
      console.error("Microphone access denied:", error);
    }
  },

  async activateMicrophone() {
    try {
      if (this.microphoneActive) return;

      this.mediaStream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: false,
      });

      this.microphoneActive = true;
      this.pushEvent("microphone_activated", {});

      this.initSpeechRecognition();
    } catch (error) {
      console.error("Failed to activate microphone:", error);
    }
  },

  deactivateMicrophone() {
    if (this.recognition) {
      try {
        this.recognition.stop();
      } catch (error) {
        console.warn("Error stopping speech recognition:", error);
      }
    }
    if (this.mediaStream)
      this.mediaStream.getTracks().forEach((track) => track.stop());

    this.microphoneActive = false;
    this.recognition = null;
    this.scriptWords = [];
    this.spokenIndex = 0;
    this.stopAutoScroll();
    this.pushEvent("microphone_deactivated", {});
  },

  initSpeechRecognition() {
    const SpeechRecognition =
      window.SpeechRecognition || window.webkitSpeechRecognition;

    if (!SpeechRecognition) {
      console.error("SpeechRecognition not supported in this browser.");
      return;
    }

    this.recognition = new SpeechRecognition();
    this.recognition.lang = "en-US";
    this.recognition.continuous = true;
    this.recognition.interimResults = true;

    const content = document.getElementById("teleprompter-content");
    const rawText = content.innerText.trim();
    this.scriptWords = rawText.split(/\s+/);

    this.recognition.onresult = (event) => {
      const result = event.results[event.results.length - 1][0].transcript
        .toLowerCase()
        .trim();

      const resultWords = result.split(/\s+/);
      let matched = false;

      for (const word of resultWords) {
        const expected = this.scriptWords[this.spokenIndex]?.toLowerCase();
        if (!expected) break;

        if (word === expected) {
          this.highlightWord(this.spokenIndex);
          this.spokenIndex++;
          this.lastSpokenTime = Date.now();
          matched = true;
        } else if (
          expected.includes(word) ||
          word.includes(expected) ||
          levenshteinDistance(word, expected) <= 2
        ) {
          this.highlightWord(this.spokenIndex);
          this.spokenIndex++;
          this.lastSpokenTime = Date.now();
          matched = true;
        }
      }

      if (matched) {
        if (!this.autoScrollActive && this.spokenIndex > 0) {
          this.startAutoScroll();
        }

        this.updateReadingSpeed();
      }
    };

    this.recognition.onerror = (e) => {
      console.warn("Speech recognition error:", e);
    };

    this.recognition.onend = () => {
      if (this.microphoneActive) {
        this.recognition.start();
      }
    };

    this.recognition.start();
  },

  startAutoScroll() {
    if (this.autoScrollActive) return;

    this.autoScrollActive = true;
    this.scrollStartTime = Date.now();

    const container = document.getElementById("teleprompter-container");
    if (container) {
      this.currentScrollPosition = container.scrollTop;
    }

    this.performAutoScroll();
  },

  stopAutoScroll() {
    this.autoScrollActive = false;
    if (this.scrollAnimationFrame) {
      cancelAnimationFrame(this.scrollAnimationFrame);
      this.scrollAnimationFrame = null;
    }
  },

  updateReadingSpeed() {
    if (!this.scrollStartTime || this.spokenIndex === 0) return;

    const timeElapsed = (Date.now() - this.scrollStartTime) / 1000; // in seconds
    if (timeElapsed > 0) {
      this.wordsPerSecond = Math.max(
        0.5,
        Math.min(5.0, this.spokenIndex / timeElapsed)
      );
    }
  },

  performAutoScroll() {
    if (!this.autoScrollActive) return;

    const container = document.getElementById("teleprompter-container");
    const content = document.getElementById("teleprompter-content");

    if (!container || !content) {
      this.scrollAnimationFrame = requestAnimationFrame(() =>
        this.performAutoScroll()
      );
      return;
    }

    const containerHeight = container.clientHeight;
    const contentHeight = content.scrollHeight;
    const maxScroll = contentHeight - containerHeight;

    if (maxScroll <= 0) {
      this.scrollAnimationFrame = requestAnimationFrame(() =>
        this.performAutoScroll()
      );
      return;
    }

    const progressRatio = this.spokenIndex / this.scriptWords.length;
    const targetScrollPosition = Math.min(maxScroll, progressRatio * maxScroll);

    const currentScroll = container.scrollTop;
    const scrollDifference = targetScrollPosition - currentScroll;

    const easingFactor = 0.05;
    const newScrollPosition = currentScroll + scrollDifference * easingFactor;

    container.scrollTop = newScrollPosition;

    this.scrollAnimationFrame = requestAnimationFrame(() =>
      this.performAutoScroll()
    );
  },

  highlightWord(index) {
    const content = document.getElementById("teleprompter-content");

    if (!content.dataset.wordWrapped) {
      const fragment = document.createDocumentFragment();
      const textNodes = [];

      function getTextNodes(node) {
        if (node.nodeType === Node.TEXT_NODE) {
          textNodes.push(node);
        } else {
          node.childNodes.forEach((child) => getTextNodes(child));
        }
      }
      getTextNodes(content);

      let wordIndex = 0;

      textNodes.forEach((textNode) => {
        const text = textNode.textContent;
        const parent = textNode.parentNode;
        const words = text.split(/(\s+)/);

        const spans = words.map((word) => {
          if (word.trim() === "") {
            return document.createTextNode(word);
          } else {
            const span = document.createElement("span");
            span.textContent = word;
            span.className = "teleprompter-word";
            span.dataset.index = wordIndex++;
            return span;
          }
        });

        const wrapper = document.createElement("span");
        spans.forEach((span) => wrapper.appendChild(span));
        parent.replaceChild(wrapper, textNode);
      });

      content.dataset.wordWrapped = "true";
    }

    const spans = content.querySelectorAll(".teleprompter-word");
    spans.forEach((span) => {
      span.style.color = "";
      span.style.backgroundColor = "";
    });

    const currentSpan = content.querySelector(
      `.teleprompter-word[data-index="${index}"]`
    );
    if (currentSpan) {
      currentSpan.style.backgroundColor = "teal";
      currentSpan.style.color = "white";
    }
  },

  adjustScroll() {
    const container = document.getElementById("teleprompter-container");
    const content = document.getElementById("teleprompter-content");

    if (!container || !content) return;

    const currentWordElement = content.querySelector(
      `.teleprompter-word[data-index="${this.spokenIndex - 1}"]`
    );

    if (!currentWordElement) return;

    const rect = currentWordElement.getBoundingClientRect();
    const containerRect = container.getBoundingClientRect();

    if (rect.top > containerRect.top + containerRect.height * 0.5) return;

    container.scrollTo({
      top: currentWordElement.offsetTop - containerRect.height / 2,
      behavior: "smooth",
    });
  },

  cleanup() {
    this.stopAutoScroll();
    this.deactivateMicrophone();
  },
};

function levenshteinDistance(a, b) {
  const matrix = Array(b.length + 1)
    .fill(null)
    .map(() => Array(a.length + 1).fill(0));

  for (let i = 0; i <= a.length; i++) matrix[0][i] = i;
  for (let j = 0; j <= b.length; j++) matrix[j][0] = j;

  for (let j = 1; j <= b.length; j++) {
    for (let i = 1; i <= a.length; i++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[j][i] = Math.min(
        matrix[j - 1][i] + 1,
        matrix[j][i - 1] + 1,
        matrix[j - 1][i - 1] + cost
      );
    }
  }

  return matrix[b.length][a.length];
}
