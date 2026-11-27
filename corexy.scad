// String CoreXY toy
//
// A CoreXY you turn by hand. The parts are printed, the belts are two loops
// of yarn, and the screws are offcuts of 1.75 mm filament.
//
// Open Window > Customizer to turn the knobs, hide parts, play an animation,
// change the size or the fit, and pick a single part to export.
// build.py exports every part in one go.
//
// Axes: +X is right, +Y is back (where the knobs are), +Z is up.
// The table is at z = 0.

/* [View] */
// what to draw ("none" draws nothing and only prints the summary)
part = "assembly"; // [assembly:Assembly, base:Base, rail:Rail (print 2), slider_r:Right slider, slider_l:Left slider, beam:Beam, carriage:Carriage, pulley:Pulley (print 8), knob:Knob (print 2), head_blank:Example head (optional)]
// right knob, % of its full range (100 = turned until the carriage reaches a corner)
right_knob = 0;  // [-100:0.5:100]
// left knob, % of its full range (counter-clockwise from above is +)
left_knob = 0;  // [-100:0.5:100]

/* [Size] */
// carriage travel left-right (mm)
work_x = 72;  // [50:2:150]
// carriage travel front-back (mm)
work_y = 80;  // [50:2:170]

/* [Animate] */
// turn on View > Animate, then set FPS 10 and Steps 60
animate = "none"; // [none:Off, x:X (both knobs same way), y:Y (knobs opposite ways), right:Right knob only (diagonal), left:Left knob only (other diagonal), circle:Circle (both knobs)]

/* [Show / hide parts] */
show_base = true;
show_rails = true;
show_sliders = true;
show_beam = true;
show_carriage = true;
// example head in the carriage's front slot
show_head = true;
show_front_pulleys = true;
show_gantry_pulleys = true;
show_knobs = true;
// filament pins
show_pins = false;
// loop A: red, lower level, right knob
show_loop_A = true;
// loop B: blue, upper level, left knob
show_loop_B = true;

/* [Fit - tune these for your printer] */
// gap per side for parts that slide (slider on rail, carriage on beam)
slide_clearance = 0.2;
// gap per side for parts that sit in a socket (rail and beam ends, head slot)
socket_clearance = 0.15;
// gap per side for parts that spin (pulleys on posts, knob shafts)
spin_clearance = 0.25;
// hole for 1.75 mm filament pins (all of them print sideways)
pin_hole = 2.3;
// yarn thickness
yarn_d = 1.1;
// yarn holes in the carriage fins and knob drums
yarn_hole = 2.5;

/* [Hidden] */
$fn = $preview ? 40 : 72;

SLIDE = slide_clearance;
FIT   = socket_clearance;
SPIN  = spin_clearance;

FIL       = 1.75;  // filament used for pins
POST_D    = 5;     // printed pulley post
SHAFT_D   = 5;     // knob shaft
SHAFT_L   = 9;
PIN_STICK = 1.5;   // pin left sticking out per end, melted into a head
MUSH_D    = 2.8;   // size of a melted pin head (drawing only)
CORNER_R  = 2;     // rounded vertical corners on the base, towers and sliders

// ---------------- input checks ---------------------------------------
function join(v, sep = ", ", i = 0) = i >= len(v) ? "" : str(i ? sep : "", v[i], join(v, sep, i + 1));
function has(v, x) = len([for (e = v) if (e == x) 1]) > 0;

// [part, how many to print]
PRINT = [["base",1], ["rail",2], ["slider_r",1], ["slider_l",1], ["beam",1],
         ["carriage",1], ["pulley",8], ["knob",2], ["head_blank",1]];
PARTS = concat(["assembly", "none"], [for (p = PRINT) p[0]]);
MOVES = ["none", "x", "y", "right", "left", "circle"];

assert(has(PARTS, part), str("Unknown part \"", part, "\". Use one of: ", join(PARTS), "."));
assert(has(MOVES, animate), str("Unknown animate \"", animate, "\". Use one of: ", join(MOVES), "."));
assert(work_x >= 50 && work_x <= 150, str("work_x is ", work_x, " mm. It must be between 50 and 150."));
assert(work_y >= 50 && work_y <= 170, str("work_y is ", work_y, " mm. It must be between 50 and 170."));
for (c = [["slide_clearance", SLIDE], ["socket_clearance", FIT], ["spin_clearance", SPIN]])
  assert(c[1] >= 0 && c[1] <= 1, str(c[0], " is ", c[1], " mm. It is a gap per side and must be between 0 and 1."));
assert(pin_hole > FIL && pin_hole <= 3.5,
  str("pin_hole is ", pin_hole, " mm. It must be more than the ", FIL, " mm filament and at most 3.5."));
assert(yarn_d > 0 && yarn_d <= 3, str("yarn_d is ", yarn_d, " mm. It must be more than 0 and at most 3."));
assert(yarn_hole > yarn_d, str("yarn_hole is ", yarn_hole, " mm. It must be bigger than yarn_d (", yarn_d, " mm)."));

// ---------------- yarn layout (top view) -----------------------------
RP  = 5;           // yarn radius around an idler pulley
RM  = 6;           // yarn radius on a knob drum
TURN = 2*PI*RM;    // yarn moved by one knob turn
// The whole frame follows from these three. The offsets are what the
// carriage, sliders and towers take up beyond the travel.
F   = work_x/2 + 33.5;   // x of the outer pulleys (front corners, outer gantry posts)
FY  = -work_y/2 - 23.5;  // front pulley y
Y0  = work_y/2 + 26;     // knob y
KX  = F + RP - RM; // knob x: its outer run lines up with the front pulley
JIN = F - 2*RM;    // inner gantry pulley x: lines up with the knob's inner run
XR  = F - RM;      // rail centre x, between the two gantry posts

// ---------------- heights --------------------------------------------
BASE_T  = 3;  RING = 7;
RAIL_W  = 8;  RAIL_H = 8;  RAIL_Z = 7.5;
SL_FLOOR = 2; SL_ROOF = 2.5;
SL_Z0   = RAIL_Z - SLIDE - SL_FLOOR;                  // slider bottom
SL_TOP  = RAIL_Z + RAIL_H + SLIDE + SL_ROOF;          // slider top, same as front tower top
SEAT    = 0.5;  SEAT_R = 3.6;                         // raised ring a pulley sits on

// idler pulley: V-groove with 45 degree flanks, prints without support
P_BORE = POST_D + 2*SPIN;
P_RO = RP + 1.5;  P_RG = RP - yarn_d/2;  P_FL = 1;  P_GW = yarn_d + 0.3;
P_FLANK = P_RO - P_RG;
P_H  = 2*P_FL + 2*P_FLANK + P_GW;
P_ZS = P_FL + P_FLANK + P_GW/2;                       // yarn height inside a pulley
HUB  = 0.5;  HUB_R = P_BORE/2 + 0.6;

ZP_A = SL_TOP + SEAT;          // lower pulley bottom
ZA   = ZP_A + P_ZS;            // loop A height
TOP_A = ZP_A + P_H + HUB;
ZP_B = TOP_A;                  // upper pulley sits on the lower one's hub
ZB   = ZP_B + P_ZS;            // loop B height
TOP_B = ZP_B + P_H + HUB;

// cross pin just above the top pulley on a post
function xpin_z(top) = top + 0.3 + pin_hole/2;
function post_top(top) = xpin_z(top) + pin_hole/2 + 1.2;
XPIN_L = POST_D + 2*PIN_STICK;

// knob: yarn drum + grip on a printed shaft, held down by a pin in a groove
K_RO = RM + 2; K_RG = RM - yarn_d/2; K_FLB = 1.5; K_FLT = 1; K_GW = 4.5;
K_FLANK = K_RO - K_RG;
K_DRUM_H = K_FLB + 2*K_FLANK + K_GW + K_FLT;
K_ZS = K_FLB + K_FLANK + K_GW/2;
K_GRIP_R = 7; K_GRIP_H = 9;
K_GRIP_Z = K_DRUM_H + K_RO - K_GRIP_R;   // grip bottom, from the knob bottom
KA_Z = ZA - K_ZS;              // right knob bottom (loop A)
KB_Z = ZB - K_ZS;              // left knob bottom (loop B)
K_GROOVE_Z = -SHAFT_L/2;       // shaft groove, from the knob bottom
K_GROOVE_R = SHAFT_D/2 - 0.7;
KPIN_OFF = K_GROOVE_R + FIL/2 + 0.15;   // lock pin offset from the knob axis
COL_R = 6;                     // column under the raised (left) knob

// ---------------- frame -----------------------------------------------
FT_IN = 11;                    // front tower inner face = FY + FT_IN
RT_IN = 13.5;                  // rear tower inner face = Y0 - RT_IN
RT_TOP = RAIL_Z + RAIL_H + 0.3;
RAIL_Y0 = FY + 3;  RAIL_Y1 = Y0 - 6.5;
RAIL_PINS = [FY + 7, Y0 - 10];
BX = F + 8;  BY0 = FY - 8;  BY1 = Y0 + 9;
TW_X0 = F - 12;                // towers' inner x
FT_XOUT = F + 3.5;             // front tower outer x
RT_XOUT = F + 5.5;             // rear tower outer x
RAIL_GAP = 1.0;                // sockets are this much longer at each rail end, so the pins set the rail position
RPIN_Z = RAIL_Z + RAIL_H/2;

// ---------------- gantry ----------------------------------------------
SL_HL    = 12;                         // slider half length
// The beam socket is an open-top channel, so it prints without a bridge.
// It stops short of the inner post so the post stands on solid plastic.
SOCK_END = JIN - SEAT_R - 0.3;
SL_XIN   = SOCK_END - 9;               // 9 mm deep socket
END_GAP  = 1.5;                        // gap past the beam end
SL_XOUT  = F + POST_D/2 + 0.5;
BEAM_W = 8; BEAM_H = 8; BEAM_Z = RAIL_Z;
BEAM_HL = SOCK_END - END_GAP;
BPIN_X  = (SL_XIN + BEAM_HL) / 2;      // beam pin x
BPIN_Z  = BEAM_Z + BEAM_H / 2;

// ---------------- carriage --------------------------------------------
// A sleeve on the beam plus two thin fins, one on each yarn line (y = +-RP).
CW_H = 7.5;                            // half width
C_WALL = 2;
CY_H = BEAM_W/2 + SLIDE + C_WALL;
C_Z0 = BEAM_Z - SLIDE - 1.6;
S_TOP = BEAM_Z + BEAM_H + SLIDE + 1.6; // sleeve top
FIN_T = 2.4;
TIE_IN = yarn_hole/2 + 1.5;            // tie hole centre from the fin end
TIE_X = CW_H - TIE_IN;
C_TOP = ZB + yarn_hole/2 + 1.5;

// Head slot on the front face: a thin T-slot, open at the top and closed at
// the bottom. A head's flange slides down behind the two front lips.
TS_WALL  = 1.0;                        // side walls
TS_LIP   = 1.2;                        // front lips
TS_FLOOR = 1.2;
TS_FL    = 1.6;                        // head flange thickness
TS_W1    = 2*CW_H - 2*TS_WALL;         // slot width behind the lips
TS_W0    = 8;                          // mouth between the lips
TS_YB    = -CY_H;                      // slot back = sleeve front face
TS_YL    = TS_YB - TS_FL - 2*FIT;      // inside face of the lips
TS_YF    = TS_YL - TS_LIP;             // slot front face
TS_Z0    = C_Z0 + TS_FLOOR;            // slot floor
TS_TOP   = S_TOP;
HEAD_GAP = 0.3;                        // gap between a head and the slot front
HEAD_T   = 2;                          // example head plate thickness
HEAD_H   = TS_TOP - TS_Z0;

// travel limits
CX_MAX = SL_XIN - 1 - CW_H;
JY_MIN = FY + FT_IN + 0.5 + SL_HL;
JY_MAX = Y0 - RT_IN - 0.5 - SL_HL;

// ---------------- summary ----------------------------------------------
FRAME_X = 2*BX;
FRAME_Y = BY1 - BY0;
// yarn per loop: the path plus about 25 cm for the ties and drum wraps
YARN_CM = ceil((4*F + 2*(Y0 - FY)) / 10 + 25);
echo(str("Size: travel ", work_x, " x ", work_y, " mm, frame ", FRAME_X, " x ", FRAME_Y,
         " mm, yarn about ", YARN_CM, " cm per loop (2 loops)"));
echo(str("The base is one piece, so your printer bed has to be at least ",
         FRAME_X, " x ", FRAME_Y, " mm."));
if (work_x > 120 || work_y > 120)
  echo("WARNING: rails/beam longer than ~200 mm; the 8 x 8 mm printed bars will flex more.");

// ---------------- current position -------------------------------------
// The knobs set the carriage position:
//   right knob turns = -(x + y) / TURN,   left knob turns = (y - x) / TURN
// While animating, the position comes from $t instead.
function clamp(v, lo, hi) = max(lo, min(hi, v));
// 100% = the turns one knob alone needs to take the carriage from the centre to a corner
KNOB_MAX = 2 * min(CX_MAX, JY_MAX, -JY_MIN) / TURN;
R_TURNS = right_knob / 100 * KNOB_MAX;
L_TURNS = left_knob / 100 * KNOB_MAX;
KNOB_X = -(R_TURNS + L_TURNS) * TURN / 2;
KNOB_Y =  (L_TURNS - R_TURNS) * TURN / 2;
if (part == "assembly" && animate == "none")
  echo(str("Knobs: right ", round(R_TURNS*100)/100, " turns, left ", round(L_TURNS*100)/100,
           " turns (100% = ", round(KNOB_MAX*100)/100, " turns at this size)"));
AMP_D = min(CX_MAX, JY_MAX);
// right knob alone moves along x = y (left knob still), left knob alone along x = -y
PX = animate == "x"      ? CX_MAX * sin(360*$t)
   : animate == "y"      ? 0
   : animate == "right"  ? AMP_D * sin(360*$t)
   : animate == "left"   ? -AMP_D * sin(360*$t)
   : animate == "circle" ? 0.8 * CX_MAX * cos(360*$t)
   : clamp(KNOB_X, -CX_MAX, CX_MAX);
PY = animate == "x"      ? 0
   : animate == "y"      ? JY_MAX * sin(360*$t)
   : animate == "right"  ? AMP_D * sin(360*$t)
   : animate == "left"   ? AMP_D * sin(360*$t)
   : animate == "circle" ? 0.8 * JY_MAX * sin(360*$t)
   : clamp(KNOB_Y, JY_MIN, JY_MAX);
if (animate == "none" && (PX != KNOB_X || PY != KNOB_Y))
  echo("Note: the knobs are turned past the end of travel, so the carriage is drawn at its stop.");

// knob angles in degrees for the position drawn, 0 at the centre
TH_A = -(PX + PY) / TURN * 360;
TH_B =  (PY - PX) / TURN * 360;

// ---------------- yarn loops -------------------------------------------
// yarn ends are tied through the corner holes of the fins: [x, y, z]
TIES = [
  [-TIE_X,  RP, ZA],   // A left:  back fin, left end, low
  [ TIE_X, -RP, ZA],   // A right: front fin, right end, low
  [-TIE_X, -RP, ZB],   // B left:  front fin, left end, high
  [ TIE_X,  RP, ZB],   // B right: back fin, right end, high
];
function tie(i, name) = [PX + TIES[i][0], PY + TIES[i][1], 0, 0, name];

// [x, y, radius, wrap (+1 = counter-clockwise from above, -1 = clockwise), name]
LOOP_A = [
  tie(0, "tie_al"),
  [-F,  PY, RP,  1, "jl_out"],
  [-F,  FY, RP,  1, "fl"],
  [ F,  FY, RP,  1, "fr"],
  [ KX, Y0, RM,  1, "knob_a"],
  [ JIN, PY, RP, -1, "jr_in"],
  tie(1, "tie_ar"),
];
LOOP_B = [
  tie(3, "tie_br"),
  [ F,  PY, RP, -1, "jr_out"],
  [ F,  FY, RP, -1, "fr"],
  [-F,  FY, RP, -1, "fl"],
  [-KX, Y0, RM, -1, "knob_b"],
  [-JIN, PY, RP,  1, "jl_in"],
  tie(2, "tie_bl"),
];

// ---------------- posts and pulleys ------------------------------------
// [x on the right side, top of its pulley stack, cross pin angle]
// The left side mirrors these, angles included.
POSTS_FRONT = [F, TOP_B, 45];
POST_SL_R = [[F, TOP_B, 90], [JIN, TOP_A, 45]];     // right slider: outer B, inner A
POST_SL_L = [[F, TOP_A, 90], [JIN, TOP_B, 90]];     // left slider (mirrored): outer A, inner B

// [name, x, y, bottom z]
PULLEYS = [
  ["pul_fr_a",    F,   FY, ZP_A], ["pul_fr_b",    F,   FY, ZP_B],
  ["pul_fl_a",   -F,   FY, ZP_A], ["pul_fl_b",   -F,   FY, ZP_B],
  ["pul_jr_out",  F,   PY, ZP_B], ["pul_jr_in",   JIN, PY, ZP_A],
  ["pul_jl_out", -F,   PY, ZP_A], ["pul_jl_in",  -JIN, PY, ZP_B],
];

// ---------------- filament pins ----------------------------------------
// [name, end 0, end 1, [melted head at end 0, at end 1]]
function xpin(name, x, y, top, ang) = let(c = cos(ang), s = sin(ang), z = xpin_z(top), h = XPIN_L/2)
  [name, [x - c*h, y - s*h, z], [x + c*h, y + s*h, z], [1, 1]];
function mxa(a) = 180 - a;
// knob lock pin: through the whole tower when low enough, else across the column
function kpin(name, s, kz) = let(z = kz + K_GROOVE_Z, y = Y0 + KPIN_OFF,
    half = sqrt(COL_R*COL_R - KPIN_OFF*KPIN_OFF),
    x0 = z < RT_TOP ? TW_X0 : KX - half, x1 = z < RT_TOP ? RT_XOUT : KX + half)
  [name, [s*(x0 - PIN_STICK), y, z], [s*(x1 + PIN_STICK), y, z], [1, 1]];

FILAMENT = [
  // rail pins, cut flush
  ["pin_rail_rf", [ TW_X0, RAIL_PINS[0], RPIN_Z], [ FT_XOUT, RAIL_PINS[0], RPIN_Z], [0, 0]],
  ["pin_rail_rr", [ TW_X0, RAIL_PINS[1], RPIN_Z], [ RT_XOUT, RAIL_PINS[1], RPIN_Z], [0, 0]],
  ["pin_rail_lf", [-TW_X0, RAIL_PINS[0], RPIN_Z], [-FT_XOUT, RAIL_PINS[0], RPIN_Z], [0, 0]],
  ["pin_rail_lr", [-TW_X0, RAIL_PINS[1], RPIN_Z], [-RT_XOUT, RAIL_PINS[1], RPIN_Z], [0, 0]],
  // beam pins, cut flush
  ["pin_beam_r", [ BPIN_X, PY - SL_HL, BPIN_Z], [ BPIN_X, PY + SL_HL, BPIN_Z], [0, 0]],
  ["pin_beam_l", [-BPIN_X, PY - SL_HL, BPIN_Z], [-BPIN_X, PY + SL_HL, BPIN_Z], [0, 0]],
  // pulley cross pins
  xpin("pin_x_fr",  F, FY, POSTS_FRONT[1], POSTS_FRONT[2]),
  xpin("pin_x_fl", -F, FY, POSTS_FRONT[1], mxa(POSTS_FRONT[2])),
  xpin("pin_x_jr_out",  POST_SL_R[0][0], PY, POST_SL_R[0][1], POST_SL_R[0][2]),
  xpin("pin_x_jr_in",   POST_SL_R[1][0], PY, POST_SL_R[1][1], POST_SL_R[1][2]),
  xpin("pin_x_jl_out", -POST_SL_L[0][0], PY, POST_SL_L[0][1], mxa(POST_SL_L[0][2])),
  xpin("pin_x_jl_in",  -POST_SL_L[1][0], PY, POST_SL_L[1][1], mxa(POST_SL_L[1][2])),
  // knob lock pins
  kpin("pin_k_a",  1, KA_Z),
  kpin("pin_k_b", -1, KB_Z),
];

// filament cut list: [length mm (rounded up), melted heads?] per pin, then counted
CUTS = [for (f = FILAMENT) [ceil(norm(f[2] - f[1]) - 0.01), max(f[3])]];
CUT_LIST = [for (L = [1:80], h = [0, 1]) let(n = len([for (c = CUTS) if (c == [L, h]) 1]))
            if (n > 0) str(n, " x ", L, " mm ", h ? "(melted ends)" : "(cut flush)")];
echo(str("Print: ", join([for (p = PRINT) str(p[1], " x ", p[0])])));
echo(str("Filament pins (1.75 mm): ", join(CUT_LIST)));
echo("PARTS", PRINT);   // build.py reads this line

// everything in the assembly, by name
COMPONENTS = concat(
  ["base", "rail_r", "rail_l", "slider_r", "slider_l", "beam", "carriage", "head"],
  [for (p = PULLEYS) p[0]],
  ["knob_a", "knob_b"],
  [for (f = FILAMENT) f[0]]
);

// =====================================================================
//  helpers
// =====================================================================
function starts(n, p) = len(n) >= len(p) && [for (i = [0:len(p)-1]) n[i]] == [for (i = [0:len(p)-1]) p[i]];
// the row of a table whose first entry is n
function row(table, n) = [for (r = table) if (r[0] == n) r][0];

// box with rounded vertical edges
module rbox(p, size, r = CORNER_R) {
  translate(p) hull() for (x = [r, size[0] - r], y = [r, size[1] - r])
    translate([x, y, 0]) cylinder(r = r, h = size[2], $fn = 32);
}

// sideways hole for a filament pin, centred on p; ang 0 runs along X, 90 along Y
module pin_bore(p, ang, length) {
  translate(p) rotate([0, 0, ang]) rotate([0, 90, 0])
    cylinder(d = pin_hole, h = length, center = true, $fn = 24);
}
module rail_pin_hole(py) pin_bore([XR, py, RPIN_Z], 0, 80);

// pulley post with a seat ring at its foot
module post(x, y, z0, seat_top, top) {
  translate([x, y, z0]) cylinder(d = POST_D, h = post_top(top) - z0);
  translate([x, y, z0]) cylinder(r = SEAT_R, h = seat_top - z0);
}
module post_hole(x, y, top, ang) pin_bore([x, y, xpin_z(top)], ang, POST_D + 2);

module seg_cyl(p, q, d) {
  v = q - p; L = norm(v);
  translate(p) rotate([0, acos(v[2] / L), atan2(v[1], v[0])]) cylinder(d = d, h = L, $fn = 16);
}

// =====================================================================
//  parts, modelled where they sit in the assembly with the knobs at 0
// =====================================================================

// open-top socket for a rail end, from y0 to y1 and up to z = top
module rail_socket(y0, y1, top) {
  translate([XR - RAIL_W/2 - FIT, y0, RAIL_Z]) cube([RAIL_W + 2*FIT, y1 - y0, top - RAIL_Z + 0.01]);
}

module front_tower() {           // right one; the left is mirrored
  difference() {
    union() {
      rbox([TW_X0, FY - 3.5, 0], [FT_XOUT - TW_X0, 3.5 + FT_IN, SL_TOP]);
      post(F, FY, SL_TOP - 0.01, SL_TOP + SEAT, POSTS_FRONT[1]);
    }
    rail_socket(RAIL_Y0 - RAIL_GAP, FY + FT_IN + 1, SL_TOP);
    post_hole(F, FY, POSTS_FRONT[1], POSTS_FRONT[2]);
    rail_pin_hole(RAIL_PINS[0]);
  }
}

module rear_tower(kz) {          // right one; kz = knob bottom height
  shaft_hole = SHAFT_D + 2*SPIN;
  difference() {
    union() {
      rbox([TW_X0, Y0 - RT_IN, 0], [RT_XOUT - TW_X0, RT_IN + 7, RT_TOP]);
      translate([KX, Y0, 0]) cylinder(r = COL_R, h = kz);
    }
    rail_socket(Y0 - RT_IN - 1, RAIL_Y1 + RAIL_GAP, RT_TOP);
    rail_pin_hole(RAIL_PINS[1]);
    // knob shaft hole with a small lead-in chamfer
    translate([KX, Y0, kz - SHAFT_L - 1]) cylinder(d = shaft_hole, h = 50);
    translate([KX, Y0, kz - 0.6]) cylinder(d1 = shaft_hole, d2 = shaft_hole + 1.4, h = 0.61);
    // knob lock pin hole
    pin_bore([KX, Y0 + KPIN_OFF, kz + K_GROOVE_Z], 0, 80);
  }
}

module base() {
  difference() {
    rbox([-BX, BY0, 0], [2*BX, BY1 - BY0, BASE_T]);
    rbox([-BX + RING, BY0 + RING, -1], [2*(BX - RING), BY1 - BY0 - 2*RING, BASE_T + 2]);
  }
  front_tower();               mirror([1,0,0]) front_tower();
  rear_tower(KA_Z);            mirror([1,0,0]) rear_tower(KB_Z);
}

module rail() {                  // right rail
  difference() {
    translate([XR - RAIL_W/2, RAIL_Y0, RAIL_Z]) cube([RAIL_W, RAIL_Y1 - RAIL_Y0, RAIL_H]);
    for (py = RAIL_PINS) rail_pin_hole(py);
    // chamfer the top edges
    for (s = [-1, 1]) translate([XR + s*RAIL_W/2, RAIL_Y0 - 1, RAIL_Z + RAIL_H])
      rotate([-90,0,0]) rotate([0,0,45]) cube([0.8, 0.8, 300]);
  }
}

// right gantry end; the left one is mirror([1,0,0]) slider(POST_SL_L)
module slider(posts) {
  difference() {
    union() {
      rbox([SL_XIN, -SL_HL, SL_Z0], [SL_XOUT - SL_XIN, 2*SL_HL, SL_TOP - SL_Z0]);
      for (p = posts) post(p[0], 0, SL_Z0, p[1] == TOP_B ? ZP_B : SL_TOP + SEAT, p[1]);
    }
    // rail tunnel
    translate([XR - RAIL_W/2 - SLIDE, -SL_HL - 1, RAIL_Z - SLIDE])
      cube([RAIL_W + 2*SLIDE, 2*SL_HL + 2, RAIL_H + 2*SLIDE]);
    // open-top beam socket
    translate([SL_XIN - 1, -BEAM_W/2 - FIT, BEAM_Z - FIT])
      cube([SOCK_END - SL_XIN + 1, BEAM_W + 2*FIT, SL_TOP - BEAM_Z + FIT + 0.01]);
    pin_bore([BPIN_X, 0, BPIN_Z], 90, 2*SL_HL + 2);
    for (p = posts) post_hole(p[0], 0, p[1], p[2]);
  }
}

module beam() {
  difference() {
    translate([-BEAM_HL, -BEAM_W/2, BEAM_Z]) cube([2*BEAM_HL, BEAM_W, BEAM_H]);
    for (x = [-BPIN_X, BPIN_X]) pin_bore([x, 0, BPIN_Z], 90, BEAM_W + 2);
  }
}

module carriage() {
  difference() {
    union() {
      translate([-CW_H, -CY_H, C_Z0]) cube([2*CW_H, 2*CY_H, S_TOP - C_Z0]);
      for (sy = [-1, 1]) translate([-CW_H, sy*RP - FIN_T/2, S_TOP - 0.01])
        cube([2*CW_H, FIN_T, C_TOP - S_TOP + 0.01]);
      // head slot: side walls and front lips, closed bottom
      difference() {
        translate([-CW_H, TS_YF, C_Z0]) cube([2*CW_H, TS_YB - TS_YF + 0.01, TS_TOP - C_Z0]);
        translate([-TS_W1/2, TS_YL, TS_Z0]) cube([TS_W1, TS_YB - TS_YL + 0.02, 50]);
        translate([-TS_W0/2, TS_YF - 1, TS_Z0]) cube([TS_W0, TS_YB - TS_YF + 1, 50]);
      }
    }
    // beam hole
    translate([-CW_H - 1, -BEAM_W/2 - SLIDE, BEAM_Z - SLIDE])
      cube([2*CW_H + 2, BEAM_W + 2*SLIDE, BEAM_H + 2*SLIDE]);
    // 3 x 3 holes in each fin; the corner ones are the tie holes
    for (sy = [-1, 1], x = [-TIE_X, 0, TIE_X], z = [ZA, (ZA + ZB)/2, ZB])
      translate([x, sy*RP, z]) rotate([90, 0, 0])
        cylinder(d = yarn_hole, h = FIN_T + 2, center = true, $fn = 24);
  }
}

// Heads: use head_tail() for the part that slides into the slot, and build
// your head inside on_head_mount(). Origin there is the bottom centre just in
// front of the slot, -Y points away from the carriage.
module head_tail() {
  translate([0, 0, TS_Z0]) {
    translate([-TS_W1/2 + FIT, TS_YL + FIT, 0]) cube([TS_W1 - 2*FIT, TS_FL, HEAD_H]);
    translate([-TS_W0/2 + FIT, TS_YF - HEAD_GAP - 0.01, 0])
      cube([TS_W0 - 2*FIT, TS_YL + FIT - (TS_YF - HEAD_GAP) + 0.02, HEAD_H]);
  }
}
module on_head_mount() translate([0, TS_YF - HEAD_GAP, TS_Z0]) children();

// example head: a plain plate
module head_blank() {
  head_tail();
  on_head_mount() translate([-CW_H, -HEAD_T, 0]) cube([2*CW_H, HEAD_T + 0.01, HEAD_H]);
}

module pulley() {                     // bottom at z = 0
  rotate_extrude() polygon([
    [P_BORE/2, 0], [P_RO, 0], [P_RO, P_FL], [P_RG, P_FL + P_FLANK],
    [P_RG, P_FL + P_FLANK + P_GW], [P_RO, P_H - P_FL], [P_RO, P_H],
    [HUB_R, P_H], [HUB_R, P_H + HUB], [P_BORE/2, P_H + HUB]
  ]);
}

module knob() {                       // drum bottom at z = 0, shaft below
  gz = K_GRIP_Z;
  difference() {
    union() {
      translate([0, 0, -SHAFT_L]) cylinder(d = SHAFT_D, h = SHAFT_L + 0.01);
      rotate_extrude() polygon([
        [0, 0], [K_RO, 0], [K_RO, K_FLB], [K_RG, K_FLB + K_FLANK],
        [K_RG, K_FLB + K_FLANK + K_GW], [K_RO, K_DRUM_H - K_FLT], [K_RO, K_DRUM_H],
        [K_GRIP_R, gz], [0, gz]
      ]);
      translate([0, 0, gz - 0.01]) cylinder(r = K_GRIP_R, h = K_GRIP_H + 0.01);
    }
    // shaft tip chamfer
    translate([0, 0, -SHAFT_L - 0.01]) difference() {
      cylinder(d = SHAFT_D + 1, h = 0.8);
      cylinder(d1 = SHAFT_D - 1.6, d2 = SHAFT_D + 0.01, h = 0.81);
    }
    // groove for the lock pin: the knob turns but can't lift out
    translate([0, 0, K_GROOVE_Z - (FIL + 0.6)/2]) difference() {
      cylinder(d = SHAFT_D + 1, h = FIL + 0.6);
      translate([0, 0, -0.01]) cylinder(r = K_GROOVE_R, h = FIL + 0.62);
    }
    // grip flutes and pointer notch
    for (a = [0 : 360/14 : 359]) rotate(a) translate([K_GRIP_R + 0.4, 0, gz + 1]) cylinder(r = 1.1, h = K_GRIP_H, $fn = 16);
    translate([K_GRIP_R - 1.5, -0.8, gz + 1]) cube([3, 1.6, K_GRIP_H]);
    // yarn hole through the drum
    translate([0, 0, K_ZS]) rotate([0, 90, 0]) cylinder(d = yarn_hole, h = 3*K_RO, center = true, $fn = 20);
  }
}

// =====================================================================
//  assembly
// =====================================================================
module component(n) {
  pul = row(PULLEYS, n);
  pin = row(FILAMENT, n);
  if (n == "base") base();
  else if (n == "rail_r") rail();
  else if (n == "rail_l") mirror([1,0,0]) rail();
  else if (n == "slider_r") translate([0, PY, 0]) slider(POST_SL_R);
  else if (n == "slider_l") translate([0, PY, 0]) mirror([1,0,0]) slider(POST_SL_L);
  else if (n == "beam") translate([0, PY, 0]) beam();
  else if (n == "carriage") translate([PX, PY, 0]) carriage();
  else if (n == "head") translate([PX, PY, 0]) head_blank();
  else if (n == "knob_a") translate([ KX, Y0, KA_Z]) rotate(TH_A) knob();
  else if (n == "knob_b") translate([-KX, Y0, KB_Z]) rotate(TH_B) knob();
  else if (pul) translate([pul[1], pul[2], pul[3]]) pulley();
  else if (pin) {
    seg_cyl(pin[1], pin[2], FIL);
    for (i = [0, 1]) if (pin[3][i] == 1) translate(pin[1 + i]) sphere(d = MUSH_D, $fn = 16);
  }
}

// yarn drawing: straight runs are tangent lines between pulleys
function rot90(v) = [-v[1], v[0]];
// direction of the yarn from circle 1 to circle 2 (signed radii)
function tdir(c1, r1, c2, r2) =
  let(D = c2 - c1, dl = r2 - r1, L = sqrt(D*D - dl*dl)) (L*D - dl*rot90(D)) / (D*D);

module string_seg(p, q, z) {
  hull() for (e = [p, q]) translate([e[0], e[1], z]) sphere(d = yarn_d, $fn = 8);
}

module string_loop(L, z) {
  n = len(L);
  segs = [for (i = [0 : n - 2]) let(
            c1 = [L[i][0], L[i][1]],     r1 = L[i][2]*L[i][3],
            c2 = [L[i+1][0], L[i+1][1]], r2 = L[i+1][2]*L[i+1][3],
            d = tdir(c1, r1, c2, r2), nl = rot90(d))
          [c1 - r1*nl, c2 - r2*nl]];
  for (s = segs) string_seg(s[0], s[1], z);
  // arcs around each pulley / drum
  for (i = [1 : n - 2]) let(
      c = [L[i][0], L[i][1]], r = L[i][2], w = L[i][3],
      pin = segs[i-1][1], pout = segs[i][0],
      a0 = atan2(pin[1] - c[1], pin[0] - c[0]),
      a1 = atan2(pout[1] - c[1], pout[0] - c[0]),
      sw = w > 0 ? (a1 - a0 + 720) % 360 : -((a0 - a1 + 720) % 360),
      k = max(2, ceil(abs(sw) / 15)))
    for (j = [0 : k - 1]) let(t0 = a0 + sw*j/k, t1 = a0 + sw*(j+1)/k)
      string_seg(c + r*[cos(t0), sin(t0)], c + r*[cos(t1), sin(t1)], z);
}

// [start of a component name, colour, shown?]
LOOKS = [["base",     "SlateGray",      show_base],
         ["rail_",    "LightSteelBlue", show_rails],
         ["slider_",  "SteelBlue",      show_sliders],
         ["beam",     "LightSteelBlue", show_beam],
         ["carriage", "Orange",         show_carriage],
         ["head",     "MediumSeaGreen", show_head],
         ["pul_f",    "WhiteSmoke",     show_front_pulleys],
         ["pul_j",    "WhiteSmoke",     show_gantry_pulleys],
         ["knob_",    "Tomato",         show_knobs],
         ["pin_",     "Black",          show_pins]];
function look(n) = [for (l = LOOKS) if (starts(n, l[0])) l][0];

// R / L letter on top of a knob grip, turning with it (assembly view only, never printed)
module knob_label(t, x, z, a)
  translate([x, Y0, z + K_GRIP_Z + K_GRIP_H]) rotate(a)
    linear_extrude(0.4) text(t, size = 7, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");

module assembly() {
  for (n = COMPONENTS) let(l = look(n)) if (l[2]) color(l[1]) component(n);
  if (show_loop_A) color("Crimson")    string_loop(LOOP_A, ZA);
  if (show_loop_B) color("DodgerBlue") string_loop(LOOP_B, ZB);
  if (show_knobs) color("White") {
    knob_label("R",  KX, KA_Z, TH_A);
    knob_label("L", -KX, KB_Z, TH_B);
  }
}

// =====================================================================
//  single parts, flat on the bed in print orientation
// =====================================================================
module print_part(n) {
  if (n == "base") base();
  else if (n == "rail") translate([0, 0, -RAIL_Z]) rail();
  else if (n == "slider_r") translate([0, 0, -SL_Z0]) slider(POST_SL_R);
  else if (n == "slider_l") translate([0, 0, -SL_Z0]) mirror([1,0,0]) slider(POST_SL_L);
  else if (n == "beam") translate([0, 0, -BEAM_Z]) beam();
  else if (n == "carriage") translate([0, 0, -C_Z0]) carriage();
  else if (n == "head_blank") translate([0, -TS_YF, -TS_Z0]) head_blank();
  else if (n == "pulley") pulley();
  else if (n == "knob") translate([0, 0, K_GRIP_Z + K_GRIP_H]) rotate([180, 0, 0]) knob();
}

if (part == "assembly") assembly();
else print_part(part);
