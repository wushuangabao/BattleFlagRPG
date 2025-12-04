# 游戏架构

BattleFlagRPG 采用基于 **QFramework** 的结构化架构来管理系统、模型和事件。这确保了关注点分离，并促进了游戏各部分之间的通信。

## 核心架构

架构设置的入口点是 `script/GameArchitecture.gd`。该类继承自 `Architecture`，负责注册游戏的核心系统。

```gdscript
# script/GameArchitecture.gd
class_name GameArchitecture extends Architecture

func _init() -> void:
    self.register_system(Game.g_actors)
    self.register_system(Game.g_scenes)
    self.register_system(Game.g_runner)
    # ...
```

## 服务定位器模式 (`Game` 类)

`script/game.gd` 文件充当中央**服务定位器**和配置持有者。它提供对全局管理器和常量的静态访问，避免了纯逻辑类需要在场景树中作为单例节点存在的需求。

### 关键全局系统

通过 `Game.*` 访问：

*   **`g_combat` (`BattleSystem`)**: 管理战斗状态、回合顺序和动作执行。
*   **`g_actors` (`ActorManager`)**: 处理游戏中角色（Actor）的生命周期和检索。
*   **`g_scenes` (`SceneManager`)**: 管理场景切换和当前场景数据。
*   **`g_runner` (`StoryRunner`)**: 使用剧情编辑器的运行时控制叙事流程。
*   **`g_luban` (`Luban`)**: 访问游戏配置数据的 Luban C++ 模块封装。
*   **`g_event` (`TypeEventSystem`)**: 用于解耦通信的全局事件系统。

## 系统注册

系统通常继承自 `AbstractSystem` (QFramework)，并重写 `on_init()` 以注册自己的事件监听器或初始化数据。

`BattleSystem.gd` 示例：

```gdscript
func on_init():
    register_event("event_chose_action", on_chose_action)
    register_event("event_chose_target", on_chose_target)
```

## 数据管线 (Luban)

项目使用 **Luban** 进行数据配置。
1.  **源数据**: 位于 `Datas/` 目录下的 Excel 文件。
2.  **生成**: `Tools/Luban/gendata.bat` 脚本处理这些 Excel 文件。
3.  **运行时**: 游戏通过 `Luban` C++ 模块（通过 `Game.g_luban` 访问）加载生成的二进制/json 数据。
