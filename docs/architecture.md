# Game Architecture

BattleFlagRPG employs a structured architecture based on **QFramework** to manage systems, models, and events. This ensures a clean separation of concerns and facilitates communication between different parts of the game.

## Core Architecture

The entry point for the architecture setup is `script/GameArchitecture.gd`. This class extends `Architecture` and is responsible for registering the core systems of the game.

```gdscript
# script/GameArchitecture.gd
class_name GameArchitecture extends Architecture

func _init() -> void:
    self.register_system(Game.g_actors)
    self.register_system(Game.g_scenes)
    self.register_system(Game.g_runner)
    # ...
```

## Service Locator Pattern (The `Game` Class)

The `script/game.gd` file acts as a central **Service Locator** and configuration holder. It provides static access to global managers and constants, preventing the need for singleton nodes in the scene tree for pure logic classes.

### Key Global Systems

Accessed via `Game.*`:

*   **`g_combat` (`BattleSystem`)**: Manages the combat state, turn order, and action execution.
*   **`g_actors` (`ActorManager`)**: Handles the lifecycle and retrieval of actors (characters) in the game.
*   **`g_scenes` (`SceneManager`)**: Manages scene transitions and active scene data.
*   **`g_runner` (`StoryRunner`)**: Controls the narrative flow using the story editor's runtime.
*   **`g_luban` (`Luban`)**: Wrapper for the Luban C++ module to access game configuration data.
*   **`g_event` (`TypeEventSystem`)**: A global event system for decoupled communication.

## System Registration

Systems typically extend `AbstractSystem` (from QFramework) and override `on_init()` to register their own event listeners or initialize data.

Example from `BattleSystem.gd`:

```gdscript
func on_init():
    register_event("event_chose_action", on_chose_action)
    register_event("event_chose_target", on_chose_target)
```

## Data Pipeline (Luban)

The project uses **Luban** for data configuration.
1.  **Source Data**: Excel files located in `Datas/`.
2.  **Generation**: The `Tools/Luban/gendata.bat` script processes these Excel files.
3.  **Runtime**: The game loads the generated binary/json data via the `Luban` C++ module (accessed through `Game.g_luban`).
