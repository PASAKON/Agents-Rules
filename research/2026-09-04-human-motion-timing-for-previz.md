# Human motion timing for Blender previz — jumps and walks

🟢 **DURABLE.** This is physics and our own measurement. Gravity does not get
patched. The only perishable line is the proxy-speed adjustment at the bottom,
which is about how *our* legless proxies read, not about people.

Asked by the CEO on 2026-09-04 after rejecting three previz in a row for
movement that was "not a human jump" and an elderly man who "walks very fast
for an old man". Nothing in the research library covered motion timing.

## The finding that mattered

**The airtime was already right. The shape was wrong.**

A jump is ballistic. Once the feet leave the ground the body is a projectile
and nothing but gravity acts on it, so the vertical motion is a parabola: fast
off the ground, slowing all the way up, motionless for an instant at the apex,
then symmetrically back down.

Blender's default bezier interpolation does the exact opposite — it eases out
of the first keyframe and into the last, so the body creeps off the floor,
races through the middle of the arc and creeps into the landing. Two keyframes
and a default interpolation will never look like a jump no matter what numbers
you put in them.

## Jump numbers

    airtime = 2 * sqrt(2h/g)          g = 9.81 m/s²
    take-off velocity = sqrt(2gh)

| apex height | airtime | frames @24fps | take-off |
|---|---|---|---|
| 0.15 m | 0.35 s | 8 | 1.72 m/s |
| 0.20 m | 0.40 s | 10 | 1.98 m/s |
| **0.28 m** | **0.48 s** | **11** | **2.34 m/s** |
| 0.40 m | 0.57 s | 14 | 2.80 m/s |

But airtime is only the middle of the move. A counter-movement jump — the
ordinary kind, no run-up — is five phases, and skipping the first and last is
what makes an animation read as a glitch:

| phase | duration | frames |
|---|---|---|
| crouch (sink ~0.10–0.12 m) | 0.30 s | 7 |
| push-off (accelerating up) | 0.20 s | 5 |
| **flight (the parabola)** | 0.48 s | 11 |
| land and absorb (sink again) | 0.25 s | 6 |
| recover to standing | 0.20 s | 5 |
| **whole cycle** | **1.43 s** | **34** |

A 0.28 m hop takes about a second and a half end to end. Budget it as such: two
hops fill three seconds of screen time, not one.

## Walk numbers

| | speed | stride | cadence |
|---|---|---|---|
| adult, unhurried | 1.2–1.4 m/s | ~0.70 m | ~2 steps/s |
| elderly, or with a cane | 0.9–1.3 m/s | shorter | slower |
| hurrying, not running | 1.6–1.9 m/s | longer | faster |

Drive the keyframes from the speed, never the other way round:

    frames = round(distance / speed * fps)

Picking frame numbers by feel is how three previz in this project ended up with
an old man crossing a gallery at 1.87 m/s — faster than a healthy young adult
walks, in a heavy overcoat, with a cane.

## How to do it in Blender

```python
def hop(o, start, x, y, z0, h=0.28, crouch=0.11, fps=24.0):
    g = 9.81
    air = int(round(2 * math.sqrt(2 * h / g) * fps))
    CR, PU, AB, RE = 7, 5, 6, 5
    f = start
    for i in range(CR + 1):                       # sink
        key(o, f + i, x, y, z0 - crouch * (i / CR))
    f += CR
    for i in range(PU + 1):                       # drive, accelerating
        key(o, f + i, x, y, z0 - crouch + crouch * (i / PU) ** 2)
    f += PU
    for i in range(air + 1):                      # flight — sample the parabola
        t = i / air
        key(o, f + i, x, y, z0 + 4 * h * t * (1 - t))
    f += air
    for i in range(AB + 1):                       # land, absorb
        key(o, f + i, x, y, z0 - crouch * (i / AB))
    f += AB
    for i in range(RE + 1):                       # stand up
        key(o, f + i, x, y, z0 - crouch * (1 - i / RE))
    return f + RE
```

Two rules make it work:

1. **Sample the curve, do not key its endpoints.** `4*h*t*(1-t)` is the
   parabola through 0 at t=0, h at t=0.5 and 0 at t=1. One key per frame.
2. **Force LINEAR interpolation afterwards**, or Blender re-eases the samples
   and undoes the shape:

```python
for fc in obj.animation_data.action.fcurves:
    for kp in fc.keyframe_points:
        kp.interpolation = 'LINEAR'
```

## How to check it without watching the video

Read the velocity out of the blend rather than trusting your eye:

```python
prev = None
for fr in range(start, end):
    sc.frame_set(fr); z = obj.location.z
    if prev is not None:
        print(fr, round(z, 3), round((z - prev) * fps, 2))   # m/s
    prev = z
```

A correct jump prints: a slow negative during the crouch, a rising positive
through the push, a peak near `sqrt(2gh)` at take-off, a smooth fall to 0.00 at
the apex, then the mirror. **Deceleration between take-off and apex must come
out near 9.8 m/s².** Ours measured 10.7 across a two-frame average, which is
the expected over-read from differencing.

The first version of this hop printed ±6 to ±12 m/s. No human does that, and
the number said so instantly where the render only looked "a bit fast".

## 🟡 The one perishable line

Our previz proxies are cylinders with no legs, so they give the eye no gait
cues and read as gliding rather than walking. A physically correct 1.20 m/s
looks too fast on them. **0.95 m/s reads as an ordinary walk in our previz**
while the prompt still tells Seedance an ordinary unhurried pace. Re-measure
this if the proxies ever get legs.

Related: `docs/PREVIZ-INDEX.md` (build recipe and the three Blender traps),
`scripts/previz/s2d_previz.py` (the hop in use).
