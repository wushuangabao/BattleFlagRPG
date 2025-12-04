# Story System

The Story System in BattleFlagRPG is designed to manage the narrative flow, integrating dialogues, choices, and battles into a cohesive graph structure. It is built around the `StoryRunner` class and visually edited using the `story_editor` plugin.

## Core Components

### 1. StoryRunner (`addons/story_editor/runtime/StoryRunner.gd`)
The `StoryRunner` is the central engine that executes the story. It is registered as a global system (`Game.g_runner`) and handles:
*   **Graph Traversal**: Navigating from one node to another based on connections defined in the `StoryGraph`.
*   **Node Execution**: executing the logic specific to each node type (e.g., starting a dialogue, initiating a battle).
*   **State Management**: Tracking the current node, visited nodes, and variables within a story session.
*   **Persistence**: Saving and loading the story state.

### 2. StoryGraph (`addons/story_editor/runtime/StoryGraph.gd`)
A `StoryGraph` is a Resource that represents a single story flow (e.g., a quest line, a chapter). It contains a collection of `StoryNode`s and defines the `entry_node` where execution begins.

### 3. Story Nodes
Nodes are the building blocks of the story graph. Each node type performs a specific action:
*   **`DialogueNode`**: Triggers a Dialogic timeline. It can branch based on Dialogic variables (e.g., choices made during the dialogue).
*   **`BattleNode`**: Initiates a combat encounter using a `PackedScene` (Battle Map). It has two fixed outputs: `success` (player won) and `fail` (player lost).
*   **`ChoiceNode`**: Presents a set of choices to the player directly in the game scene (outside of the dialogue system). Useful for interaction points or major decisions.
*   **`EndingNode`**: Marks the end of a story flow, potentially triggering an event (`story_ended`).

### 4. Story Editor Plugin (`addons/story_editor`)
This is a custom editor plugin that allows developers to visually construct `StoryGraph` resources.
*   **Visual Graph**: Nodes are represented as blocks on a graph canvas.
*   **Connections**: Lines connect the output ports of one node to the input of another, defining the flow.
*   **Inspector Integration**: Node properties (e.g., selecting a timeline or battle scene) are edited via the standard Godot Inspector.

## Integration with Other Systems

*   **Dialogic**: `StoryRunner` listens to `Dialogic.timeline_ended` to proceed to the next node in the graph.
*   **BattleSystem**: When a `BattleNode` is active, `StoryRunner` pauses and waits for the `battle_end` event from the `BattleSystem`.
*   **Save System**: `StoryRunner` provides `save_story_state()` and `restore_story_state()` methods to serialize the current progress, ensuring the player can resume exactly where they left off.

## Usage Example

To start a story:
```gdscript
# Assuming you have a StoryGraph resource
var my_story = preload("res://asset/story/story_main.tres")
Game.g_runner.start(my_story)
```

This will initialize a session and begin executing from the `entry_node` of the graph.
