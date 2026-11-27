# Building the String CoreXY

## Pins

Cut 1.75 mm filament into these lengths:

- 2 x 16 mm and 2 x 18 mm for the front and rear rail ends, cut flush
- 2 x 24 mm for the beam ends, cut flush
- 6 x 8 mm for the tops of the pulley posts
- 1 x 21 mm for the right knob, 1 x 14 mm for the left knob

The pulley and knob pins stick out about 1.5 mm each side. Melt both ends into small heads so they can't fall out.

## Assembly

1. Slide the carriage onto the beam.
2. Drop the beam ends into the channels of the two sliders and push a 24 mm pin sideways through each slider and the beam.
3. Slide a rail through each slider.
4. Drop the rail ends into the sockets on the four towers and pin each one from the side.
5. Put two pulleys on each front corner post and one on each slider post, raised ring at the bottom. Push an 8 mm pin through the hole at the top of each post and melt both ends. Keep the heads small so the pulleys still spin.
6. Drop each knob into its rear tower, push its pin through the side of the tower and melt both ends.

If the sliding feels grippy, rub candle wax or pencil graphite on the rails and beam.

## Stringing

Keep [renders/top.png](../renders/top.png) open. Loop A (red in the renders) uses the lower pulley grooves and the low holes in the carriage fins, and wraps the right knob. Loop B (blue) uses the upper grooves and the high holes, and wraps the left knob. Start with the carriage near the middle so each knob has yarn to wind both ways.

Loop A:

1. Tie one end through the right low hole of the front fin.
2. Go right to the inner (short) pulley on the right slider and around its front.
3. Go back to the right knob. Wrap the drum from the inner side, around the back, to the outer side. Pass the yarn once through the hole in the drum and add one or two extra turns so it can't slip.
4. Come forward to the lower pulley on the front right post.
5. Cross the front to the lower pulley on the front left post.
6. Go back to the outer (short) pulley on the left slider.
7. Go right to the left low hole of the rear fin, pull it snug and tie it off.

Loop B, the mirror image:

1. Tie one end through the right high hole of the rear fin.
2. Go right to the outer (tall) pulley on the right slider.
3. Come forward to the upper pulley on the front right post, then cross to the upper pulley on the front left post.
4. Go back up the left side to the left knob and wrap it the same way as loop A.
5. Go to the inner (tall) pulley on the left slider.
6. Go to the left high hole of the front fin, pull it snug and tie it off.

Both loops should be about equally tight, just enough that the yarn doesn't sag. If the gantry binds or goes crooked, the tensions are uneven. Cotton stretches a bit at first, so you may need to re-tie once.

With R = 6 mm (the drum radius), the knob angles in radians are $\theta_A = -(x + y)/R$ and $\theta_B = (y - x)/R$.

## Changing the size or fit

Everything is in [corexy.scad](../corexy.scad). In OpenSCAD, open Window > Customizer to turn the knobs, hide either loop, play the animations, change the size and clearances, and export single parts.

To export every part at once you need OpenSCAD 2021.01 or newer on your PATH, and [uv](https://docs.astral.sh/uv/):

```bash
uv run build.py
uv run build.py my_stl --work-x 100 --work-y 120 --slide-clearance 0.25
```

The default writes one file per copy into `stl/`. `--single` gives one file per part, `--legacy` forces the CGAL engine (slow), and `--help` lists every option. At the end it prints the part counts, frame size, yarn length and pin cut list for your size.

The work area is 72 x 80 mm by default and can be 50 to 150 mm in X and 50 to 170 mm in Y. The base is one piece of about (work_x + 83) x (work_y + 67) mm, so it has to fit your bed. Above about 120 mm the 8 x 8 mm bars flex noticeably.

## Heads

The carriage has a slot on its front face, open at the top, for a detachable head. `head_blank.stl` is a plain plate for testing the fit. For your own, use `head_tail()` and `on_head_mount()`:

```openscad
use <corexy.scad>
head_tail();
on_head_mount() {
  // origin: bottom centre, just in front of the slot. -Y points away
  // from the carriage, +Z is up. Overlap y = 0 a little so it fuses.
  translate([-7.5, -2, 0]) cube([15, 2.01, 10.4]);   // same as head_blank
}
```

The middle of the frame is open down to the table, so a pen head can reach paper underneath.
