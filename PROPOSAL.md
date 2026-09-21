# MoonBit Forth 语言工作台 · 项目申报书

## 一、项目名称

MoonBit Forth 语言工作台

## 二、项目说明

当前公开模块为 0.19.0，实现受预算约束的 Forth 子集：32 位整数、数据栈/返回栈、字节空间、定义与控制流，配套 Node CLI 和 Worker 网页。

## 三、方向与通用性

编程语言与开发者工具。用于栈式语言教学、交互验算及嵌入脚本实验；不是完整 Gforth 或 Forth 标准认证实现。

## 四、应用场景

node tools/forth.mjs --eval ': square dup * ; 12 square .' 执行示例；Machine 的 feed/eval 支持会话；网页观察栈和输出，并可停止 Worker 中的运行。

## 五、功能与验证边界

已实现范围、预算与错误行为见 FEATURES.md 和 TESTING.md。仓库包含双后端回归和 Gforth 0.7.3 独立对照；提交时应绑定具体 evidence 与 commit，不沿用其他版本的测试总数，不将有界预算视为完整安全沙箱。

## 六、原创性与参考材料

原创实现和自写探针采用 MIT。Gforth（GPL-3.0，https://gforth.org/）仅为独立行为参考，未复制其实现、词库或测试集；发行源码不捆绑该参考解释器。

## 七、仓库链接

https://github.com/mawei2018/moonbit-forth
