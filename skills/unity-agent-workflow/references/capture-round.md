# Capture rounds: judge visual changes by matched renders

Back to [SKILL.md](../SKILL.md). Rung 4 of the ladder, for any change whose result is a look (lighting, shaders, terrain, LOD, VFX, camera).

Numbers can pass while the picture is wrong: a project can drift for weeks on green numeric checks that never looked right. So every visual change gets a capture round, and the numbers only back up what the pictures show. Technique from a public 2026-11 write-up of a Unity 6 planet renderer built with Claude Code, written fresh here.

## The round

1. Keep a small set of named views in the repo (`Shots~/views/<name>.json`): fixed viewpoints that cover the feature, plus any view the user flagged.
2. Before the change, capture every view. After it, capture the same views.
3. Compare each pair with a difference image: threewright's `tw diff before.png after.png --out d.png` works on any PNG (pixel share changed, largest channel change, red overlay). Put before, after and difference side by side on one sheet when the user should look.
4. Look at the sheets first, then read the numbers. Say in one line per view what changed and whether it was meant to.

## View stamp: every capture carries its view

Write the camera pose next to every capture, so a screenshot someone calls wrong can be reopened at exactly that view and measured there. Checked 2026-11-21 on a Unity 6.6 Editor through the Unity CLI (Pipeline eval): saved, read back and parsed, pose and fov matched exactly. Numbers are written in the invariant culture so a comma-decimal locale reads them back.

Save (one eval after the capture; `Shots~/x.png` becomes `Shots~/x.view.json`):

```
unity command eval 'var c = UnityEngine.Camera.main; var t = c.transform; System.IO.File.WriteAllText("Shots~/x.view.json", UnityEngine.JsonUtility.ToJson(new UnityEngine.Pose(t.position, t.rotation)) + "\n" + c.fieldOfView.ToString(System.Globalization.CultureInfo.InvariantCulture) + " " + UnityEngine.Time.time.ToString(System.Globalization.CultureInfo.InvariantCulture)); return t.position.ToString("F3") + " " + t.eulerAngles.ToString("F2");'
```

Restore (before the after-capture, in Play Mode if the game owns the camera, and turn off whatever drives it for that frame):

```
unity command eval 'var l = System.IO.File.ReadAllText("Shots~/x.view.json").Split(new[]{"\n"}, 2, System.StringSplitOptions.None); var p = UnityEngine.JsonUtility.FromJson<UnityEngine.Pose>(l[0]); var c = UnityEngine.Camera.main; c.transform.SetPositionAndRotation(p.position, p.rotation); c.fieldOfView = float.Parse(l[1].Split(new[]{" "}, System.StringSplitOptions.None)[0], System.Globalization.CultureInfo.InvariantCulture); return "ok";'
```

Add time of day or weather to the second line when the scene has them. When the user reports "this looks wrong", ask for (or make) the view file first, reproduce at that view, measure, and only then change code.

## Tools that measure motion

Still captures miss what happens in motion. Have the agent write small tools for the defect at hand rather than eyeballing a flight: a recorded camera route replayed the same way every run, frame times logged along it, a count of one-frame flashes (mean brightness jumping and returning within a frame or two), a push-in that counts objects or tiles that pop in, a check along region or chunk seams. Each prints a number per run, so before and after compare.

## Large worlds and temporal AA

Past a few kilometres, float32 positions jitter. Keep the camera at the origin and the world position in doubles, moving the world instead (floating origin). URP's TAA and motion blur then never see the camera travel, and history blends wrong: feed the travel back (shift the previous-frame view matrix by the same offset), or every move reads as no motion and smears. Unverified here; prove it with a flash-and-ghosting count along a recorded route before and after.
