const BackHook = { mounted() { this.el.addEventListener("click", () => { history.back() }); } };
export default BackHook;