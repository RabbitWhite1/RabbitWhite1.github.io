---
layout: post
title:  LLVM Lab 示例代码笔记
date:   2021-01-08 00:00:00 +0800
image:  /assets/images/presto/presto-hetu.png
author: Hank Wang
tags: llvm
---

  
**本文记录了张昱老师的 LLVM 实验示例代码的笔记**

## 从 main 函数看起

### 前置部分

- 诊断函数部分暂时不看
- llvm::Triple 暂时不看

随后通过
```cpp
llvm::ErrorOr<std::string> ClangPath = llvm::sys::findProgramByName("clang");
```
实例化 `clang` 编译器对象.

然后是一些简单的信息输出.

之后初始化了 `TheDriver`, 它是 `Driver` 的实例, 其构造函数设置了 `Driver` 的名字, 并初始化了 `_TheDriver` (一个 `clang::driver::Driver`)

初始化后做了两件事:
- ParseArgs: 解析传入参数并修改相应的 `flag`, 如设置 `_show_ir_after_pass = true;`
- BuildCIe: 调用成员 `_TheDriver` 根据参数创建编译任务实例, 并设置到成员 `_C` (一个 `driver::Compilation`). 在其内依次做了 
  - 创建编译任务, 存入 `_C`
  - 任务数量检查, 本例中应为 1
  - err_fe_expected_clang_command 检查 (TODO)
  - 编译器实例 `CompilerInvocation`, 和编译任务不同的是, 它包含的是 include path, 编译器参数等. 最后设置 `clang::CompilerInstance _Clang` 的 `Invocation` 为此, 并设置好诊断器.

### 关键代码

关键代码部分其实是这个:
```cpp
TheDriver.FrontendCodeGen();
TheDriver.runChecker();
TheDriver.InitializePasses();
TheDriver.addPass(createPromoteMemoryToRegisterPass());
TheDriver.addPass(createLSPass());
TheDriver.addPass(createmyDCEPass());
TheDriver.addPass(createmyGlobalPass());
TheDriver.run();
```

下面一个一个分析:

## FrontendCodeGen

这一部分做了:
- 设置动作 `_Act` 为 `EmitLLVMOnlyAction` 实例, 并调用 `_Clang` 执行它.
- 初始化本地目标程序以及本地 LLVM IR 的 printer 函数
- 取生成了的 LLVM Module:
  ```cpp
  _M = _Act->takeModule();
  ```
- 并设置 `_M` 的 print 目标(文件或标准输出)

## runChecker

通过调用 `_Clang.ExecuteAction(动作)` 可以完成一个动作. 这里助教使用了自定义的一个动作 `myAnalysisAction` 来进行

## InitializePasses

上来就初始化了一堆我看不懂的东西, 以后弄懂再补充.(TODO)
```cpp
_PassRegistry = PassRegistry::getPassRegistry();
initializeCore(*_PassRegistry);
initializeScalarOpts(*_PassRegistry);
initializeIPO(*_PassRegistry);
initializeAnalysis(*_PassRegistry);
initializeTransformUtils(*_PassRegistry);
initializeTarget(*_PassRegistry);
```

随后设置了:
- _PM: legacy::PassManager(), 并为之添加 `TargetLibraryInfoWrapperPass`(TODO)
- _FPM: legacy::FunctionPassManager(_M.get())

## addPass

这里面加了 4 个 passes.

### createPromoteMemoryToRegisterPass

官方描述:
```cpp
// PromoteMemoryToRegister - This pass is used to promote memory references to
// be register references. A simple example of the transformation performed by
// this pass is:
//
//        FROM CODE                           TO CODE
//   %X = alloca i32, i32 1                 ret i32 42
//   store i32 42, i32 *%X
//   %Y = load i32* %X
//   ret i32 %Y
```

### createLSPass

这玩意全在 `LoopSearchPass.hpp` 了.

它实现了继承自 [FunctionPass](https://llvm.org/doxygen/classllvm_1_1FunctionPass.html) 的类 `LSPass`

**`FunctionPass` 要求我们实现 `runOnFunction` 函数.**

其实现模板可以归纳如下:
```cpp
using namespace llvm;

#define DEBUG_TYPE "loop-search"
// STATISTIC(LoopSearched, "Number of loops has been found");

namespace llvm {
  FunctionPass * createLSPass();
  void initializeLSPassPass(PassRegistry&);
}

namespace {

struct LSPass : public FunctionPass {
  static char ID; // Pass identification, replacement for typeid

  LSPass() : FunctionPass(ID) {
    initializeLSPassPass(*PassRegistry::getPassRegistry());
  }

  bool runOnFunction(Function &F) override {
      // 该函数的实现
  }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
      // AnalysisUsage::addRequired<> 是指 pass 之间的依赖, 必须先执行哪些 pass 才能执行本 pass
      // AnalysisUsage::addRequired<> 能够暂存 pass, 因为它可能会经常被用到
      // 参考: https://www.jianshu.com/p/b280c8d67909
  }

};

} // end anonymous namespace

char LSPass::ID = 0;

// 这是相当于用宏实现了这个 Pass 的初始化, 其内部做了包括注册, 记录 ID ↑ 等的事情.
// 前面的 initializeLSPassPass 由它定义的.
INITIALIZE_PASS(LSPass, "LSPass", "Loop search", false, false)

FunctionPass *llvm::createLSPass() { return new LSPass(); }
```

而此处数循环个数, 使用的是 DFS:
```cpp
for(auto sSucc = succ_begin(BB), eSucc = succ_end(BB);sSucc != eSucc; ++sSucc){
    auto SuccNode = DT.getNode(*sSucc);
    if(DT.dominates(SuccNode, CurNode)){
        BackEdgeNum++;
    }
}
```
遍历当前树节点对应的 `BB`, 然后获取它对应的 SuccNode, 判断其是否支配 CurNode, 如果它支配的话, 那就说明有回边, 于是 `BackEdgeNum++`

然后输出到文件, 直接调用 `DominatorTree.print` 和 `PostDominatorTree.print`. 

这个过程实际上是没用到 PostDominatorTree 的, 只有最后 print 才有.

**TODO: getAnalysisUsage**

### createmyDCEPass

死代码消除需要有 `TargetLibraryInfo` 的支持. **TODO: 它到底是啥**

`eliminateDeadCode` 函数迭代了 Function 里的指令, 并加入 `WorkList`, 此后循环执行用来消除死代码函数 `DCEInstruction` 直到 `WorkList` 为空.

`DCEInstruction` 函数调用了指令的一些检查函数来判断是否可能是死代码:
- use_empty
- isTerminator
- mayHaveSideEffects

如果可能是, 就会去迭代每个指令的所有 `operand` (**TODO: 什么是 operand**)

然后它又会把 operand 转化为 `Instruction` 类型, 并用 `isInstructionTriviallyDead` 做判断以决定 **是否再放入 WorkList**.

最后它会执行 `I->eraseFromParent()`, 并返回 true

### createmyGlobalPass

这玩意就没必要多说了

## run

这里关键是
```cpp
_FPM->doInitialization();
for(auto sF = _M->begin(), eF = _M->end();sF != eF;++sF) {
    _FPM->run(*sF);
}
_FPM->doFinalization();
_PM->run(*_M);
```

调用前后需要初始化和结束化.







## 常用工具/类索引

- `llvm::outs()`, `llvm::errs()`: 输出流