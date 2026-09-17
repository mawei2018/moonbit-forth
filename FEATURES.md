# 当前能力与证据

版本 0.19.0。具体词、限制和错误行为以 [WORDS.md](WORDS.md) 为准。

| 领域 | 已实现 | 验证与边界 |
|---|---|---|
| 整数/栈 | 32 位算术、位操作、比较、单/双栈操作、返回栈 | 溢出回绕；不是 64 位 Gforth cell 兼容 |
| 数据空间 | 64 KiB 字节空间、4 字节小端 cell、对齐、重叠 MOVE、变量/常量 | 只访问虚拟空间，无宿主指针 |
| 词典/编译 | 早绑定冒号词、匿名词、执行令牌、IMMEDIATE/LITERAL/POSTPONE/COMPILE,、CREATE/DOES> | 编译词集及控制流栈仍为子集 |
| 控制流 | IF、BEGIN、DO/?DO、LOOP/+LOOP、LEAVE、I/J、EXIT/UNLOOP、RECURSE | 一个 BEGIN 最多一个 WHILE；不是完整控制流栈 |
| 输入与文字 | 原始字节游标、SOURCE/PARSE/PARSE-NAME/WORD、EVALUATE、字符串与转义、字符输出 | API 输入都是 EVALUATE 缓冲区；无原生终端/文件输入词 |
| 数字输入输出 | BASE 2..36、HEX/DECIMAL、显式前缀、带宽度/无符号显示 | 没有双 cell/浮点/完整 pictured numeric output |
| 异常 | CATCH/THROW、ABORT/ABORT"、部分标准错误码 | 完整栈副本恢复是本地扩展；未映射错误为 -256 |
| 持久会话 | feed 跨缓冲区定义、Node Worker、多文件/行 REPL/JSONL、网页 | 取消/超时销毁状态；无持久化快照 |
| 独立验收 | 128 官方案例、双后端 92 组、9 主机组、实际浏览器 | 全部为已列子集；不是上游全量或性能证明 |

本轮移除了整段源码预先小写分词的限制，保留字符串大小写和空格，使立即词可读取当前输入游标；编译状态现在能跨 feed 保留。SEARCH 改为线性扫描；词典绑定、异常回退和只读字符串映射有专项回归。旧版逐轮功能记录归档在 HISTORY.md，不作为当前缺口列表。
