# Editor Tools and Plugins

BattleFlagRPG includes several custom tools and plugins to assist with development and content creation.

## Attribute Viewer (`addons/attribute_viewer`)

A custom dock integrated into the Godot Editor to visualize and simulate game attribute curves.

*   **Purpose**: Allows designers to tweak and visualize how different attributes (like Attack, Defense) interact, likely using curve resources.
*   **Usage**:
    *   Enabled via Project Settings -> Plugins.
    *   Appears as a dock panel (typically on the right side).
    *   Provides sliders and visualization for attribute values.

## Story Editor (`addons/story_editor`)

A visual graph editor for creating and managing the game's narrative flow.

*   **Purpose**: To create `StoryGraph` resources which drive the game's logic via the `StoryRunner`.
*   **Features**:
    *   **Graph Canvas**: Add, move, and connect story nodes.
    *   **Custom Nodes**: Specific nodes for Battles, Dialogues, Choices, and Endings.
    *   **Data Binding**: Connects nodes to actual game assets (Dialogic timelines, Scene files).
*   **Documentation**: See [Story System](story_system.md) for a detailed breakdown of the runtime logic and node types.

## Dialogic (Third-Party)

The project uses [Dialogic](https://dialogic.pro/) for handling the text, characters, and timelines of the dialogue system. The `StoryRunner` integrates tightly with Dialogic to display content.
