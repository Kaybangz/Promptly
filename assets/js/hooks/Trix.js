import Trix from "trix";

export default {
  mounted() {
    const element = document.querySelector("trix-editor");

    element.editor.element.addEventListener("trix-change", (e) => {
      this.el.dispatchEvent(new Event("change", { bubbles: true }));
    });

    element.editor.element.addEventListener(
      "trix-attachment-add",
      function (event) {
        if (event.attachment.file) uploadFileAttachment(event.attachment);
      }
    );

    element.editor.element.addEventListener(
      "trix-attachment-remove",
      function (event) {
        removeFileAttachment(event.attachment.attachment.previewURL);
      }
    );
  },
};
