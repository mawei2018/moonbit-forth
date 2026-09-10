# 功能与兼容性边界

## 新增能力

增加 nip/tuck/2dup/2drop/2swap 标准栈操作及下溢检查。

## 尚未达到上游的部分

不是完整 ANS Forth；词汇、内存模型和控制流仍为子集。已有基础能力参见 README 与生成的 `pkg.generated.mbti`。

## 工程交付范围

独立 Git 仓库、独立构建目录、可执行文档、Wasm-GC/JS 测试、真实编译的浏览器与 CLI、边界输入检查、样例基准、CI 配置均随仓库交付。运行记录见 evidence；配置 CI 不代表远端 CI 已运行。没有公开发布或比赛验收结论。


## 0.3.0 开发更新：变量与数据空间

新增 VARIABLE、CONSTANT、CREATE、HERE、ALLOT、ALIGN/ALIGNED、CELLS/CELL+、@/!/ +!、C@/C!、逗号/C,、FILL、ERASE、MOVE。数据空间属于各 Machine，跨 eval 保留；变量地址可传入自定义词，常量压入定义时的值。MOVE 处理重叠区域。

本实现使用 4 字节有符号 cell、小端存储、字节地址和最多 65536 字节数据空间；cell 访问需 4 字节对齐。ALLOT 可回退数据空间，释放后旧地址不再有效。越界、未对齐及缺少名称均报错。它只模拟 Forth 的数据空间，不读写宿主内存；尚无通用堆分配、DOES>、完整编译期绑定语义和 ANS Forth 全词集。语义依据 [Gforth memory manual](https://gforth.org/manual/Memory.html)，没有复制上游实现。

示例：`variable count 5 count ! : increment 1 count +! ; increment count @`，得到 6。也可 `create table 10 , 20 , table cell+ @` 得到 20。

本轮仅运行 4 组新增 data space JS 测试，检查状态保留、字节/cell、分配对齐与重叠复制及错误范围；未跑 Gforth 实机对照、全套双后端测试或重打包。


## 0.4.0 开发更新：BEGIN 循环

新增 BEGIN…UNTIL、BEGIN…AGAIN、BEGIN…WHILE…REPEAT，可嵌套并在自定义词/IF 内使用。UNTIL 消费栈顶标志，非零退出；WHILE 标志为零时跳过后半段并退出。每次循环检查共享执行预算，空 AGAIN 循环也不会无限占用。补充 0=、0<、0>、1+、1-。

示例：`0 begin 1+ dup 4 = until` 留下 4；`3 begin dup 0> while 1- repeat` 留下 0。当前每个 BEGIN 只支持一个 WHILE，不支持标准控制流栈允许的多 WHILE 编排。仍不能视为完整 Forth 控制流。

仅运行新增 `begin loops*` 的 4 组 JS 测试：UNTIL、零次 WHILE、嵌套/变量/IF、错误结构和无限循环预算。未重复旧套件或打包，未作 Gforth 实机对照。


## 0.5.0 开发更新：计数循环

新增 DO/?DO…LOOP/+LOOP、I/J 嵌套索引和 LEAVE。参数顺序为 limit start；`5 0 do i 2 +loop` 留下 0、2、4，`0 3 do i -1 +loop` 留下 3、2、1、0。?DO 在起点等于终点时跳过；DO 保留绕回语义。正负步长按 32 位 cell 回绕及边界跨越处理，零步长受执行预算约束。

LEAVE 可从 IF 或 BEGIN 中退出最近的计数循环；循环异常会清理索引状态。最多嵌套 64 层。当前是运行期解释模型，LEAVE 使用动态循环上下文；没有完整标准编译期控制流约束，也尚无 DOES>。

语义参考 [Forth +LOOP](https://forth-standard.org/standard/core/PlusLOOP) 与 [LEAVE](https://forth-standard.org/standard/core/LEAVE)。本轮仅运行新增 `counted loops*` 的 4 组 JS 测试，覆盖跳过、嵌套、正负步长、回绕、提前退出和错误后恢复；没有运行 Gforth 对照、全套回归或重新打包。最新源码及浏览器引擎为开发版，旧压缩包仍是历史快照。


## 0.6.0 开发更新：返回栈

新增 >R、R>、R@、2>R、2R>、2R@，保留双 cell 的原始顺序。示例 `: keep dup >r 1+ r> ; 7 keep` 留下 8、7。每次自定义词调用有自己的访问边界，不能弹出调用者暂存的数据；词返回和 eval 结束时必须平衡。错误会清理该调用暂存的数据并恢复上层边界。IF/BEGIN/DO 中可使用，返回栈与循环索引存储分离。

返回栈最多 4096 个 cell，下溢/超限操作预先检查。顶层在单次 eval 中成对使用是本项目的解释模式扩展，不支持跨 eval 留存返回栈数据。它不暴露底层返回地址；编译期绑定及 DOES> 仍待实现。

操作语义参考 [Forth >R](https://forth-standard.org/standard/core/toR) 和 [2R@](https://forth-standard.org/standard/core/TwoRFetch)。本轮只运行新增 `return stack*` 的 5 组 JS 测试，包含顺序、嵌套调用、条件/循环、边界和异常恢复；未重复全套回归、未运行 Gforth 实机对照、未更新历史压缩包。


## 0.7.0 开发更新：EXIT 与 UNLOOP

EXIT 从当前自定义词返回，可穿过 IF 和 BEGIN；被调用词的 EXIT 不会退出调用者。计数循环内返回前须逐层 UNLOOP，且返回栈暂存数据必须取回。示例 `: find 5 0 do i dup 2 = if unloop exit then loop ; find` 留下 0、1、2。双层循环需 `unloop unloop exit`。

UNLOOP 只移除当前词的循环参数，不允许破坏调用者循环；移除后继续执行该 LOOP 会报错。顶层 EXIT/UNLOOP 拒绝执行。异常与正常返回均恢复调用上下文，避免污染后续 eval。

参考 [Forth EXIT](https://forth-standard.org/standard/core/EXIT) 与 [UNLOOP](https://forth-standard.org/standard/core/UNLOOP)。本轮新增 4 组 `word exit*` JS 测试通过，覆盖条件/BEGIN、调用者循环和返回栈、嵌套 UNLOOP、错误后恢复。未重复全套或打包；尚未完成编译期绑定、DOES> 和完整上游符合性对照。
