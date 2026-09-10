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


## 0.8.0 开发更新：词绑定与 RECURSE

冒号定义现在在定义时绑定已有自定义词、变量/常量和内建操作。后续同名定义不改变已编译引用；例如 `: a 3 ; : b a ; : a 9 ; b a` 留下 3、9。重定义中的同名引用绑定旧版本：`: a 1 ; : a a 1+ ; a` 得到 2。

RECURSE 绑定当前定义自身，配合 IF/EXIT 和返回栈可实现递归，即使之后重定义同名词也不改变旧递归。未知词在定义时拒绝，失败不替换同名旧定义。内部绑定标识不允许从输入注入，绑定数量上限为 65536。

这是已有词集的绑定编译器；尚无 IMMEDIATE、POSTPONE、编译模式切换或 DOES>。控制结构仍由原有结构化执行器处理，不能重定义这些保留控制词。VARIABLE/CONSTANT/CREATE 的运行期名称解析已在 0.10.0 补充；DOES> 定义词机制仍待补齐。

参考 [Forth colon definition](https://forth-standard.org/standard/core/Colon) 与 [RECURSE](https://forth-standard.org/standard/core/RECURSE)。本轮 `binding*` 的 5 组新增 JS 测试通过，覆盖用户词/内建词/数据词重定义、同名旧引用、递归身份、返回栈递归和失败恢复；未重复全套回归、未作 Gforth 实机对照或重新打包。


## 0.9.0 开发更新：执行令牌

新增顶层 `' name`、定义内 `['] name` 和 EXECUTE。令牌可作为整数 cell 放入常量/变量、传给其他词或跨 eval 使用，引用的行为不随同名词重定义改变。示例 `: square dup * ; : apply execute ; 6 ' square apply` 得到 36；`: callback ['] square ; 7 callback execute` 得到 49。

令牌属于当前 Machine，采用 1 起始的不透明索引，上限 65536；相同已有实现复用令牌。EXECUTE 保留调用边界、预算和深度保护。无效索引、未知名称和无受支持解释语义的控制词会报错。

0.10.0 已补定义内单引号的运行期名称解析；完整原始文本输入游标仍待实现。控制词和返回栈原语不提供令牌，自定义词可以使用这些能力后通过令牌调用。它不是原生地址或跨 Machine 可序列化标识；仍缺 DOES>、IMMEDIATE、POSTPONE 等。

参考 [Forth tick](https://forth-standard.org/standard/core/Tick) 与 [EXECUTE](https://forth-standard.org/standard/core/EXECUTE)。本轮仅运行 `execution tokens*` 的 5 组 JS 测试，覆盖回调、令牌复用、保存和重定义、编译时引用、递归/EXIT 与拒绝场景。未重复全套或重新打包，未作 Gforth 实机对照。


## 0.10.0 开发更新：运行期名称解析

自定义词现在可通过 VARIABLE、CONSTANT、CREATE 和单引号从当前 eval 输入读取后续名称，支持嵌套调用、条件分支、循环和通过 EXECUTE 调用解析原语。示例 `: table create 10 , 20 , ; table data data cell+ @` 得到 20；`: call ' execute ; 3 call dup +` 得到 6。

定义中的单引号在调用时读取名称；`[']` 仍在编译时捕获名称。名称消费推进共享输入游标，已消费名称不再当作普通词执行。缺失或非法名称会报错，eval 结束或失败后清理输入游标，字典/数据空间按已有规则保留。

本轮只运行 `runtime names*` 的 5 组新增 JS 测试，覆盖变量/常量/CREATE、多个名称、嵌套解析、条件/循环、执行令牌及错误后恢复。未重复全套、未作 Gforth 实机对照或打包。当前仍使用预分词输入，不提供原始 SOURCE/>IN、EVALUATE 或完整编译状态；CREATE…DOES> 仍待补齐。


## 0.11.0 开发更新：CREATE…DOES>

新增 DOES>：为最近的 CREATE 词安装后续代码，并从当前定义返回。新词先压入自己的数据地址，再运行安装的代码。示例 `: con create , does> @ ; 7 con a 9 con b a b` 留下 7、9；`: array create cells allot does> swap cells + ; 3 array table` 创建按 cell 索引访问的表。

支持 CREATE 位于辅助词、重复替换行为和多个 DOES> 分阶段替换。已捕获的词引用与执行令牌共享被创建词的行为更新；不同 CREATE 即使数据地址相同也拥有独立身份。新增定义若不是 CREATE，会使其不能成为 DOES> 修改对象。

顶层 DOES>、缺失 CREATE、未平衡返回栈/循环和控制结构内 DOES> 会报错；DOES> 后 RECURSE 属于未支持场景，编译时明确拒绝。尚无 IMMEDIATE、POSTPONE、原始输入缓冲区或完整 ANS 符合性证明。

语义参考 [Forth DOES>](https://forth-standard.org/standard/core/DOES)。本轮只运行新增 `does*` 的 5 组 JS 测试，覆盖独立数据、数组与条件行为、辅助创建/重复替换、执行令牌身份、自替换及错误恢复；未重复全套、未运行 Gforth 实机对照或重新打包。


## 0.12.0 开发更新：匿名定义与数据地址

新增 :NONAME 和 >BODY。匿名定义在分号处留下执行令牌，可保存在常量或变量、作为回调传递，支持 RECURSE、EXIT 和 CREATE…DOES>。示例 `:noname dup * ; constant square 7 square execute` 得到 49。

>BODY 接收 CREATE 词的执行令牌并返回数据区地址，DOES> 替换行为或后续同名重定义不改变旧令牌对应的地址。例如 `: con create , does> @ ; 4 con a 7 ' a >body ! a` 得到 7。普通冒号定义、内建词及 CONSTANT 的令牌不被当作 CREATE 数据地址，无效令牌报错。数据区尚未分配时可取得 HERE 对应地址，但读写仍须先分配空间。

参考 [Forth :NONAME](https://forth-standard.org/standard/core/ColonNONAME) 与 [>BODY](https://forth-standard.org/standard/core/toBODY)。本轮仅运行新增 `anonymous*` 的 5 组 JS 测试，覆盖回调存取、递归、匿名定义词、地址稳定性及非法输入；未重复全套、未作 Gforth 实机对照或打包。完整编译状态、IMMEDIATE/POSTPONE 和源码输入词仍待实现。


## 0.13.0 开发更新：编译结构检查与失败回滚

冒号和匿名定义在发布前验证结构化控制流：IF/ELSE/THEN、BEGIN/WHILE/REPEAT、BEGIN/UNTIL/AGAIN、DO/?DO/LOOP/+LOOP 必须正确嵌套与闭合，最大 64 层；DOES> 必须处于已闭合的边界。即使错误代码不会被执行，也在定义时拒绝，保留同名旧定义。

编译过程暂存内部词引用，成功后才加入字典；失败时恢复绑定编号并撤销本次新建令牌，避免反复失败消耗内部资源。已存在令牌和字典保持有效。

本轮仅运行 `compile structure*` 的 4 组新增 JS 测试：22 种错配/未闭合结构、合法混合嵌套和 DOES>、匿名递归与错误、100 次失败编译后的令牌使用。未重复全套、未作 Gforth 实机对照或打包。该检查覆盖当前结构化子集，不支持标准控制流栈的任意重排及多 WHILE 编排；IMMEDIATE/POSTPONE 和完整编译状态仍待补齐。


## 0.14.0 开发更新：编译期计算与 LITERAL

定义内 `[ … ]` 在编译时执行，LITERAL 消费当时栈顶并将整数写入运行代码。示例 `: value [ 7 7 * 2 + ] literal ; value` 得到 51。可调用已定义词、访问现有变量、获取执行令牌；`: double [ ' dup ] literal execute + ; 5 double` 得到 10。

编译期计算共享执行预算，使用独立临时输入上下文，结束或失败后恢复外层输入和模式。LITERAL 可位于条件分支或 DOES> 后；编译期副作用只发生一次。数据栈与既有内存的修改沿用错误前保留规则；本轮失败的新定义不发布。

当前支持定义内成对的 `[ … ]` 和 LITERAL，不支持跨 eval 编译、STATE、IMMEDIATE、POSTPONE、任意控制流栈操作或在编译期间运行定义词；嵌套方括号明确拒绝。这些限制仍需继续补齐。

参考 [Forth LITERAL](https://forth-standard.org/standard/core/LITERAL) 与 [left bracket](https://forth-standard.org/standard/core/Bracket)。本轮只运行 `compile evaluation*` 的 5 组新增 JS 测试，覆盖计算、一次性副作用、令牌/匿名定义、分支/DOES>、错误恢复及预算。未重复全套、未作 Gforth 实机对照或打包。


## 0.15.0 开发更新：IMMEDIATE 与 COMPILE,

IMMEDIATE 标记最近完成的命名定义，使其在后续编译中立即执行；解释模式仍正常调用。适用于自定义词、常量和变量，重定义会重置标记。`: seven 7 ; immediate : value seven literal ; value` 得到 7。

COMPILE, 将执行令牌对应的调用写入当前定义，保留当时引用。`: emitdup ['] dup compile, ; immediate : double emitdup + ; 6 double` 得到 12。立即词也可读取编译输入的后续词名：`: emit ' compile, ; immediate : value 5 emit 1+ ; value` 得到 6。编译动作共享预算，失败恢复输出缓冲区和输入上下文。

本实现拒绝在活跃编译期间再次执行 IMMEDIATE；匿名定义后不能标记 IMMEDIATE。COMPILE, 仅用于已有支持的执行令牌，不提供控制流词令牌。尚缺 POSTPONE、STATE、跨 eval 编译和任意控制流栈编排。

参考 [Forth IMMEDIATE](https://forth-standard.org/standard/core/IMMEDIATE) 与 [COMPILE,](https://forth-standard.org/standard/core/COMPILEComma)。本轮只运行 `immediate*` 的 5 组新增 JS 测试，覆盖立即执行/解释、常量、调用生成及绑定、名称解析、一次性副作用和错误恢复。未重复全套、未作 Gforth 实机对照或打包。


## 0.16.0 开发更新：POSTPONE 与生成代码检查

POSTPONE 保存目标词的编译行为：普通词延后生成调用，用户立即词延后执行，受支持控制词/LITERAL/DOES> 延后执行编译动作。引用保留定义时版本。示例 `: endif postpone then ; immediate : choice if 7 else 8 endif ;`，以及 `: lit7 7 postpone literal ; immediate : value lit7 ; value` 得到 7。

支持生成 IF/ELSE/THEN、BEGIN 循环、DO 循环及 DOES>。结构检查改为验证最终生成代码，让宏可以开闭结构，同时拒绝未闭合或错配的生成结果。无当前编译输出时执行需要编译上下文的延期动作会报错；延期调用用户立即词仍可在解释时执行其正常行为。

POSTPONE 暂不支持方括号状态切换、[']、RECURSE、POSTPONE 自身等解析/状态编译词；STATE、跨 eval 编译和标准控制流栈任意编排仍待补齐。

参考 [Forth POSTPONE](https://forth-standard.org/standard/core/POSTPONE)。本轮新增 `postpone*` 5 组 JS 测试通过，另对受改动影响的 `compile structure*` 4 组作定向回归，均通过。未重复其他套件、未作 Gforth 实机对照或打包。


## 0.17.0 开发更新：STATE 与延后解析

STATE 压入只读状态 cell 地址，`STATE @` 在编译状态为 -1，在解释状态为 0。编译中执行用户立即词保持编译状态，`[ … ]` 中执行切换为解释状态；成功或失败后恢复外层状态。状态 cell 使用独立虚拟地址 -4，不占用数据空间；支持 @ 和 C@ 读取，写入拒绝。

可编写区分状态的立即词：`: smart 7 state @ if postpone literal then ; immediate`，解释时留下 7，编译时写入字面量 7。POSTPONE 也支持 `[']`，在延期动作执行时读取当时的名称，例如 `: quote postpone ['] ; immediate : callback quote dup ;`。

本轮 `compiler state*` 的 4 组新增 JS 测试通过，覆盖解释/编译/方括号状态、状态相关宏、延期名称读取、失败恢复和只读状态保护。未重复全套、未运行 Gforth 实机对照或打包。跨 eval 编译、独立状态切换词和完整原始输入仍待实现。

语义参考 [Forth STATE](https://forth-standard.org/standard/core/STATE)。
