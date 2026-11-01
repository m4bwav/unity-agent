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

One column per level, one row per element. The rows: name and scene file, story beat, gameplay focus, estimated
play time, time of day and colour scheme, enemies, mechanics, hazards, power-ups or new abilities, economy (what it
hands out) and music cue. Read across the rows and flag:

- more than two or three new things in one level (the first level is the exception);
- the same enemy and hazard combination, lighting, colour or music cue in neighbouring columns;
- an ability given late: every ability should arrive by about three quarters of the way through, so the last
  stretch uses them (heuristic);
- a new enemy or hazard that arrives before the tool that beats it;
- a level that hands out nothing, or more than the next one can use.

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
- Size gaps, ledges and corridors from the asset. A gizmo that draws the jump arc and reach at the player start
  lets the user check a grey-box in the Scene view. Make 3D corridors wider than the plan suggests (heuristic:
  about five hero widths), because first grey-boxes come out cramped.
- Once players have learned the numbers, do not change them mid-game: they judge distance by eye.
- Values in the asset are serialized: renaming a field drops its value (Step 3's serialized-field rule).

## 4. Test scenes and debug cheats

- `Assets/Scenes/_Playground.unity` holds the movement metrics course (every gap at the limit and just past it),
  each hazard and each power-up. `Assets/Scenes/_CombatArena.unity` spawns any enemy mix from a debug menu. Build
  both before the first real level, and create them through an editor script or `[MenuItem]`, never as hand-written
  YAML (Step 3).
- Cheats: level skip, invulnerability, grant item and money, a free camera for screenshots. Compile them out of
  release builds. The simplest gate is the built-in `DEVELOPMENT_BUILD` and `UNITY_EDITOR` symbols [verified].
  For a switch of your own, define a symbol such as `GAME_CHEATS` only in the development build profile (Build
  Profiles window, Build Data > Scripting Defines) [verified]. The project-wide place is Player Settings > Other
  Settings > Script Compilation > Scripting Define Symbols, then Apply [verified]. Wrap the code in `#if GAME_CHEATS`, or mark the entry points
  `[System.Diagnostics.Conditional("GAME_CHEATS")]`.
- Proof the cheats are gone: build or compile the release configuration (rung 2 or 3) and show that no cheat type
  is reachable, rather than trusting the define list.
- A demo slice is easier when level skip and the arena exist from the start.
- Time controls in the same cheat menu: pause (`Time.timeScale = 0`), single-step (advance one frame, then pause
  again), slow and fast play (`Time.timeScale = 0.25f` and `4f`). Drive the menu, its tweens and UI Animators from
  `Time.unscaledDeltaTime` (`Animator.updateMode = AnimatorUpdateMode.UnscaledTime`) so it still works while the
  game is paused. Gregory, Game Engine Architecture 2e (2014), sec. 7.4.2 and 9.5.
- Clamp long frames: `Time.maximumDeltaTime` caps `Time.deltaTime` after a hitch or a breakpoint, and with it the
  number of `FixedUpdate` calls one frame can run (`maximumDeltaTime / fixedDeltaTime`) [verified, Unity scripting
  reference]. Gregory, Game Engine Architecture 2e (2014), sec. 7.5.5.
- A tuning panel for the numbers designers change most (speeds, gravity, damage, spawn rates), editable at runtime
  and written back to the `PlayerMetrics` asset (section 3) or another ScriptableObject, so a change needs no
  recompile. Gregory, Game Engine Architecture 2e (2014), sec. 9.3.

### Gameplay architecture traps

- Prefer small components on one GameObject over deep `MonoBehaviour` inheritance trees; a new enemy should be a new
  mix of components, not a new subclass. Gregory, Game Engine Architecture 2e (2014), sec. 15.2.
- Update order bugs: the order of `Update` calls across scripts is not defined. When one script reads what another
  writes in the same frame, fix the order (`[DefaultExecutionOrder]` or Project Settings > Script Execution Order),
  move the reader to `LateUpdate`, or accept and document a one-frame lag. Gregory, Game Engine Architecture 2e
  (2014), sec. 12.5.2 and 15.6.
- A destroyed `UnityEngine.Object` is not C# null, but its overloaded `==` reports it equal to null. Test it with
  `== null` or `if (obj)`; `?.` and `??` skip the overload and touch the dead object. Gregory, Game Engine Architecture 2e (2014),
  sec. 15.5, on handles that read as null.
- Events raised while a list is being walked (an enemy dies during the damage pass, a spawn during the spawn loop):
  queue them and handle them after the loop, never add to or remove from the list inside it. Gregory, Game Engine
  Architecture 2e (2014), sec. 15.7.

## 5. Enemy card and encounter pacing

Fill one card per enemy before modelling or scripting it, in the attack-matrix asset or a `docs/enemies/` file:

| Field | Notes |
|---|---|
| Archetype | patroller, chaser, shooter, guard, flyer, bomber, burrower, teleporter, blocker (shield), mimic of the player |
| Size, speed, strength | they trade off: small is fast and weak, big is strong and slow; mid-size, fast and strong feels unfair |
| Speed against the player | a chaser runs a little slower than the player so retreat works |
| Movement and aggro radius | what makes it notice the player, and how far |
| Awareness | how it senses the player: radius, view cone and line of sight, hearing (sound reaches it late and fades), reaction time before it acts, and the cue that shows it has noticed. Millington, AI for Games, ch. 11 |
| States | at least normal and spotted, with a switch the player cannot miss (a bark, a pose, an icon); players notice the change more than the behaviour, and a missing switch reads as a bug. Millington, AI for Games, ch. 2 |
| Attacks and their tells | every attack has a wind-up, sound, glow or laser line the player can read |
| Health in hits | how many normal hits it takes; player health is the hits they should survive times average enemy damage |
| Weakness | follows the fiction (an ice enemy fears fire) |
| Variant of | a recoloured rig that behaves differently and reads differently at a glance |

Encounter rules:

- Pair archetypes so the player must choose a target. Pairs that work: a shield blocker in front of a shooter, a
  big chaser with small flyers, a teleporter with a chaser, a guard with a bomber overhead.
- Only one or two attack at once, even in a big group. In Unity this is usually an attack-token manager that
  enemies ask before attacking; cap the tokens, not the group size.
- Spawn out of the camera's view or behind a spawner the player can see and hit, never inside melee
  range. A first appearance is an event: frame it, name it, give the player a moment.
- Introduce things in order across a level or a game. Movement and collecting come first, then one mechanic until
  it is learned, then a second, then the two combined. Next a hazard over familiar ground, enemies alone, enemies
  with hazards, and last a twist on something familiar.
- No two big moments back to back; a quiet stretch follows a climax.
- Hazards look dangerous and keep predictable timing with a little leeway. No death the player could not see
  coming. Checkpoints face the direction of travel and sit on flat ground away from hazards and aggro radii; they
  respawn the player standing and save when touched. Offer, never force, an easier setting after repeated deaths.
  Never design an encounter around a target number of deaths.
- A boss fight is a readable pattern built on moves the player already has, or on one new ability, never both.
  It has a main attack to learn, a big attack to survive and a clearly lit weak-spot window, in rounds that
  escalate, in an arena built with the boss. The player lands the last hit, and a respawn should not reset the
  whole fight.

### AI performance and navigation

After Millington, AI for Games, ch. 2, 4, 6, 8 and 10, restated here. Unity names marked [verified] were read in the
Unity 6 scripting reference and the AI Navigation package 2.0 API on 2026-11-01 ([RESEARCH.md](../RESEARCH.md)
R-20261101-1).

- Stagger NPC thinking: give each enemy a random phase offset so their expensive updates do not land on the same
  frame, and run each layer at its own rate: movement every frame, perception a few times a second, tactics every
  few seconds. Pick intervals that share no common factor so the layers do not stack up.
- No allocation mid-level in AI code: pool paths, perception results and lists, and check the GC Alloc column in
  the Profiler with twenty enemies on screen.
- Move on a rough path first: a character that stands still while it plans looks broken, so head toward the
  goal (straight line or a coarse route) while the full path finishes, then switch.
- Path cost is a design tool: mark dangerous or exposed ground as its own NavMesh area, then weigh it per agent
  type, so a scout avoids open ground a brute walks across. Bake with `NavMeshSurface` (namespace
  `Unity.AI.Navigation`) [verified]; set per-agent costs with `NavMeshAgent.SetAreaCost(int areaIndex, float cost)`,
  index from `NavMesh.GetAreaFromName`, and limit walkable areas with `NavMeshAgent.areaMask` [verified]. Costs set
  by `SetAreaCost` reset when the agent is disabled and enabled again [verified], so set them in `OnEnable`.
- Jumps, drops, ladders and doors are `NavMeshLink`s (`bidirectional`, `width`, `costModifier`, `area`) [verified]
  placed with the level, not hard-coded in the enemy. Hand-placed cover, sniper and jump points get gizmos
  (`OnDrawGizmos`) so a designer can see them in the Scene view; most games need only a few simple tags.
- Leave passages wide enough for the AI to move through in groups; level layout and AI are one job.
- NavMeshAgent traps that tutorials repeat: test arrival with `!agent.pathPending && agent.remainingDistance <=
  agent.stoppingDistance`, never `transform.position == target` (floats almost never match, so the state never ends);
  pause with `agent.isStopped = true` or `ResetPath()`, not the obsolete `Stop()`; never move an agent's transform
  directly (`Translate`) while it is enabled, because it leaves the mesh and walks through walls: use `SetDestination`,
  `agent.Move`, or set `updatePosition = false` and drive it yourself; snap random patrol points to the mesh with
  `NavMesh.SamplePosition` before `SetDestination`; cache the agent in `Awake`, not `GetComponent` every frame.
- Carve with `NavMeshObstacle.carving` only for obstacles that really block a route (a closed gate, a parked
  truck); leave crates and other agents to local avoidance, because each carve rebuilds NavMesh tiles and costs CPU.
- Ledge drops and jumps: set `agent.autoTraverseOffMeshLink = false`, poll `agent.isOnOffMeshLink`, play the jump
  or drop animation along the link, then call `agent.CompleteOffMeshLink()`. Links come from `NavMeshLink` in the AI
  Navigation package (`com.unity.ai.navigation`), not the legacy `OffMeshLink` component older books use.
- Sight check, cheapest first: distance, then `Vector3.Angle` against the half-angle of the cone (name it so),
  then one `Physics.Raycast` with a layer mask of occluders plus the player; compare tags with `CompareTag`.
- Older tutorials (Unity 2019 to 2021) bake through the Navigation Static flag and the Navigation window; in
  Unity 6 that window is gone for new projects: add a `NavMeshSurface` and bake it, as above.
- One `System.Random` per subsystem (level layout, loot, AI choices), each seeded from one master seed, instead of
  the shared `UnityEngine.Random`, so the same seed builds the same level 2 whatever happened in level 1's fights.

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

A PlayMode test turns the first two items into a rung 3 check. Drive the player along a recorded path through the
level and assert on each frame that the player stays in view and unblocked. `path` and `player` are the test's
fixtures. Both C# blocks on this page compile against the Unity 6.6 Editor's assemblies with C# 9; neither has been
run inside a Unity project here.

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

1. The agent, alone, where it can. Through the live Editor (unity-agent-cli: `editor_play`, `eval`,
   `console --level error`), teleport the player backwards along the level, through every door from the far side,
   out of bounds and onto wall tops. Run past enemies to see whether they follow, and set each tuning value to its
   extremes. Report errors, stuck states and falls through the world.
2. The user, alone: play it as a player would, not in god mode; hug walls, jump at the camera's edges, play
   on each target platform.
3. Fresh eyes: someone new, with the screen and their face recorded. Write the questions before the session (can
   they find the exit, read the goal, beat the fight, use the menus?) and watch without helping.
4. Act on a problem when several testers hit it; suggestions are optional.

Questions for afterwards: what were you trying to do; where were you confused, frustrated or bored; how long did
it feel; what felt unfair; best and worst moment; would you play again. A development-build logger that writes
each death and the player's position every few seconds to a CSV gives a cheap heat map for the next pass.

Feedback the playtest should check: success is praised in layers (sound, animation, effect, text) and only for
real achievements; success sounds rise in pitch and failure sounds fall; every sound that carries gameplay
information has a visual twin.

## 9. ML-Agents training checklist

After Lapan, Deep Reinforcement Learning Hands-On, 3rd ed. 2024, restated here. ML-Agents names marked [verified] were
read in the ML-Agents docs (release 23) on 2026-11-01 ([RESEARCH.md](../RESEARCH.md) R-20261101-2). Use it when the game
trains an agent with the ML-Agents package.

- Observations must tell states apart (ch. 6). If one frame cannot show where things are heading, add the velocity or set
  `Stacked Vectors` on Behavior Parameters [verified]; a stack also turns a one-frame view into a short history.
- Rewards (ch. 1, 6): reward each step's change in progress, not a lump at the end, and keep each step's reward within
  -1..1, since larger values destabilise training [verified]. Do any hidden start action (a spawn, a reset
  pose) in `OnEpisodeBegin()` [verified], so every episode starts from a state the agent can observe.
- Speed (ch. 9, 12): put many copies of the training area in one scene, run several environment instances with
  `--num-envs`, and train on a build with `engine_settings` `no_graphics: true` and a high `time_scale` [verified].
- Trainer (ch. 16): `trainer_type: ppo` is the default [verified]. Run several seeds of a run and compare them before
  judging a change; one lucky seed proves nothing.
- Sparse goals (ch. 18): add an intrinsic signal under `reward_signals`, `curiosity` or `rnd` [verified].
- Hard to discover (ch. 14): record play with the `Demonstration Recorder` component and train with `behavioral_cloning`
  or the `gail` reward signal, both fed by a `demo_path` [verified].
- Self-play (ch. 20): the `self_play` block keeps snapshots of the policy; judge them by the ELO the trainer reports from
  match results (a +1/0/-1 final reward), not by loss [verified].

When training fails (after Graesser and Keng, Foundations of Deep Reinforcement Learning, 2019):

- First check it beats an agent that picks random actions; matching random means nothing is learning yet.
- Watch the policy entropy curve in TensorBoard: it should start high and fall slowly. Flat means no learning; a crash
  early on means exploration died.
- Look at what the agent sees: draw its observations with Debug draws or preview the camera sensor's image. Most bugs
  live between the game state and the observation.
- Prove the setup on a tiny scene that trains in minutes before moving to the real level.
- Keep the default config's hyperparameters until the bugs are gone; tune last.

Action design (same book):

- One discrete branch per control (move, turn, jump) rather than one action per combination.
- Relative moves (turn left, step forward) for local control; absolute targets only for global choices.
- Start with a few coarse discrete steps; go continuous only when the coarse set limits play.
- Mirror symmetric actions (left and right) so the agent learns one and gets both.
- Start with the fewest actions that can solve the task and add more later.
