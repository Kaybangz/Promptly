export const TeleprompterControls = {
  mounted() {
    this.hideTimeout = null;
    this.touchTimeout = null;
    this.lastTouchTime = 0;
    this.isMouseMoving = false;
    this.isTouchDevice =
      "ontouchstart" in window || navigator.maxTouchPoints > 0;

    this.hideControls();

    this.handleMouseMove = (e) => {
      if (!this.isTouchDevice) {
        this.showControls();
        this.resetHideTimer();
      }
    };

    this.handleTouch = (e) => {
      if (this.isTouchDevice) {
        const currentTime = Date.now();

        if (currentTime - this.lastTouchTime < 300) {
          e.preventDefault();
        }

        this.lastTouchTime = currentTime;
        this.showControls();
        this.resetTouchTimer();
      }
    };

    this.handleMouseLeave = () => {
      if (!this.isTouchDevice) {
        this.hideControls();
      }
    };

    document.addEventListener("mousemove", this.handleMouseMove);
    document.addEventListener("touchstart", this.handleTouch);
    this.el.addEventListener("mouseleave", this.handleMouseLeave);

    this.el.addEventListener("contextmenu", (e) => e.preventDefault());
  },

  destroyed() {
    document.removeEventListener("mousemove", this.handleMouseMove);
    document.removeEventListener("touchstart", this.handleTouch);
    this.el.removeEventListener("mouseleave", this.handleMouseLeave);

    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout);
    }
    if (this.touchTimeout) {
      clearTimeout(this.touchTimeout);
    }
  },

  showControls() {
    this.pushEvent("show_controls", {});
  },

  hideControls() {
    this.pushEvent("hide_controls", {});
  },

  resetHideTimer() {
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout);
    }

    this.hideTimeout = setTimeout(() => {
      this.hideControls();
    }, 3000);
  },

  resetTouchTimer() {
    if (this.touchTimeout) {
      clearTimeout(this.touchTimeout);
    }

    this.touchTimeout = setTimeout(() => {
      this.hideControls();
    }, 3000);
  },
};
