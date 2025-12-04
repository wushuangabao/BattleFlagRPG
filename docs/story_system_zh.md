# 剧情系统 (Story System)

BattleFlagRPG 的剧情系统旨在管理叙事流程，将对话、选项和战斗整合到一个连贯的图结构中。它围绕 `StoryRunner` 类构建，并使用 `story_editor` 插件进行可视化编辑。

## 核心组件

### 1. StoryRunner (`addons/story_editor/runtime/StoryRunner.gd`)
`StoryRunner` 是执行剧情的核心引擎。它被注册为全局系统 (`Game.g_runner`) 并处理：
*   **图遍历**: 根据 `StoryGraph` 中定义的连接，从一个节点导航到另一个节点。
*   **节点执行**: 执行特定于每个节点类型的逻辑（例如，开始对话，发起战斗）。
*   **状态管理**: 跟踪剧情会话中的当前节点、已访问节点和变量。
*   **持久化**: 保存和加载剧情状态。

### 2. StoryGraph (`addons/story_editor/runtime/StoryGraph.gd`)
`StoryGraph` 是一个资源 (Resource)，代表单个剧情流程（例如，一条任务线，一个章节）。它包含 `StoryNode` 的集合，并定义了执行开始的 `entry_node`。

### 3. 剧情节点 (Story Nodes)
节点是剧情图的构建块。每个节点类型执行特定的动作：
*   **`DialogueNode`**: 触发一个 Dialogic 时间轴。它可以根据 Dialogic 变量（例如，对话期间所做的选择）进行分支。
*   **`BattleNode`**: 使用 `PackedScene`（战斗地图）发起战斗遭遇。它有两个固定输出：`success`（玩家获胜）和 `fail`（玩家失败）。
*   **`ChoiceNode`**: 直接在游戏场景中向玩家展示一组选项（在对话系统之外）。适用于交互点或重大决策。
*   **`EndingNode`**: 标记剧情流程的结束，可能会触发事件（`story_ended`）。

### 4. 剧情编辑器插件 (`addons/story_editor`)
这是一个自定义编辑器插件，允许开发者可视化地构建 `StoryGraph` 资源。
*   **可视化图表**: 节点表示为图表画布上的块。
*   **连接**: 线条将一个节点的输出端口连接到另一个节点的输入，定义了流程。
*   **检查器集成**: 节点属性（例如，选择时间轴或战斗场景）通过标准的 Godot 检查器进行编辑。

## 与其他系统的集成

*   **Dialogic**: `StoryRunner` 监听 `Dialogic.timeline_ended` 以继续图中的下一个节点。
*   **BattleSystem**: 当 `BattleNode` 激活时，`StoryRunner` 暂停并等待来自 `BattleSystem` 的 `battle_end` 事件。
*   **存档系统**: `StoryRunner` 提供 `save_story_state()` 和 `restore_story_state()` 方法来序列化当前进度，确保玩家可以从中断的确切位置恢复。

## 使用示例

开始一段剧情：
```gdscript
# 假设你有一个 StoryGraph 资源
var my_story = preload("res://asset/story/story_main.tres")
Game.g_runner.start(my_story)
```

这将初始化一个会话并从图的 `entry_node` 开始执行。
