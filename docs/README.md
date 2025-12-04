# BattleFlagRPG Technical Documentation

Welcome to the technical documentation for **BattleFlagRPG**, a tactical turn-based RPG developed with the Godot Engine.

## Project Overview

BattleFlagRPG is a tactical role-playing game that features grid-based combat, a story-driven narrative, and an inventory management system. The project leverages several powerful tools and frameworks to maintain a scalable and organized codebase.

## Key Technologies

*   **Engine**: [Godot 4.x](https://godotengine.org/) (GDScript)
*   **Architecture**: [QFramework](https://github.com/liangxiegame/QFramework) (Ported to Godot) - Used for system registration, event handling, and architecture management.
*   **Data Management**: [Luban](https://luban.doc.code-philosophy.com/) - A powerful game configuration solution for handling Excel/XML data and generating code/data for the game.
*   **Dialogue System**: [Dialogic](https://dialogic.pro/) - A popular Godot plugin for creating dialogs and narratives.
*   **Inventory**: Grid Base Inventory System (GBIS) - A custom or plugin-based solution for grid-based inventory management.

## Documentation Contents

1.  [Architecture](architecture.md) - Overview of the game's architectural patterns, including the Service Locator and System registration.
2.  [Combat System](combat_system.md) - Deep dive into the turn-based combat logic, state machine, actions, and effects.
3.  [Story System](story_system.md) - Explanation of the `StoryRunner`, `StoryGraph`, and the visual Story Editor.
4.  [Tools and Plugins](tools_and_plugins.md) - Details on custom editors like the `attribute_viewer` and `story_editor`.
5.  [Folder Structure](folder_structure.md) - Explanation of the project's directory layout and key files.

---
[中文版 (Chinese Version)](README_zh.md)
