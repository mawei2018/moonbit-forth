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
