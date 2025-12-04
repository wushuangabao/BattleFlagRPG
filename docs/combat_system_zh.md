# 战斗系统

BattleFlagRPG 的战斗系统是一个基于网格的回合制战术系统。主要由位于 `script/combat/BattleSystem.gd` 的 `BattleSystem` 类管理。

## 核心组件

*   **`BattleSystem`**: 中央控制器。它维护 `BattleState`，持有地图和角色的引用，并编排战斗流程。
*   **`TurnController`** (`script/combat/Timeline/TurnController.gd`): 管理回合队列（时间轴）。它根据单位速度或其他因素决定轮到谁行动。
*   **`ActionBase`** (`script/combat/Action/ActionBase.gd`): 所有战斗动作的基类（攻击、移动、防御、技能）。
*   **`ActorController`** (`script/entity/ActorController.gd`): 代表战斗中的单位。它保存属性、当前状态，并链接到 3D 视觉表现 (`UnitBase3D`)。
*   **`BattleMap`**: 管理网格、寻路和图块数据。
*   **`BattleScene`** (`scene/combat/battle_scene.gd`): 3D 场景控制器。它处理：
    *   视觉表现（实例化单位、移动摄像机）。
    *   输入处理（鼠标点击选择地块/单位）。
    *   将 2D 网格地图 (`BattleMapContainer`) 绑定到 3D 平面。

## 战斗循环

战斗流程由 `BattleSystem` 中的状态机控制。

### 战斗状态 (`BattleState` 枚举)

1.  **`Uninit` / `Init`**: 初始化阶段。
2.  **`Prepare`**: 战斗前准备。
3.  **`Wait`**: 等待动画或回合转换。
4.  **`ActorIdle`**: 当前行动角色准备做出决策。
5.  **`ChoseActionTarget`**: 玩家（或 AI）正在为选定的动作选择目标。
6.  **`ActorDoAction`**: 角色正在执行动作。
7.  **`AtEnd`**: 战斗结束。

### 回合流程

1.  **回合开始**: `TurnController` 调用 `BattleSystem.turn_started(actor)`。
2.  **动作选择**:
    *   **玩家**: UI 允许用户选择动作（移动、攻击、技能）。
    *   **AI**: `Brain` 组件 (`script/combat/Brain/`) 决定最佳动作。
3.  **目标选择**: `BattleSystem.chose_action_target()` 处理网格上的目标选择输入。
4.  **执行**: `BattleSystem.let_actor_do_action()` 执行逻辑。
    *   触发动画。
    *   通过 `Resolver` 应用 `Effects`（伤害、治疗、Buff）。
5.  **回合结束**: `BattleSystem.turn_ended()` 进行清理并通知 `TurnController` 继续下一个单位。

## 动作与效果

*   **Actions (动作)** 定义单位*能做什么*（例如，“斩击”、“火球术”）。它们指定范围、消耗 (AP/MP) 和目标类型。
*   **Effects (效果)** (`script/combat/Effect/`) 定义当动作命中时*发生什么*（例如，`DamageEffect` 伤害效果, `HealEffect` 治疗效果, `BuffEffect` Buff效果）。
*   **Resolver (解析器)** (`script/combat/Effect/Resolver.gd`): 计算效果的最终结果，考虑属性、Buff 和随机数 (RNG)。

## Buff 系统

由 `BuffSystem` (`script/combat/Buff/BuffSystem.gd`) 管理。Buff 可以修改属性、触发持续效果（DoT/HoT）或改变动作属性。
