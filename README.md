# Forth 工作台 · 0.19.0

## 获取与验证入口

公开源码：[github.com/mawei2018/moonbit-forth](https://github.com/mawei2018/moonbit-forth)；MoonBit 模块名为 `mawei2018/forth`。

从源码运行：`git clone https://github.com/mawei2018/moonbit-forth.git` 后进入该目录，按下文和 [TESTING.md](TESTING.md) 安装所需工具。仓库公开不等于已在 Mooncakes 发布，不承诺 `moon add` 当前可用。

查看 [GitHub Actions](https://github.com/mawei2018/moonbit-forth/actions) 时请核对 run 的 commit SHA；历史 evidence、旧 ZIP 与本地测试不能替代当前提交的 CI 结果。下文保留各版本的验证范围和兼容性限制。

一个原创 MoonBit Forth 子集，提供可嵌入解释器、保留状态的命令行和浏览器工作台。支持 32 位整数、字节数据空间、编译词绑定、循环、返回栈、定义词，以及本版新增的原始输入解析、UTF-8 字符串、进制、异常捕获和跨次编译。

这是独立的本地开发仓库，尚未追平 Gforth 或完整 ANS Forth。没有发布、上传或远程 CI 验收。当前能力见 [WORDS.md](WORDS.md)，仍缺的能力见 [ROADMAP.md](ROADMAP.md)；0.18 及更早记录保存于 [HISTORY.md](HISTORY.md)。

## 立即运行

安装 Node.js 24 后可直接使用已编译的真实 MoonBit 引擎：

~~~sh
node tools/forth.mjs --eval ': square dup * ; 12 square .'
node tools/forth.mjs --file examples/greeting.fs
node tools/forth.mjs --file examples/definitions.fs --eval '7 triple .'
node tools/forth.mjs --lines
~~~

默认从 UTF-8 标准输入读取完整程序。多个 `--file` / `--eval` 按参数顺序共享词典与数据栈；单个 `--file` 应含完整定义。`--lines` 每行发送一个片段，允许冒号定义跨行延续。交互终端自动使用此模式；提示写入 stderr，字符输出原样写入 stdout。

~~~text
forth> : triple
   ... dup dup + +
   ... ;
forth> 5 triple .
15
~~~

实际数字输出为 `15 `（含尾空格，示例为阅读省略尾空格）。用 `--json` 获取栈、错误码和原始字节数组；用 `--jsonl` 发送一行一个 `{ "op": "feed", "source": ": square" }` 命令。JSONL 支持 `eval/feed/state/reset`，格式错误给出一行错误并继续，进程最终返回非零。

网页用 Python 3 启动：

~~~sh
python tools/serve.py --port 8771
~~~

打开 [本地工作台](http://127.0.0.1:8771/web/)。运行、发送片段、重置、停止和原始字节下载都使用 Worker 内的真实 MoonBit 引擎；定义与栈跨次保留。停止或超时会销毁会话，再运行时创建新会话。输出在每次操作完成后显示，不是逐字节流式终端。

## 嵌入 API

MoonBit 的 `Machine::eval` 执行完整缓冲区；`feed` 返回是否还在等待定义结束。`values` 返回数据栈，`output_bytes` 返回原始输出，`output_text` 为 UTF-8 容错显示，`clear_output` 清除输出。普通调用会累积输出；CLI/Worker 桥在每次 eval/feed 前主动清除。

~~~moonbit
let m = @forth.Machine::new()
ignore(m.feed(": twice dup"))
ignore(m.feed("+ ;"))
m.eval("21 twice .")
assert_eq(m.output_text(), "42 ")
~~~

完整签名由工具链生成于 [pkg.generated.mbti](pkg.generated.mbti)。现有 [README.mbt.md](README.mbt.md) 和新输入/编译测试均纳入双后端测试。旧 `printed()`、`run()` 和 `tools/cli.mjs` 保留数字演示兼容行为；字符/二进制程序应使用新 API 或 `tools/forth.mjs`。

Node.js 持续会话：

~~~js
import { ForthSession } from './tools/session-runtime.mjs';
const session = await ForthSession.open({ timeoutMs: 5000, budget: 1000000 });
try {
  await session.feed(': square dup');
  await session.feed('* ;');
  const result = await session.eval('9 square .');
  process.stdout.write(Buffer.from(result.bytes)); // 81 后跟一个空格
} finally {
  await session.close();
}
~~~

一个会话一次处理一个请求；并发请求被拒绝。Forth 错误作为 `ok:false` 返回，超时、AbortSignal 和 Worker 故障拒绝 Promise 并结束会话。`reset()` 清空词典和数据。底层 JSON 桥见 [HOST.md](HOST.md)。

## 本轮验证

- JS 与 Wasm-GC 各 92 组通过，其中包含从官方执行结果生成的 128 个黄金程序。
- 未修改 Gforth 0.7.3 的 128 个原创程序：成功时逐项比较栈及精确输出字节，失败时比较异常码。128/128 一致。
- 9 组 Node/真实 CLI 检查，含跨文件/跨行状态、UTF-8/二进制输出、取消/超时、错误恢复、JSONL 和 1000 次 Worker 往返。
- 307 个有界异常输入；真实浏览器检查保留定义、分段编译、错误恢复、执行上限、停止/重建、下载、390px 布局及控制台。
- `verify.ps1` 完整通过。计时仅为本机特定样本，不构成与 Gforth 的性能追平结论。

范围、参考包指纹、重现命令和证据边界见 [TESTING.md](TESTING.md)。历史 26 案例证据仍保留，不与本轮累计为新案例数。

## 来源与许可

参考 [Gforth](https://gforth.org/) 和 [Forth 标准](https://forth-standard.org/standard/words)。实现及测试输入由本项目编写，没有复制上游代码、词库或测试集。MIT 仅适用于本目录原创内容。外部 Gforth 二进制仅用于本地对照，不随项目分发；参考实现的许可不被本项目 MIT 替代。

本仓库可单独移动使用，不依赖兄弟项目、私有工作区路径或上级 moon.work。源码构建需 MoonBit，运行预编译网页/CLI 不需 MoonBit。开发流程见 [CONTRIBUTING.md](CONTRIBUTING.md)。
