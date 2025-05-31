document.addEventListener("DOMContentLoaded", function () {
  // Mobile Menu Toggle
  const mobileMenuButton = document.getElementById("mobileMenuButton");
  const mobileMenu = document.getElementById("mobileMenu");
  const menuIcon = document.getElementById("menuIcon");
  const closeIcon = document.getElementById("closeIcon");

  mobileMenuButton.addEventListener("click", function () {
    // Toggle menu visibility
    mobileMenu.classList.toggle("hidden");

    // Toggle icons
    menuIcon.classList.toggle("hidden");
    closeIcon.classList.toggle("hidden");
  });

  // Smooth scrolling for anchor links
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener("click", function (e) {
      e.preventDefault();
      const targetId = this.getAttribute("href");
      if (targetId === "#") return;
      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        window.scrollTo({
          top: targetElement.offsetTop - 80, // Adjust for header height
          behavior: "smooth",
        });
        // Close mobile menu if open and reset icons
        if (!mobileMenu.classList.contains("hidden")) {
          mobileMenu.classList.add("hidden");
          menuIcon.classList.remove("hidden");
          closeIcon.classList.add("hidden");
        }
      }
    });
  });
});
