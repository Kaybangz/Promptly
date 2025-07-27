import Trix from "trix";

export default {
  mounted() {
    const element = document.querySelector("trix-editor");

    element.editor.element.addEventListener("trix-change", (e) => {
      this.el.dispatchEvent(new Event("change", { bubbles: true }));
    });
  },
};
