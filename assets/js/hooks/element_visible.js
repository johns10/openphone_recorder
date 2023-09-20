const ElementVisible = {
  mounted() {
    hook = this

    const observer = new IntersectionObserver(function (entries) {
      if (entries[0].isIntersecting === true) {
        hook.pushEvent("next-page", {})
      }
    }, { threshold: [0] });

    observer.observe(this.el);
  },
};

export default ElementVisible;
