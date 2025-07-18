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

export const TeleprompterScrollAnimation = {
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
