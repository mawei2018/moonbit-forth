# 功能与兼容性边界

## 新增能力

增加 nip/tuck/2dup/2drop/2swap 标准栈操作及下溢检查。

## 尚未达到上游的部分

不是完整 ANS Forth；词汇、内存模型和控制流仍为子集。已有基础能力参见 README 与生成的 `pkg.generated.mbti`。

## 工程交付范围

独立 Git 仓库、独立构建目录、可执行文档、Wasm-GC/JS 测试、真实编译的浏览器与 CLI、边界输入检查、样例基准、CI 配置均随仓库交付。运行记录见 evidence；配置 CI 不代表远端 CI 已运行。没有公开发布或比赛验收结论。


## 0.3.0 开发更新：变量与数据空间

新增 VARIABLE、CONSTANT、CREATE、HERE、ALLOT、ALIGN/ALIGNED、CELLS/CELL+、@/!/ +!、C@/C!、逗号/C,、FILL、ERASE、MOVE。数据空间属于各 Machine，跨 eval 保留；变量地址可传入自定义词，常量压入定义时的值。MOVE 处理重叠区域。

本实现使用 4 字节有符号 cell、小端存储、字节地址和最多 65536 字节数据空间；cell 访问需 4 字节对齐。ALLOT 可回退数据空间，释放后旧地址不再有效。越界、未对齐及缺少名称均报错。它只模拟 Forth 的数据空间，不读写宿主内存；尚无通用堆分配、返回栈、DOES>、完整编译期绑定语义和 ANS Forth 全词集。语义依据 [Gforth memory manual](https://gforth.org/manual/Memory.html)，没有复制上游实现。

示例：`variable count 5 count ! : increment 1 count +! ; increment count @`，得到 6。也可 `create table 10 , 20 , table cell+ @` 得到 20。

本轮仅运行 4 组新增 data space JS 测试，检查状态保留、字节/cell、分配对齐与重叠复制及错误范围；未跑 Gforth 实机对照、全套双后端测试或重打包。


## 0.4.0 开发更新：BEGIN 循环

新增 BEGIN…UNTIL、BEGIN…AGAIN、BEGIN…WHILE…REPEAT，可嵌套并在自定义词/IF 内使用。UNTIL 消费栈顶标志，非零退出；WHILE 标志为零时跳过后半段并退出。每次循环检查共享执行预算，空 AGAIN 循环也不会无限占用。补充 0=、0<、0>、1+、1-。

示例：`0 begin 1+ dup 4 = until` 留下 4；`3 begin dup 0> while 1- repeat` 留下 0。当前每个 BEGIN 只支持一个 WHILE，不支持标准控制流栈允许的多 WHILE 编排。EXIT 和返回栈仍未实现，不能视为完整 Forth 控制流。

仅运行新增 `begin loops*` 的 4 组 JS 测试：UNTIL、零次 WHILE、嵌套/变量/IF、错误结构和无限循环预算。未重复旧套件或打包，未作 Gforth 实机对照。


## 0.5.0 开发更新：计数循环

新增 DO/?DO…LOOP/+LOOP、I/J 嵌套索引和 LEAVE。参数顺序为 limit start；`5 0 do i 2 +loop` 留下 0、2、4，`0 3 do i -1 +loop` 留下 3、2、1、0。?DO 在起点等于终点时跳过；DO 保留绕回语义。正负步长按 32 位 cell 回绕及边界跨越处理，零步长受执行预算约束。

LEAVE 可从 IF 或 BEGIN 中退出最近的计数循环；循环异常会清理索引状态。最多嵌套 64 层。当前是运行期解释模型，LEAVE 使用动态循环上下文；没有完整标准编译期控制流约束，也尚无 EXIT、返回栈或 DOES>。

语义参考 [Forth +LOOP](https://forth-standard.org/standard/core/PlusLOOP) 与 [LEAVE](https://forth-standard.org/standard/core/LEAVE)。本轮仅运行新增 `counted loops*` 的 4 组 JS 测试，覆盖跳过、嵌套、正负步长、回绕、提前退出和错误后恢复；没有运行 Gforth 对照、全套回归或重新打包。最新源码及浏览器引擎为开发版，旧压缩包仍是历史快照。
