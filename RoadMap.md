# DataRain — Coming Updates & Technical Roadmap (Godot 4)

* **License Note:** Modding allowed; full standalone remakes prohibited.
* **Visual Direction:** Pure black (`#000000`) background, flat unlit 2D sprites, zero heavy shaders/lighting, modular `Sprite2D` texture swapping.

---

## `[COMPLETED]` V1.0 — Core Movement, UI, Stamina & Dash Update

### 1. Core Movement & Procedural Pill Transforms
* Exact HTML5 prototype physics & bottom-anchored pill transforms (`idle`, `walk`, `sprint`, `crouch`, `jump`, `fall`, landing squash).
* **Intentional Crouch Superjump:** Hold `Shift` (`>= 0.18s`) + `Space` = `1.304x` jump velocity (`1.7x` jump height).
* **Mid-Air Double Jump:** `1.42x` jump velocity, recharges on floor.

### 2. Player Facing Direction Variable (`player_state_direction`)
* Float variable (`1.0` = facing right, `-1.0` = facing left), updated whenever `A` or `D` is pressed and remembered while standing still.
* Controls Dash direction and flips custom `Sprite2D` textures (`flip_h`).

### 3. Stamina Bar & Q-Key Dash
* Top-left cyan Stamina Bar (`100` max) positioned directly under the HP bar.
* Drains during Sprint (`16/s`), Dash (`30` cost), and SuperDoubleJump (`35` cost).
* Regenerates at `28/s` after a `0.65s` cooldown delay.
* Pressing `Q` triggers a horizontal burst (`980` speed for `0.14s`) in `player_state_direction` with suspended gravity and brief invulnerability.

### 4. SuperDoubleJump & Three-Tier Stomp System + Camera Screen Shake
* **Trigger:** Perform a Crouch Superjump (`jump_tier = 1`), then press `Space` again in mid-air with `>= 35` Stamina.
* **Effect:** Launches at `1.56x` jump velocity (`jump_tier = 3`) with tall vertical stretch and light camera shake (`3.5` intensity).
* **Aerial Stomps (`S` while falling):**
  * **Normal Stomp** *(after Superjump)*: `1350` fall speed, `0.36` squash, `0.22s` `stomp_land` recovery, subtle screen shake (`5.0` intensity).
  * **Mega Stomp** *(after Double Jump)*: `1850` fall speed, `0.50` squash, `0.36s` `stomp_land` recovery, medium screen shake (`8.5` intensity).
  * **SuperStomp** *(after SuperDoubleJump)*: `2250` fall speed, `0.62` pancake squash, `0.46s` `stomp_land` recovery, heavy screen shake (`14.0` intensity).

### 5. Separate Main Menu Scene (`control.tscn` + `control.gd`)
* Root `Control` node on pure black (`#000000`) background.
* Displays `D A T A R A I N` title, `PLAY` button (`Enter`/`Space`/Click), and controls bar at the bottom.
* Set as Godot's default startup scene; loads `res://main.tscn` on `PLAY`.

### 6. Death Screen & Velocity-Scaled Hazards
* Top-left HUD Health Bar (`100` HP) + Triangular Spikes (`25` base DMG + up to `+75` velocity fall bonus; SuperStomp impact = `100` lethal DMG).
* Triggers when HP reaches `0` (freezes gameplay).
* Displays red `YOU DIED` header + two buttons:
  * **RETRY (`R` / `Enter` / Click):** Resets HP, stamina, timers, and player position cleanly at spawn.
  * **MAIN MENU (`Esc` / Click):** Switches scene back to `control.tscn`.

---

## `[NEXT]` V1.1 — Custom Texture Update ("Texture Day")
* Replace procedural `ImageTexture` placeholders on isolated `Sprite2D` nodes:
  * `GroundSprite_ReplaceMe` -> Custom blue/cyber baseplate PNG.
  * `SpikeSprite_ReplaceMe` -> Custom spike cluster PNG.
  * `PlayerSprite_ReplaceMe` -> Swap textures dynamically by state string (`idle`, `walk`, `sprint`, `crouch`, `jump`, `fall`, `dash`, `stomp_land`).
* Flip sprites automatically using `player_state_direction < 0.0`.

---

## `[PLANNED]` V1.2 — Optimization & Modular Refactor Update
* Split monolithic `main.gd` into dedicated, low-RAM modular scenes:
  1. `control.tscn` / `control.gd` (Main Menu & future Settings).
  2. `player.tscn` / `player.gd` (`CharacterBody2D`, physics, stamina, dash, stomp tiers, state machine, and sprite swapping).
  3. `hud.tscn` / `hud.gd` (`CanvasLayer` listening to player signals for HP, Stamina, and Death Screen overlay).
  4. `main.tscn` / `level_1.tscn` (Arena floor, hazards, camera, and spawning).
* Connect `Player -> HUD/Camera` via Godot signals (`health_changed`, `stamina_changed`, `player_died`, `shake_requested`) for zero tight coupling.
* Possible project name refinement.

---

## `[FUTURE]` V2.0+ — Combat, Shaders & Atmosphere Expansion

* **Directional Melee / Knockback Combat:** Smash Bros.-inspired `%` / knockback scaling + Hollow Knight-inspired crisp hitstop and pogo bounces.
* **Aerial Slam Shockwaves:** Stomp tiers deal AoE damage & upward launch to nearby enemies on floor impact.
* **Gliding / Air-Mobility:** Extensions building on modular kinematics.
* **Golden Focus Regeneration (`.gdshader`):** Hollow Knight-style healing state featuring a warm golden glow shader around the player and rising inward particles.
* **Low-HP Heartbeat Danger State (`< 20%` HP):** Slow `< 60 BPM` heartbeat pulse where the camera subtly zooms in on every beat and triggers crimson screen-edge flashes at each peak (contrasting the warm golden regen glow).
* **Combo System:** Aerial & ground combo chains.
