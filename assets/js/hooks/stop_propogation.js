const StopPropogation = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      console.log(e)
    });
  },
};

export default StopPropogation;
