# Forth 栈式解释器

可嵌入、具执行预算的 Forth 子集。本地开发版 0.8.0，供比较和代码审查；尚未作为完整竞赛作品提交。

## 运行

安装 MoonBit 后在本目录执行：

```sh
moon check
moon test
moon run cmd/main
```

也可在本目录运行 `./verify.ps1` 验证本项目。`pkg.generated.mbti` 是真实工具链生成的公共 API。命名空间 `localreview` 仅用于本地，正式发布前应替换为申请人的账号。

## 本版范围

实现目标：词定义、整数栈运算、条件分支、执行预算。

未承诺：浮点、完整 ANS Forth、REPL IO。

## 来源与实现方式

规格/算法参考：https://gforth.org/。

当前代码是本地新写的 MoonBit 实现，不声称是上游完整移植；未复制上游源代码、词库或测试集。测试输入为本项目新写。MIT 仅适用于本目录原创代码。将来如移植上游文件，需要另行保存其版权声明并核查许可证，不能直接沿用当前说明。

## 审查

先看 `cmd/main/main.mbt` 的实际使用，再看公共 API 与测试文件。联网兼容性、性能数据或官方验收未执行的部分不得从本地单元测试成功推断。

## 下一阶段与明确限制

增加完整编译词集、REPL 和 ANS 子集符合性测试；顶层词查找为运行时查找，冒号定义保留定义时的词引用，32 位整数按 MoonBit 溢出语义回绕，错误发生前的栈/字典修改会保留。

本分装包自带 `web/index.html`（用 `start-review.ps1` 启动）。`cmd/web/main.mbt` 为薄适配层，网页调用编译后的真实 MoonBit 模块。

## 独立分装使用

本文件夹可以单独移动或建立仓库，不依赖其他候选项目。浏览器演示已编译，无须安装 MoonBit 即可试用（需要 Python 3）：

```powershell
./start-review.ps1
```

打开 http://127.0.0.1:8771/web/ 。修改和测试源码需安装 MoonBit 与 Node.js，再运行 `./verify.ps1`。本机尚未将 MoonBit 加入 PATH 时，可传入 `-MoonPath`。独立包不捆绑编译器。

仅含本项目源码和构建产物；没有上传仓库或发布包。`DUPLICATION.md`、`evidence/current-validation.json` 和本次分装清单 提供查重、测试和完整性资料。

## 独立仓库工作流

本目录是该项目后续开发的唯一主仓库，旧批次目录及 ZIP 为历史审查快照。没有 Git remote，没有共享构建目录，没有上级 moon.work。

真实 CLI 支持输入参数、文件和标准输入：

```powershell
node tools/cli.mjs --help
node tools/cli.mjs --file sample.txt --json
```

需要安装 MoonBit 后传 `-MoonPath` 或将 moon 加入 PATH；不依赖工作区之外的私有脚本。详见 [TESTING.md](TESTING.md) 和 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 本轮功能升级

增加 nip/tuck/2dup/2drop/2swap 标准栈操作及下溢检查。

不是完整 ANS Forth；词汇、内存模型和控制流仍为子集。

[可执行 API 示例](README.mbt.md)会随测试运行；[功能边界](FEATURES.md)和[测试说明](TESTING.md)用于独立审查。网页与 CLI 展示示例入口，新 API 的完整使用见可执行示例。


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


## 0.8.0 开发更新：词绑定与 RECURSE

冒号定义现在在定义时绑定已有自定义词、变量/常量和内建操作。后续同名定义不改变已编译引用；例如 `: a 3 ; : b a ; : a 9 ; b a` 留下 3、9。重定义中的同名引用绑定旧版本：`: a 1 ; : a a 1+ ; a` 得到 2。

RECURSE 绑定当前定义自身，配合 IF/EXIT 和返回栈可实现递归，即使之后重定义同名词也不改变旧递归。未知词在定义时拒绝，失败不替换同名旧定义。内部绑定标识不允许从输入注入，绑定数量上限为 65536。

这是已有词集的绑定编译器；尚无 IMMEDIATE、POSTPONE、编译模式切换、执行令牌或 DOES>。控制结构仍由原有结构化执行器处理，不能重定义这些保留控制词。VARIABLE/CONSTANT/CREATE 目前用于顶层定义，不支持在冒号定义内解析新的输入名称；定义词机制仍待补齐。

参考 [Forth colon definition](https://forth-standard.org/standard/core/Colon) 与 [RECURSE](https://forth-standard.org/standard/core/RECURSE)。本轮 `binding*` 的 5 组新增 JS 测试通过，覆盖用户词/内建词/数据词重定义、同名旧引用、递归身份、返回栈递归和失败恢复；未重复全套回归、未作 Gforth 实机对照或重新打包。
