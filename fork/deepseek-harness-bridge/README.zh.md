# `deepseek-harness-bridge` —— superpowers 技能接入 DeepSeek Harness 的桥接

> **状态**：已在本 fork 中实现，尚未合并到上游 `obra/superpowers`。
> **配套文档**：[`docs/upstream/deepseek-harness-analysis.md`](../../docs/upstream/deepseek-harness-analysis.md) 是本桥接所依据的 graphify 深度阅读分析,本目录是配套实现。

这是一个小巧的桥接,允许所有现有的 `superpowers/skills/*/SKILL.md` 文件加载到 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)中,无需重写任何技能内容。本目录提供两条互补的接入路径:

1. **最低摩擦路径** —— 一个 `cordis.yml` 覆盖层,使用 harness 自带的 `@deepseek-ai/dsh-skill-filesystem` provider,并将 `customSkillDirs` 指向 `['./superpowers/skills']`,再通过 `@deepseek-ai/dsh-hooks-claude-code` 桥接加载我们现有的 `hooks.json`。无需构建,无需额外的插件代码,只需一个 `--patch` 参数即可将所有技能接入。
2. **更整洁的长期路径** —— `src/index.ts` 中的自定义 `ctx.skills` provider,复用现有的 `SKILL.md` 文件,但在 fork 自己的 provider 名称下注册。当你希望技能与 harness 的其他发现根隔离时(例如在没有 `customSkillDirs` 依赖的打包安装场景),可使用此路径。

两条路径使用相同的技能文件;请根据你的安装形态选择最合适的那条。

## 目录结构

```
fork/deepseek-harness-bridge/
├── README.md                本文件(英文版)
├── README.zh.md             本文件(中文版)
├── cordis.yml               最低摩擦路径:复用 @deepseek-ai/dsh-skill-filesystem + dsh-hooks-claude-code
├── hooks.json               兼容 Claude Code 形状的 SessionStart 钩子(复用 hooks/session-start)
├── package.json             桥接包元数据(用于更整洁的长期路径)
├── tsconfig.json            src/index.ts 的类型检查配置
├── src/
│   └── index.ts             自定义 ctx.skills provider(更整洁的长期路径)
├── test/
│   └── provider.test.ts    自定义 provider 的单元测试(用 bun 运行)
├── examples/
│   ├── config.example.json  用户配置示例
│   ├── dsh-headless.yml     完整的无头 profile 补丁示例
│   └── acceptance.md        本次移植的验收测试
└── CHANGELOG.md             桥接的独立变更日志
```

## 安装(最低摩擦路径,推荐起点)

此路径使用 harness 自带的 provider 以及我们现有的 `hooks/session-start` 脚本。无需构建,无需安装额外的包。

```sh
# 1. 让 harness 能找到本桥接以及 superpowers 的技能。
#    它们位于同一个 checkout 中:
#    <checkout>/fork/deepseek-harness-bridge/
#    和 <checkout>/skills/。
#    用我们的 cordis.yml 给 harness 打补丁:

dsh --profile web --patch ./fork/deepseek-harness-bridge/cordis.yml

# 2. (可选)将补丁持久化到你的 profile,使每个会话自动继承。
#    把同一份 cordis.yml 放入活动 profile 的目录中
#    (默认为 ~/.dsh/profiles/<name>/cordis.patch.yml)。
```

补丁的作用:

- 在 `@deepseek-ai/dsh-skill-filesystem` provider 上设置 `customSkillDirs`,指向 `./superpowers/skills`(rank 300,位于项目根之后、用户根之前,因此用户级技能仍可覆盖)。
- 添加 `@deepseek-ai/dsh-hooks-claude-code` 桥接,`configPath` 指向 `./fork/deepseek-harness-bridge/hooks.json`,使 `SessionStart` 钩子在每个新会话中注入 `using-superpowers` 启动器。
- 复用现有的 `hooks/session-start` 脚本(无 fork 本地的副本)。该脚本通过环境变量识别 harness;在 DeepSeek 上,会回退到 `additionalContext`(SDK 标准)分支,该分支会被桥接映射为 `agent.inject()`。

## 安装(更整洁的长期路径,未来的优化方向)

此路径使用 `src/index.ts` 中的自定义 `ctx.skills` provider。它绕过 harness 的发现与文件监视栈,直接重新注册现有的 `SKILL.md` 文件。适合以下场景:

- 你希望桥接是一个自包含的包(无需 `customSkillDirs` 间接层)。
- 你正在为源码树之外的发行方式打包本 fork。
- 你希望桥接能够控制技能在发现根中的命名方式(避免被用户层面的同名技能静默覆盖)。

先构建:

```sh
# 1. 安装开发依赖并构建 provider。
cd fork/deepseek-harness-bridge
bun install                # 需要 bun >= 1.3.13
bun run build              # 输出 lib/index.js + lib/index.d.ts

# 2. 在补丁中引用构建产物:
cd ../..
dsh --profile web --patch ./fork/deepseek-harness-bridge/examples/dsh-headless.yml
```

补丁内容参见 `examples/dsh-headless.yml`。

## 覆盖范围与未覆盖项

| 关注点 | 状态 | 备注 |
| --- | --- | --- |
| 技能发现(`ctx.skills`) | ✅ | 通过 `customSkillDirs`(路径 1)或自定义 provider(路径 2)实现。 |
| 模型可见的目录(`<available_skills>`) | ✅ | 与 Claude Code 模板一致;由 harness 渲染。 |
| `skill` 工具(按需加载) | ✅ | harness 的 `@deepseek-ai/dsh-tool-skill` 工具可对已注册的 provider 正常工作。 |
| `/<name>` 用户调用 | ✅ | harness 的正则为 `/(^|\s)\/([a-z0-9]+(?:-[a-z0-9]+)*)(?=\s|$)/g`。15 个 superpowers 技能名均为 kebab-case,均可匹配,无需适配层。 |
| `SessionStart` 启动器 | ✅ | 通过 `dsh-hooks-claude-code` + 现有 `hooks/session-start` 脚本实现。 |
| `UserPromptSubmit` / `PreToolUse` / `PostToolUse` / `Stop` 钩子 | ✅ | 同一桥接;只有 `type: 'command'` 类型的钩子会运行。 |
| `SessionEnd` 钩子 | ❌ | `dsh-hooks-claude-code` 尚未映射 `SessionEnd`。**经核实,无 superpowers 技能依赖该事件**(详见 `examples/acceptance.md`)。若未来某个技能依赖它,请编写一个原生 Cordis 插件监听 `agent/turn-end` / `session/dispose`。 |
| `Bash(...)` 权限规则 | ❌ | harness 通过 `dsh-sandbox-policy` / `dsh-approval` 行使用通用 JSON 策略,而非 `Bash(...)` 语法。**没有任何 superpowers 技能以 `Bash(...)` 形式携带规则**(规则属于用户的 `settings.json`,不属于技能)。翻译这些规则是用户自己的事,本桥接不会自动转换。 |
| `subagent` 与 `subagent_fork` 的区分 | ⚠️ | superpowers 技能只命名动作("dispatch a subagent"),不指明工具。`using-superpowers/SKILL.md` 的 Platform Adaptation 列表现已指向 `references/deepseek-harness-tools.md`,以便模型知道调用哪个工具。详见该工具映射参考。 |
| `catalogDescriptionMaxLength` 上限(500) | ✅ | 全部 15 个 superpowers 技能 `description:` 值均在 500 字符以内(最长为 `safety-check`,315 字符)。无需裁剪。 |
| `disable-model-invocation` / `user-invocable` frontmatter | ✅ | 目前没有 superpowers 技能设置这两个字段;若未来设置,harness 的严格解析器可兼容。 |
| MCP、设置、凭据 | n/a | 这些由 harness 原生处理;本桥接不重复实现。 |
| Windows / WSL | ⚠️ | 桥接复用了基于 shell + bash 的 `hooks/session-start`。Windows 通过现有的多语言 `run-hook.cmd` 机制支持 —— DeepSeek Harness 的 `@deepseek-ai/dsh-bash-sandbox` 具备平台感知能力。本桥接无需额外的 Windows 工作。 |

## 推迟到上游处理的开放问题

1. **`/name` 正则是唯一的用户调用入口。** harness 不会在 `/help` 中列出 `/<name>`,也不会在 token 后解析参数。若未来需要 `/superpowers-brainstorm my idea` 这样的语义,可以在 `dsh-hooks-claude-code` 中包装一个轻量原生 Cordis 插件,负责参数解析并注入技能正文;在那之前,纯名称手势即是合约。
2. **部署时的目录描述裁剪。** `catalogDescriptionMaxLength` 可以按 `tool-skill` 实例配置。我们目前没有上调(没有任何 superpowers 描述超过 500)。如果未来某个技能超过 500,部署时需要决定是裁剪 `description:`,还是在补丁中调高 `catalogDescriptionMaxLength`。
3. **没有一等公民的 `Bash(...)` 语法。** harness 的 `dsh-approval` 行使用 JSON 策略。若用户希望翻译他们现有的 Claude Code `Bash(...)` 规则,可以在 `dsh-approval` 行配置中手工完成;桥接不会自动转换。这才是正确的边界:两个 harness 的规则语义不同(沙箱模式、作用域、按命令审批),静默自动转换比显式重新编写更危险。

## 验收测试

按照移植规范(`docs/porting-to-a-new-harness.md` 第三部分),本桥接的验收测试记录在 `examples/acceptance.md` 中。简而言之 —— 在一个干净会话中,消息"让我们做一个 react todo list"必须自动触发 `brainstorming` 技能,并且在写出任何代码之前触发。

## 移植形态说明

- **形态 A(shell 钩子)** —— 现有的 `hooks/session-start` 脚本输出 harness 中立的 JSON 形状;本桥接的 `dsh-hooks-claude-code` 行消费它。该脚本与 Claude Code、Cursor、Copilot CLI、OpenCode 当前消费它的方式完全一致,未做修改。
- **形态 B(进程内插件)** —— `src/index.ts` 是等价的进程内实现,是一个会变更分层 `ctx.skills` 注册表的 Cordis 插件。harness 通过补丁 YAML 中的 `- id: deepseek-harness-bridge` 行加载它。
- **形态 C(指令文件)** —— DeepSeek Harness 的 `AGENTS.md` 相当于 `GEMINI.md` / `CLAUDE.md`。我们不直接在树中提供 `AGENTS.md`,因为 harness 自带的 `AGENTS.md` 是给 harness 维护者用的,而不是给技能消费者(见 [分析文档](../../docs/upstream/deepseek-harness-analysis.md#8-open-questions--unknowns) 第 9 题)。启动器通过 `dsh-hooks-claude-code` 行承载。

## 另请参阅

- [`docs/upstream/deepseek-harness-analysis.md`](../../docs/upstream/deepseek-harness-analysis.md) —— 前置研究
- [`docs/porting-to-a-new-harness.md`](../../docs/porting-to-a-new-harness.md) —— 移植规范
- [`docs/compatibility.md`](../../docs/compatibility.md) —— 运行时矩阵
- [DeepSeek Harness 仓库](https://github.com/deepseek-ai/deepseek-harness) —— 上游 harness
- [Cordis](https://github.com/cordiverse/cordis) —— 本 harness 所基于的插件框架
