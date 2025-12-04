# BattleFlagRPG 技术文档

欢迎阅读 **BattleFlagRPG** 的技术文档。这是一款基于 Godot 引擎开发的战棋类回合制 RPG。

## 项目概览

BattleFlagRPG 是一款战术角色扮演游戏，包含战棋战斗、剧情叙事和物品管理系统。项目采用多种强大的工具和框架来保持代码库的可扩展性和条理性。

## 核心技术

*   **引擎**: [Godot 4.x](https://godotengine.org/) (GDScript)
*   **架构**: [QFramework](https://github.com/liangxiegame/QFramework) (Godot 移植版) - 用于系统注册、事件处理和架构管理。
*   **数据管理**: [Luban](https://luban.doc.code-philosophy.com/) - 强大的游戏配置解决方案，用于处理 Excel/XML 数据并生成游戏所需的代码/数据。
*   **对话系统**: [Dialogic](https://dialogic.pro/) - 流行的 Godot 插件，用于创建对话和叙事。
*   **库存系统**: Grid Base Inventory System (GBIS) - 用于网格化库存管理的解决方案。

## 文档内容

1.  [架构设计 (Architecture)](architecture_zh.md) - 游戏架构模式概览，包括服务定位器和系统注册。
2.  [战斗系统 (Combat System)](combat_system_zh.md) - 深入解析回合制战斗逻辑、状态机、动作和效果。
3.  [目录结构 (Folder Structure)](folder_structure_zh.md) - 项目目录结构和关键文件的说明。

---
[English Version](README.md)
