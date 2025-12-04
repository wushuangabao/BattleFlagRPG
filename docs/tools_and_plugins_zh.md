# 编辑器工具与插件 (Editor Tools and Plugins)

BattleFlagRPG 包含多个自定义工具和插件，以辅助开发和内容创作。

## 属性查看器 (Attribute Viewer - `addons/attribute_viewer`)

集成到 Godot 编辑器中的自定义停靠面板，用于可视化和模拟游戏属性曲线。

*   **用途**: 允许设计者调整和可视化不同属性（如攻击、防御）如何相互作用，通常使用曲线资源。
*   **用法**:
    *   通过 项目设置 -> 插件 (Project Settings -> Plugins) 启用。
    *   作为停靠面板出现（通常在右侧）。
    *   提供属性值的滑块和可视化。

## 剧情编辑器 (Story Editor - `addons/story_editor`)

用于创建和管理游戏叙事流程的可视化图表编辑器。

*   **用途**: 创建 `StoryGraph` 资源，通过 `StoryRunner` 驱动游戏逻辑。
*   **功能**:
    *   **图表画布**: 添加、移动和连接剧情节点。
    *   **自定义节点**: 专用于战斗、对话、选项和结局的节点。
    *   **数据绑定**: 将节点连接到实际游戏资产（Dialogic 时间轴、场景文件）。
*   **文档**: 有关运行时逻辑和节点类型的详细说明，请参阅 [剧情系统 (Story System)](story_system_zh.md)。

## Dialogic (第三方)

项目使用 [Dialogic](https://dialogic.pro/) 来处理对话系统的文本、角色和时间轴。`StoryRunner` 与 Dialogic 紧密集成以显示内容。
