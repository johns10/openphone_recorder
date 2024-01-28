export default MaintainAttrs = {
  beforeUpdate() { this.prevHeight = this.el.style.height; },
  updated() { this.el.style.height = this.prevHeight; }
}