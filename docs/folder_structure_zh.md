# 目录结构

本文档概述了包含游戏源代码的 `script/` 目录的组织结构。

## `script/`

*   **`combat/`**: 战斗系统的核心逻辑。
    *   `Action/`: 单位动作定义（攻击、移动、防御等）。
    *   `Brain/`: NPC 行为的 AI 逻辑。
    *   `Buff/`: Buff 和状态效果系统。
    *   `Effect/`: 动作后果逻辑（伤害、治疗、条件）。
    *   `Map/`: 网格地图逻辑和寻路辅助。
    *   `Timeline/`: 回合顺序和时间轴管理。
    *   `Unit/`: 单位的视觉和 3D 表现。
    *   `BattleSystem.gd`: 主战斗控制器。
*   **`Dialog/`**: 对话系统相关脚本（可能是自定义扩展或测试）。
*   **`entity/`**: 游戏实体。
    *   `skill/`: 技能数据结构和形状。
    *   `ActorController.gd`: 控制游戏角色的主类。
    *   `player.gd`: 玩家特定逻辑。
*   **`model/`**: 数据模型。
    *   `UnitStat.gd`: 单位的 RPG 属性（HP、MP、力量等）。
*   **`scene/`**: 场景管理。
    *   `SceneManager.gd`: 全局场景切换和管理。
    *   `SceneData.gd`: 场景数据持久化。
*   **`ui/`**: 用户界面脚本（战斗 UI、按钮、鼠标光标）。
*   **`util/`**: 工具类。
    *   `GridHelper.gd`: 网格坐标数学和辅助工具。
    *   `MathUtils.gd`: 通用数学函数。
    *   `evaluator/`: 逻辑评估器（可能用于 AI 或条件检查）。
*   **根脚本**:
    *   `game.gd`: 全局“服务定位器”和常量定义。
    *   `GameArchitecture.gd`: QFramework 架构设置。
    *   `ActorManager.gd`: 管理所有角色的集合。

## 其他关键目录

*   **`Datas/`**: 定义游戏数据的 Excel 和 XML 文件（物品、属性、技能）。
*   **`Tools/`**: 外部工具，主要是用于数据生成的 `Luban`。
*   **`modules/`**: C++ 模块源代码（例如 `luban`, `utils`）。
*   **`addons/`**: Godot 插件（Dialogic 等）。
