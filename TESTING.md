# Validation contract

- Explicit Wasm-GC and JS targets: no inference from the toolchain default.
- Public API tests plus compiled browser engine, CLI stdin/file/argument and failure exit-code checks.
- 307 seeded bounded malformed inputs including UTF-16 surrogates. The worker has a 20-second limit.
- Local code coverage: `moon coverage analyze -p localreview/forth -- -f summary`. No coverage upload is configured. Coverage is evidence about current code, not upstream feature coverage.
- Benchmark: 5 warmups and 30 measured documented-example executions; median and p95 recorded locally.
- Generated API and browser artifact must match the same source revision.

CI files are prepared locally; remote CI has not run because this repository has not been uploaded. Compatibility beyond README scope remains unverified.


## Gforth 实机对照（2026-09-10）

新增可独立运行的 `node tools/test-gforth.mjs`，默认调用 PATH 中的 gforth；也可用 `GFORTH_COMMAND_JSON` 指定命令及参数数组，通过 WSL 调用时设置 `GFORTH_WSL=1`。测试脚本直接调用本仓库浏览器引擎，并与独立 Gforth 进程运行相同程序后的数据栈逐项比较。每个进程超时 15 秒，临时输入文件完成后清理；任一差异退出码为 1。

本次使用 Ubuntu 软件源的 Gforth 0.7.3，26/26 个原创代表性程序结果一致，覆盖算术、词绑定、BEGIN/DO/+LOOP/LEAVE、返回栈、EXIT/UNLOOP、递归、令牌、匿名定义、CREATE…DOES>、>BODY、LITERAL、IMMEDIATE、COMPILE,、POSTPONE 和 STATE。逐例结果和引擎/用例 SHA256 见 `evidence/gforth-comparison.json`；参考软件包指纹见 `evidence/gforth-reference-packages.json`。

这是共享整数行为的实机对照，不验证完整词集、原始地址相等、32/64 位边界、性能或所有异常语义。没有运行其他套件或重新打包。参考二进制仅存于工作区外部测试目录，不随项目分发；历史开发记录中的“未作 Gforth 对照”描述的是各自当时的检查范围。
