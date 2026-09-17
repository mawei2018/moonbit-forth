# 词与行为边界

0.19.0 实现的是受限的 32 位 Forth 环境。下面列出当前可用词；内部执行标记不是稳定接口。词名忽略大小写，字符串保留大小写、空格和 UTF-8 字节。没有词集或标准认证声明。

## 词汇

| 类别 | 词 |
|---|---|
| 数据栈 | DUP DROP SWAP OVER ROT NIP TUCK 2DUP 2DROP 2SWAP ?DUP 2OVER PICK ROLL DEPTH |
| 返回栈 | >R R> R@ 2>R 2R> 2R@ |
| 算术 | + - * / MOD /MOD */ */MOD NEGATE ABS MIN MAX 1+ 1- 2* 2/ |
| 位/比较 | AND OR XOR INVERT LSHIFT RSHIFT = <> < > U< U> 0= 0<> 0< 0> WITHIN TRUE FALSE |
| 数据空间 | VARIABLE CONSTANT CREATE HERE ALLOT ALIGN ALIGNED CELLS CELL+ @ ! +! C@ C! , C, 2@ 2! FILL ERASE MOVE BLANK UNUSED |
| 编译 | : ; :NONAME IMMEDIATE [ ] LITERAL POSTPONE COMPILE, ['] [CHAR] RECURSE DOES> STATE |
| 执行令牌 | ' EXECUTE >BODY |
| 控制流 | IF ELSE THEN BEGIN UNTIL AGAIN WHILE REPEAT DO ?DO LOOP +LOOP I J LEAVE UNLOOP EXIT |
| 输入 | SOURCE SOURCE-ID >IN PARSE PARSE-NAME WORD PAD EVALUATE SAVE-INPUT RESTORE-INPUT REFILL |
| 文字 | S" ." C" .( S\" CHAR CHAR+ CHARS BL COUNT TYPE EMIT CR SPACE SPACES -TRAILING /STRING COMPARE SEARCH |
| 数值文本 | BASE HEX DECIMAL . U. .R U.R |
| 异常 | CATCH THROW ABORT ABORT" |
| 注释 | ( 到闭合括号，反斜杠到行尾；必须作为单独词开始 |

内部辅助 `abort-message` 目前可被名字查找，但不属于承诺的公共词汇。编译器使用的 NUL/控制字节前缀不能从原始源码注入。

## 输入与字符串

输入以 UTF-8 字节表示，`SOURCE` 返回当前缓冲区地址和字节数，`>IN` 是字节偏移。`PARSE` 按单字节分隔符解析；`PARSE-NAME` 跳过字节值不大于空格的分隔；读词会消费一个紧随其后的分隔字节。`WORD` 返回共享临时区中的计数字符串，该临时区会被后续 WORD 覆盖。

`EVALUATE` 嵌套输入会恢复外层输入帧。API/CLI 的所有输入在核心内均为字符串缓冲区，因此 `SOURCE-ID` 为 -1、`REFILL` 为 false；CLI 分行输入不等同原生 Forth 终端输入源。`SAVE-INPUT` 保存游标和源身份，`RESTORE-INPUT` 仅接受仍活跃的同一输入帧。

`S"` 返回地址/长度；`C"` 返回长度字节开头的地址且最多 255 字节；`."` 输出文字；`.(` 在被解析时立即输出。字符串在 Machine 生命周期内驻留并去重。输入源与驻留字符串只读，若需修改，应 MOVE 到已分配数据空间。PARSE/SOURCE 地址仅在所属输入帧仍活跃时有效。

`S\"` 支持转义 a/b/e/f/l/n/m/q/双引号/r/t/v/z/反斜杠/xHH，其中 n/l 为 LF、m 为 CRLF、z 为 NUL。未知或不完整转义报错。输入字符串中的原始字节 0、1、2 被拒绝，但转义输出可以含任意字节。`EMIT` 输出低 8 位；`TYPE` 按长度输出原始字节。`output_text` 使用 UTF-8 容错解码；需要无损二进制时使用 `output_bytes` 或 CLI stdout。

`CHAR` / `[CHAR]` 取名称的第一个 UTF-8 字节。本地 `'A'` 数字扩展目前取单个 UTF-16 代码单元，只对 ASCII 字符承诺与 CHAR 一致。Unicode 字符语义不完整。

未闭合字符串或括号注释报错，不能跨 feed 缓冲区；PARSE 在缓冲区末尾返回剩余部分。SEARCH 使用线性 KMP，返回从命中位置起的地址/剩余长度和 true，未命中保留原地址/长度和 false。

## 数值与存储

整数为 32 位 cell，算术按现有回绕语义。BASE 支持 2..36，默认十进制；HEX/DECIMAL 修改当前进制。`$`、`#`、`%` 前缀分别指定十六/十/二进制，符号可紧随前缀。正数字面量可覆盖 0..4294967295 并映射到有符号 cell；负数字面量下限为 -2147483648。编译时的数字绑定已冻结，之后改变 BASE 不会重新解析已编译数字。

`.` 和 `U.` 尾随一个空格；`.R` 和 `U.R` 用空格补到最小宽度，不额外添加尾空格。没有浮点、双 cell 数值系统、>NUMBER 或完整 pictured numeric output。

数据空间最多 65536 字节，cell 为 4 字节小端并要求对齐。ALLOT 可回退空间，释放地址不再有效。MOVE 支持重叠。2! / 2@ 按本地四字节 cell 成对存取。另有 1024 字节共享临时区；WORD 使用其前部，PAD 位于后部。驻留字符串和输入位于独立只读虚拟区域，不消耗 HERE/UNUSED 所示数据空间。

STATE 可读但不可写；BASE 和 >IN 支持受检查的读写。不要依赖这些控制单元或字符串的原始整数地址；它们不是宿主指针。

## 编译、失败与持续会话

冒号定义保留定义时绑定；顶层查找仍为运行时查找。立即词能够从当前位置 PARSE 输入，也能在编译中 EVALUATE。feed 保留未结束的定义和方括号解释状态，直到后续片段完成；eval 遇未完成定义报错。

定义结束要求数据栈深度与开始时一致。编译失败撤回尚未发布的词绑定/令牌；若仍处于方括号解释，恢复进入方括号时的栈副本。编译期间已经发生的内存修改、输出或其它立即词副作用不保证回滚。普通运行错误也不会自动清空已经修改的数据/词典。

CATCH 成功压入 0，THROW 0 无效，其它代码向外传播。捕获失败恢复进入 CATCH 时的完整数据栈副本，并清理相应返回/循环/输入帧；完整单元副本是本地额外保证，标准只对相应栈深度作要求，不能据此声称 Gforth 的覆盖单元内容相同。字典和内存副作用不回滚。

ABORT 为 -1，ABORT" 的非零标志抛 -2；被 CATCH 捕获时不输出该消息，未捕获时输出消息。映射还包括部分 -4 下溢、-10 除法、-13 未知词、-23 对齐、-9 地址/令牌错误；其余为 -256。这不是完整标准错误码表。

控制流、CREATE/DOES> 与 POSTPONE 仍有子集限制：一个 BEGIN 最多一个 WHILE；编译中嵌套定义及部分定义词不支持；DOES> 后的 RECURSE 不支持；POSTPONE 不覆盖所有编译词（例如 [CHAR]）。顶层结构化控制是本地扩展，不能替代标准控制流栈。详见源码回归和 ROADMAP.md。

## 执行上限

| 项目 | 当前限制 |
|---|---|
| 单次核心输入 | 1,000,000 个 UTF-16 单元，转为 UTF-8 解析 |
| 数据栈 | 4096 项；在解释执行边界检查 |
| 数据空间 / 临时区 | 65536 / 1024 字节 |
| 驻留字符串 | 16,000,000 字节，含终止及计数开销 |
| 字符输出 | 2,000,000 字节；clear_output 后重新计数 |
| 调用 / 输入帧 / 循环嵌套 | 64 |
| 编译绑定 / 执行令牌 | 65536 |
| 核心默认预算 | 每次 eval/feed 10000；宿主默认值见 HOST.md |

预算按解释器操作计数，并非 CPU 时间；某些有界批量字节操作只计一次或少量操作。Worker 超时/停止补充墙钟控制。限制是 API 防误用边界，不是严格内存占用或不可信代码隔离证明。

语义参考：[PARSE](https://forth-standard.org/standard/core/PARSE)、[EVALUATE](https://forth-standard.org/standard/core/EVALUATE)、[S"](https://forth-standard.org/standard/core/Sq)、[CATCH](https://forth-standard.org/standard/exception/CATCH)、[SAVE-INPUT](https://forth-standard.org/standard/core/SAVE-INPUT)。上文列出的本地扩展与限制不作为这些标准的要求。
