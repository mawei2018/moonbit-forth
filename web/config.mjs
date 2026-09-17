export default {
  "slug": "forth",
  "title": "Forth 工作台",
  "description": "可嵌入的 32 位 Forth 子集与持续会话",
  "source": "https://gforth.org/",
  "scope": "原始输入、UTF-8 字符串、进制、异常捕获、跨段编译、Worker/CLI/网页",
  "limitations": "仍缺完整标准词集、数值与原生输入输出；尚未追平 Gforth",
  "version": "0.19.0",
  "example": "s\" Hello, Forth!\" type cr\n: square dup * ; 12 square ."
};
