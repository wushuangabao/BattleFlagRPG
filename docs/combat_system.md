# Combat System

The combat system in BattleFlagRPG is a grid-based, turn-based tactical system. It is primarily managed by the `BattleSystem` class located in `script/combat/BattleSystem.gd`.

## Core Components

*   **`BattleSystem`**: The central controller. It maintains the `BattleState`, references to the map and actors, and orchestrates the flow of battle.
*   **`TurnController`** (`script/combat/Timeline/TurnController.gd`): Manages the turn queue (Timeline). It decides whose turn it is based on unit speed or other factors.
*   **`ActionBase`** (`script/combat/Action/ActionBase.gd`): The base class for all combat actions (Attack, Move, Defend, Skill).
*   **`ActorController`** (`script/entity/ActorController.gd`): Represents a unit in the battle. It holds stats, current state, and links to the 3D visual representation (`UnitBase3D`).
*   **`BattleMap`**: Manages the grid, pathfinding, and tile data.
*   **`BattleScene`** (`scene/combat/battle_scene.gd`): The 3D scene controller. It handles:
    *   Visual representation (instantiating units, moving cameras).
    *   Input handling (mouse clicks for selecting tiles/units).
    *   Binding the 2D grid map (`BattleMapContainer`) to the 3D plane.

## Combat Loop

The combat flow is governed by a state machine in `BattleSystem`.

### Battle States (`BattleState` Enum)

1.  **`Uninit` / `Init`**: Initialization phases.
2.  **`Prepare`**: Pre-battle setup.
3.  **`Wait`**: Waiting for animations or turn transitions.
4.  **`ActorIdle`**: The current actor is ready to make a decision.
5.  **`ChoseActionTarget`**: The player (or AI) is selecting a target for a chosen action.
6.  **`ActorDoAction`**: The actor is performing the action.
7.  **`AtEnd`**: Battle has ended.

### Turn Flow

1.  **Turn Start**: `BattleSystem.turn_started(actor)` is called by the `TurnController`.
2.  **Action Selection**:
    *   For **Player**: The UI allows the user to select an action (Move, Attack, Skill).
    *   For **AI**: The `Brain` component (`script/combat/Brain/`) determines the best action.
3.  **Target Selection**: `BattleSystem.chose_action_target()` handles the input for selecting target cells on the grid.
4.  **Execution**: `BattleSystem.let_actor_do_action()` executes the logic.
    *   This triggers animations.
    *   It applies `Effects` (Damage, Heal, Buffs) via `Resolver`.
5.  **Turn End**: `BattleSystem.turn_ended()` cleans up and notifies `TurnController` to proceed to the next unit.

## Actions and Effects

*   **Actions** define *what* a unit can do (e.g., "Slash", "Fireball"). They specify range, cost (AP/MP), and target type.
*   **Effects** (`script/combat/Effect/`) define *what happens* when an action hits (e.g., `DamageEffect`, `HealEffect`, `BuffEffect`).
*   **Resolver** (`script/combat/Effect/Resolver.gd`): Calculates the final outcome of effects, taking into account stats, buffs, and RNG.

## Buff System

Managed by `BuffSystem` (`script/combat/Buff/BuffSystem.gd`). Buffs can modify stats, trigger effects over time (DoT/HoT), or alter action properties.
