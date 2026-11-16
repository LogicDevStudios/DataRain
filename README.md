# DATARAIN

![Engine](https://img.shields.io/badge/Engine-Godot_4-blue)
![Language](https://img.shields.io/badge/Language-GDScript-blue)
![Status](https://img.shields.io/badge/Status-In_Development-orange)
![Studio](https://img.shields.io/badge/Studio-LogicDevStudios-lightgrey)

## Development Roadmap

> 📋 **[View Full Technical Roadmap (`RoadMap.md`)](./RoadMap.md)**

> **A 2D atmospheric action-platformer blending dark, interconnected exploration with momentum-heavy aerial traversal and knockback-driven combat.**

---

## Overview

**DataRain** is an indie 2D action-platformer currently in active pre-production and prototyping at **TearDropStudios**. 

Built from the ground up in **Godot 4**, the project combines three distinct gameplay pillars into a single, fluid movement and combat sandbox:
* **Atmospheric Exploration (*Hollow Knight*):** Tight, responsive platforming across dark, moody environments with environmental storytelling and deliberate level pacing.
* **Knockback-Driven Combat (*Super Smash Bros.*):** Velocity-based combat where positioning, spacing, and directional launches matter just as much as raw damage.
* **Momentum & Aerial Mastery (*Minecraft PvP*):** High-skill movement mechanics featuring conserved horizontal sprint momentum, controlled aerial gliding, and high-velocity downward slam attacks.

---

## Core Mechanics & Design Pillars

### 1. Precision Movement & State Machine
* **Responsive Ground & Air Physics:** Snappy horizontal acceleration, deliberate ground friction, and conserved sprint momentum when launching into the air.
* **Competitive Platforming Feel:** Built-in **coyote time**, **jump buffering**, and **variable jump height** (tap for short hop, hold for full arc).
* **Procedural Animation Feedback:** Dynamic squash, stretch, and directional lean anchored at the character's base to communicate speed, weight, and impact in real time.

### 2. Aerial Traversal & Slam Physics *(Planned)*
* **Momentum Gliding:** Deployable aerial glide states that convert downward fall speed into forward horizontal velocity.
* **High-Velocity Downward Slams:** Dive-attack mechanics that scale impact force and knockback based on fall distance and vertical velocity.

### 3. Knockback Combat System *(Planned)*
* **Directional Launch Vectors:** Hits apply scalable impulse vectors rather than static health depletion, allowing players to chain aerial follow-ups and edge-guard hazards.

---

## Controls (Prototype Phase)


| Action | Keybind |
| :--- | :--- |
| **Move Left / Right** | `A` / `D` |
| **Sprint** | `Ctrl` + `A` / `D` |
| **Crouch** | `Shift` |
| **Jump (Short Hop / Full)** | `Space` (Tap / Hold) |
| **Double Jump** | `Space` (Mid-air) |
| **Dash** | `Q` |
| **SuperJump** | Hold `Shift` (0.18s) + `Space` |
| **SuperDoubleJump** | `SuperJump` + `Space` (Mid-air) |
| **Stomp** | `SuperJump` + `S` (While falling) |
| **SuperStomp** | `DoubleJump` + `S` (While falling) |
| **MegaStomp** | `SuperDoubleJump` + `S` (While falling) |

---

## Development Roadmap

- [x] **Phase 0:** Repository setup, architecture planning, and licensing.
- [x] **Phase 1:** Baseplate environment, player `CharacterBody2D` state machine, coyote time, jump buffering, and procedural squash/stretch visuals.
- [x] **Phase 2:** Health system, HUD bars, environmental hazards (spikes), and knockback damage states.
- [ ] **Phase 3:** Combat hitboxes, directional knockback scaling, and dummy targets.
- [ ] **Phase 4:** Aerial glide mechanics and velocity-scaled downward slam attacks.
- [ ] **Phase 5:** Level blockouts, atmospheric lighting, shaders, and audio design.
- [ ] **Phase 6:** Modding API documentation and community mod support hooks.

---

## Project Structure

```
DataRain/
├── assets/sprites/    # Textures (characters, hazards, environment)
├── control.tscn / .gd # Main Menu scene and logic
├── main.tscn / .gd    # Core gameplay arena and physics controller
├── project.godot      # Godot 4.4+ configuration
├── RoadMap.md         # Version roadmap
├── LICENSE            # Rights and modding notice
└── README.md          # Documentation (DataRain v1.1)
```
---

## Modding & License

**Copyright © 2026 LogicDevStudios. All Rights Reserved.**

This repository is **source-available** to encourage community transparency and modding:
* **Allowed:** Viewing the source code and developing/distributing free community **Mods** that require a legitimate copy of **DataRain** to run.
* **Prohibited:** Copying, forking, redistributing, or selling the source code, builds, or assets for any standalone game or commercial project without explicit written permission from **LogicDevStudios**.

See the [LICENSE](./LICENSE) file for full legal terms.
