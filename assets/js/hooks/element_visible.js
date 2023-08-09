const ElementVisible = {
  mounted() {
    hook = this

    const observer = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting === true) {
        console.log("visible")
        hook.pushEvent("next-page", {})
      }
    }, { threshold: [0] });

    observer.observe(this.el);
  },
};

export default ElementVisible;
