# Folder Structure

This document outlines the organization of the `script/` directory, which contains the game's source code.

## `script/`

*   **`combat/`**: Core logic for the battle system.
    *   `Action/`: Definitions for unit actions (Attack, Move, Defend, etc.).
    *   `Brain/`: AI logic for NPC behavior.
    *   `Buff/`: Buff and Status Effect system.
    *   `Effect/`: Logic for action consequences (Damage, Healing, Conditions).
    *   `Map/`: Grid map logic and pathfinding helpers.
    *   `Timeline/`: Turn order and timeline management.
    *   `Unit/`: Visuals and 3D representation of units.
    *   `BattleSystem.gd`: Main battle controller.
*   **`Dialog/`**: Scripts related to the dialogue system (likely custom extensions or tests).
*   **`entity/`**: Game entities.
    *   `skill/`: Skill data structures and shapes.
    *   `ActorController.gd`: The main class controlling a game character.
    *   `player.gd`: Player-specific logic.
*   **`model/`**: Data models.
    *   `UnitStat.gd`: RPG statistics (HP, MP, Strength, etc.) for a unit.
*   **`scene/`**: Scene management.
    *   `SceneManager.gd`: Global scene switching and management.
    *   `SceneData.gd`: Data persistence for scenes.
*   **`ui/`**: User Interface scripts (Combat UI, Buttons, Mouse cursors).
*   **`util/`**: Utility classes.
    *   `GridHelper.gd`: Grid coordinate math and helpers.
    *   `MathUtils.gd`: General math functions.
    *   `evaluator/`: Logic evaluators (possibly for AI or condition checking).
*   **Root Scripts**:
    *   `game.gd`: Global "Service Locator" and constant definitions.
    *   `GameArchitecture.gd`: QFramework architecture setup.
    *   `ActorManager.gd`: Manages the collection of all actors.

## Other Key Directories

*   **`Datas/`**: Excel and XML files defining game data (Items, Stats, Skills).
*   **`Tools/`**: External tools, primarily `Luban` for data generation.
*   **`modules/`**: C++ modules source code (e.g., `luban`, `utils`).
*   **`addons/`**: Godot plugins (Dialogic, etc.).
