const StopPropagation = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      console.log(e)
    });
  },
};

export default StopPropagation;
