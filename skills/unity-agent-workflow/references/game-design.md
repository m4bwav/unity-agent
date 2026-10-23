# Game design before code (a Unity game)

Back to [SKILL.md](../SKILL.md). Use this page when the request is a new game, a level, an enemy, a weapon, the
player's movement or the camera, rather than a fix or a refactor. The design rules are after Scott Rogers,
*Level Up! The Guide to Great Video Game Design* (3rd ed.), restated here in this skill's own words; the Unity
parts are this skill's. Unity names marked [verified] were read in the docs on 2026-10-23 ([RESEARCH.md](../RESEARCH.md)
R-20261023-1). Numbers marked (heuristic) are rules of thumb from the book: start there, then tune them in playtests.

The agent writes the documents below as files in the user's repo (`docs/` unless the repo has its own place), keeps
them current, and checks each new request against them. A request that does not serve the core loop gets one line
saying so, and the user decides.

## 1. The one-pager (`docs/ONE-PAGER.md`, before the first gameplay script)

Ask for, or draft and confirm, these fields:

| Field | What goes in it |
|---|---|
| Working title | one name the team uses |
| Platforms and controls | PC with pad, mobile touch, and so on |
| Audience | age and the rating it aims for |
| Core loop | the one verb the player does most ("jump", "build", "dodge"), plus the short loop around it |
| Session length | how long one level or run lasts on the main platform: on mobile, a few minutes (heuristic: 2-5) |
| Selling points | about five things that make it different |
| Comparables | two or three successful games it resembles |
| Out of scope | what it will not have, so features can be refused early |

Everything built should serve the core loop. A system that will appear fewer than three times is rarely worth
building (heuristic); reuse and recolour a few systems instead.

## 2. The beat chart (`docs/BEAT-CHART.md`, once there are three or more levels)

One column per level, one row per element: name and scene file, story beat, gameplay focus, estimated play time,
time of day and colour scheme, enemies, mechanics, hazards, power-ups or new abilities, economy (what it hands out),
music cue. Read across the rows for:

- **Clumping**: more than two or three new things in one level (the first level is the exception).
- **Sameness**: the same enemy and hazard combination, lighting, colour or music cue in neighbouring columns.
- **Late tools**: every ability should be given by about three quarters of the way through, so the last stretch
  uses them (heuristic).
- **Pairing**: each new enemy or hazard arrives with, or after, the tool that beats it.
- **Economy gaps**: a level that hands out nothing, or more than the next one can use.

The music row is what a composer or the musicwright plugin plans cues from, so fill it.

## 3. Player metrics in one asset

Measure the world in the hero's units: height, width, walk and run speed, jump height and distance, melee reach,
projectile range. Keep them in one ScriptableObject that the character controller and the level tools both read, so
a global change is one edit and nobody builds a gap by eye.

```csharp
[CreateAssetMenu(menuName = "Game/Player Metrics")]
public sealed class PlayerMetrics : ScriptableObject
{
    public float height = 1.8f, width = 0.5f;
    public float walkSpeed = 4f, runSpeed = 7f;
    public float jumpHeight = 1f, jumpDistance = 3f;   // design these, derive gravity and impulse from them
    public float meleeReach = 1.2f, shotRange = 20f;
}
```

- Derive the physics from the design numbers (jump impulse from `jumpHeight` and gravity), not the other way round,
  and cover the derivation with a rung 1 test.
- Size gaps, ledges and corridors from the asset: a gizmo or an editor tool that draws the jump arc and reach at
  the player start lets the user check a grey-box by eye in the Scene view. A 3D corridor is roomier than it looks
  in a plan (heuristic: about five hero widths), because first grey-boxes come out cramped.
- Once players have learned the numbers, do not change them mid-game: they judge distance by eye.
- Values in the asset are serialized: renaming a field drops its value (Step 3's serialized-field rule).

## 4. Test scenes and debug cheats

- `Assets/Scenes/_Playground.unity` holds the movement metrics course (every gap at the limit and just past it),
  each hazard and each power-up. `Assets/Scenes/_CombatArena.unity` spawns any enemy mix from a debug menu. Build
  both before the first real level, and create them through an editor script or `[MenuItem]`, never as hand-written
  YAML (Step 3).
- Cheats: level skip, invulnerability, grant item and money, a free camera for screenshots. Compile them out of
  release builds. Either gate them on the built-in `DEVELOPMENT_BUILD` and `UNITY_EDITOR` symbols [verified], or
  define a custom symbol such as `GAME_CHEATS` only in the development build profile (Build Profiles window,
  Build Data > Scripting Defines; project-wide it is Player Settings > Other Settings > Script Compilation >
  Scripting Define Symbols, then Apply) [verified]. Wrap the code in `#if GAME_CHEATS`, or mark the entry points
  `[System.Diagnostics.Conditional("GAME_CHEATS")]`.
- Proof the cheats are gone: build or compile the release configuration (rung 2 or 3) and show that no cheat type
  is reachable, rather than trusting the define list.
- A demo slice is easier when level skip and the arena exist from the start.

## 5. Enemy card and encounter pacing

Fill one card per enemy before modelling or scripting it, in the attack-matrix asset or a `docs/enemies/` file:

| Field | Notes |
|---|---|
| Archetype | patroller, chaser, shooter, guard, flyer, bomber, burrower, teleporter, blocker (shield), mimic of the player |
| Size, speed, strength | they trade off: small is fast and weak, big is strong and slow; mid-size, fast and strong feels unfair |
| Speed against the player | a chaser runs a little slower than the player so retreat works |
| Movement and aggro radius | what makes it notice the player, and how far |
| Attacks and their tells | every attack has a wind-up, sound, glow or laser line the player can read |
| Health in hits | how many normal hits it takes; player health is the hits they should survive times average enemy damage |
| Weakness | follows the fiction (an ice enemy fears fire) |
| Variant of | a recoloured rig that behaves differently and reads differently at a glance |

Encounter rules:

- **Pair archetypes** so the player must choose a target: a shield blocker in front of a shooter, a big chaser with
  small flyers, a teleporter with a chaser, a guard with a bomber overhead.
- **Only one or two attack at once**, even in a big group. In Unity this is usually an attack-token manager that
  enemies ask before attacking; cap the tokens, not the group size.
- **Spawn safely**: out of the camera's view or behind a spawner the player can see and hit, never inside melee
  range. A first appearance is an event: frame it, name it, give the player a moment.
- **Orchestrate in order** across a level or a game: movement and collecting, one mechanic until it is learned, a
  second, the two combined, a hazard over familiar ground, enemies alone, enemies with hazards, then a twist on
  something familiar.
- **Pace big moments against small ones**: no two big moments back to back, a quiet stretch after a climax.
- **Fairness**: hazards look dangerous and keep predictable timing with a little leeway; no death the player could
  not see coming; checkpoints face the direction of travel, sit on flat ground away from hazards and aggro radii,
  respawn the player standing, and save when touched. Offer, never force, an easier setting after repeated deaths.
  Never design an encounter around a target number of deaths.
- **Bosses**: a readable pattern built on moves the player already has, or on one new ability, never both; a main
  attack to learn, a big attack to survive, a clearly lit weak-spot window, rounds that escalate, an arena built
  with the boss, and the player lands the last hit. A respawn should not reset the whole fight.

## 6. Camera checklist (Cinemachine 3 or a custom follow camera)

Cinemachine 3 renamed its components and moved to the `Unity.Cinemachine` namespace [verified]. Use the 3.x names
and do not mix in 2.x ones from old tutorials:

| Job | Cinemachine 3 component [verified] | 2.x name it replaced |
|---|---|---|
| The camera | `CinemachineCamera` | `CinemachineVirtualCamera` |
| Follow at an offset | `CinemachineFollow` | `CinemachineTransposer` |
| Frame the target on screen | `CinemachinePositionComposer` | `CinemachineFramingTransposer` |
| Aim at the target | `CinemachineRotationComposer` | `CinemachineComposer` |
| Shoulder camera | `CinemachineThirdPersonFollow` | `Cinemachine3rdPersonFollow` |
| Keep out of walls | `CinemachineDeoccluder` | `CinemachineCollider` |
| Keep inside the level | `CinemachineConfiner2D` or `CinemachineConfiner3D` | `CinemachineConfiner` |

Check the installed version in `Packages/manifest.json` before writing camera code (unity-agent-packages); 3.1.5
was current for Unity 6.2 when this was written. The checklist, whichever camera is used:

- It never clips through geometry, and the character is never lost behind it (pull in, fade the wall, or outline
  the character).
- Corners make follow cameras flip, so keep pickups, objectives and AI paths out of tight corners.
- Damping is smooth on start and stop; sudden acceleration makes players sick.
- It shows where to go: the objective is in frame when the player arrives at a junction.
- A scripted shot that takes control away is obvious (letterbox, a cut, input ignored visibly), and hands control
  back cleanly.

A PlayMode test makes the first two items a rung 3 check: drive the player along a recorded path through the level
and assert each frame that the player stays in view and unblocked.

```csharp
[UnityTest]
public IEnumerator CameraKeepsPlayerVisibleAlongPath()
{
    foreach (var point in path.Points)        // a recorded or authored list of positions
    {
        player.position = point;
        yield return null;                    // let the brain update
        var cam = Camera.main;
        var v = cam.WorldToViewportPoint(player.position);
        Assert.That(v.z > 0 && v.x is > 0.05f and < 0.95f && v.y is > 0.05f and < 0.95f, $"player off screen at {point}");
        Assert.IsFalse(Physics.Linecast(cam.transform.position, player.position + Vector3.up, out var hit)
                       && hit.transform != player, $"view blocked by {hit.transform?.name} at {point}");
    }
}
```

## 7. Attack matrix

One row per attack or weapon: name, input, range, speed or fire rate, direction, damage, special effect, the niche
it fills. Each row needs a niche the others lack, and any overlap costs something (reload time, speed). Keep it
as data so a balance pass is a table edit: one ScriptableObject per weapon, or a CSV such as
`Assets/Data/attacks.csv` imported into those assets by an importer (Step 3's importer rule). An engine-free test
can then flag two rows with the same range band and damage band.

Press means act: the attack starts on the button press, and only heavy attacks wind up, as the price of their
damage. Every hit is sold with a reaction animation, an impact sound and effect, hit-pause or shake on big hits,
and the player's own hits stay loud whatever the distance. Stuns, knockback and grabs are short and escapable, and
never chain the player into a hazard. A shooter keeps a melee fallback for an empty magazine.

## 8. Playtest protocol and questionnaire

The ladder's rung 5 is a playtest. Hand the user this protocol rather than "please playtest".

1. **Solo, by the agent where it can**: through the live Editor (unity-agent-cli: `editor_play`, `eval`,
   `console --level error`), teleport the player backwards along the level, through every door from the far side,
   out of bounds and onto wall tops; run past enemies to see whether they follow; set each tuning value to its
   extremes. Report errors, stuck states and falls through the world.
2. **Solo, by the user**: play it as a player would, not in god mode; hug walls, jump at the camera's edges, play
   on each target platform.
3. **Fresh eyes**: someone new, with the screen and their face recorded, and the questions written before the
   session (can they find the exit, read the goal, beat the fight, use the menus?). Watch without helping.
4. Act on a problem when several testers hit it; suggestions are optional.

Questions for afterwards: what were you trying to do; where were you confused, frustrated or bored; how long did
it feel; what felt unfair; best and worst moment; would you play again. A development-build logger that writes
each death and the player's position every few seconds to a CSV gives a cheap heat map for the next pass.

Feedback the playtest should check: success is praised in layers (sound, animation, effect, text) and only for
real achievements; success sounds rise in pitch and failure sounds fall; every sound that carries gameplay
information has a visual twin.
