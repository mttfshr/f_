```glsl
/////////////////////////////////////////////////////////////////////
//
// Apollonian Gasket: iterated inversion in a set of tangent circles
//
// Originally derived from https://www.shadertoy.com/view/4dsBDn
// by ebanflo but changed fairly substantially.
//
// Mouse drags central circle around.
// 'd' inverts in unit disk
// 'h' maps to half plane
// 'j' applies Joukovsky transform
//
/////////////////////////////////////////////////////////////////////
// N = 3 gives 4 mutually tangent circles.
const float N = 3.0;
const int max_iterations = 100;
const float pi = 3.14159265;
// Circles are represented as vec3(x,y,r2) where
// (x,y) is the centre and r2 is the squared radius.
// Invert pos in circle c
vec2 invert(vec2 pos, vec3 c) {
  vec2 p = pos-c.xy;
  float p2 = dot(p,p);
  return p*c.z/p2 + c.xy;
}

// Invert pos in circle if it is inside
bool checkinverse(inout vec2 pos, vec3 c) {
  vec2 p = pos-c.xy;
  float p2 = dot(p,p);
  if (p2 > c.z) return false;
  pos = p*c.z/p2 + c.xy;
  return true;
}
// N circles in a ring, with tangency points on unit circle,
// plus a central circle, tangent to the others.
vec3 gasket(vec2 pos){
  float theta = pi/N;
  float r = 1.0/cos(theta);
  float s = tan(theta);
  for(int n = 0; n < max_iterations; n++){
    vec3 c = vec3(0,0,pow(r-s,2.0));
    // Try inverting in central circle
    if (!checkinverse(pos,c)) {
      bool found = false;
      // else try in the circles of the ring.
      for (float i = 0.0; i < N; i++) {
        float t = 0.2*iTime;
        vec3 c = vec3(r*sin(2.0*i*theta+t), r*cos(2.0*i*theta+t), s*s);
        if (checkinverse(pos,c)) {
          found = true;
          break;
        }
      }
      if (!found) return vec3(pos,n);
    }
  }
  return vec3(pos,max_iterations);
}
```

**Key facts this exposed** (see `plan.md` ADR-7 for the full diagnosis):

- Circles stored as `vec3(x, y, r2)` — `r2` is the squared radius already,
  matching this project's `ringR2`/`c.z` convention (no change needed there)
- **Ring circles**: centered at distance `r = 1/cos(theta)` from origin,
  radius `s = tan(theta)`, `theta = pi/N`
- **Central circle**: centered at the ORIGIN, radius `r - s` (NOT the ring
  radius, NOT a giant bounding circle) — squared radius `(r-s)^2`
- **No enclosing/outer circle exists anywhere in this algorithm.** Each
  iteration checks the central circle first, then each ring circle in
  order; the moment a point isn't inside ANY of them, the loop `break`s
  immediately — a genuine per-pixel variable-length escape-time test,
  not a fixed fold
- This project's ring+central-circle construction (T111–T119) had
  invented a large "enclosing" circle that inverts everything outside it
  back inward, every iteration, indefinitely — this circle and this
  behavior do not exist anywhere in the actual reference

## Complex Möbius-matrix Kleinian-group variant — reviewed, not the translation target

A second, more general shader (Möbius transformations represented as
2x2 complex matrices, arbitrary N generating circles via
`getInversionCircle(i)`/`getLimitCircle(i)`, supports mouse-driven
extra inversion and continuous rotation). More mathematically general
than the direct-inversion approach above (models the full Kleinian
group action via matrix composition rather than directly tracking a
transformed point), but not adopted as the translation target here —
the direct-inversion approach above is simpler and sufficient for this
project's scope (equal-radius ring + central circle only, per Matt's
explicit "count only" scope decision, `spec.md` User Story 2.5).
Retained here for future reference if the project ever needs true
per-mouse/live-rotation Möbius composition (e.g. if `f_poincare` work
picks this up later).

## Per-circle texture sampling references (2026-07-08, for production item #3 — not yet implemented)

Two more references Matt supplied, specifically relevant to
`spec.md`'s production item #3 (per-region texture sampling) — the
next build item after ring-count generalization (item #1, this
session) and the live max-iteration param (item #2), per the build
order in spec.md's "What 'production' means" section.

- **`https://www.shadertoy.com/view/dtGGRz`** — Matt: "does 'exactly'
  what we want in that each circle has a texture (a movie in this
  case) playing in it." This is the concrete target behavior for item
  #3 — full source not yet pulled into this doc, fetch and diff when
  item #3 is actually picked up.
- **`https://www.shadertoy.com/view/Xclfzj`** — shows the UV
  calculation for the limit circles specifically. The `Apollonian
  Britney` shader above (view/dtGGRz's likely sibling/precursor,
  `mla` 2023, modification of `fizzer`'s `WtdSDf`) already contains a
  worked example of this: `cMobiusOnCircle(mi, C)` maps a limit circle
  `C` through the accumulated inverse transformation `mi` to get its
  position/radius `D` in the ORIGINAL (unfolded) coordinate frame, then
  `uv = 0.5 * (p.xy - D.xy) / D.z` gives a local, scale-normalized UV
  inside that specific circle — exactly the "per-circle local-frame"
  mechanism `ideas/f_apollonian.md` already identified as the missing
  piece for per-region texture sampling, now with a concrete worked
  formula rather than just the concept. Key structural difference from
  this project's current per-pixel-forward-fold approach: this
  reference tracks the ACCUMULATED TRANSFORMATION MATRIX `mi` (Möbius
  composition) throughout the loop, not just the final folded point —
  it needs the full transform (or its inverse) to map a fixed limit
  circle definition back into per-pixel local UV space. This project's
  GenExpr codebox doesn't have a matrix type; achieving the same effect
  will need either (a) tracking the same information via composed
  scalar inversions (extending the `s`-scale-accumulator pattern already
  used for line-drawing, generalized to also track enough info to
  invert the accumulated transform), or (b) a different formulation
  entirely. Not designed yet — worth a dedicated ADR when item #3 starts.

### Full source — "Apollonian Britney" (mla, 2023, modification of fizzer's WtdSDf)

```glsl
// Apollonian Britney, mla, 2023
//
// Modification of @fizzer's original https://www.shadertoy.com/view/WtdSDf
// See mainImage around line 210 for limit circle uv calculation.

const float pi = acos(-1.);
const int numCircles = 4; // Set this to 4, for the classic gasket.

const mat4x2 midentity = mat4x2(vec2(1, 0), vec2(0, 0), vec2(0, 0), vec2(1, 0));

vec2 cMobius(mat4x2 m, vec2 x) {
    return cDiv(cMul(x, m[0]) + m[1], cMul(x, m[2]) + m[3]);
}

mat4x2 cMobiusConcat(mat4x2 ma, mat4x2 mb) {
    return mat4x2(cMul(ma[0], mb[0]) + cMul(ma[1], mb[2]),
                  cMul(ma[0], mb[1]) + cMul(ma[1], mb[3]),
                  cMul(ma[2], mb[0]) + cMul(ma[3], mb[2]),
                  cMul(ma[2], mb[1]) + cMul(ma[3], mb[3]));
}

mat4x2 cMobiusInverse(mat4x2 m) {
    return mat4x2(m[3], -m[1], -m[2], m[0]);
}

// Apply transformation T to circle C — this is the key per-circle mapping
vec3 cMobiusOnCircle(mat4x2 T, vec3 C) {
    vec3 D;
    vec2 z = C.xy;
    if (T[2] != vec2(0)) z -= cDiv(vec2(C.z * C.z, 0), cConj(cDiv(T[3], T[2]) + C.xy));
    D.xy = cMobius(T,z).xy;
    D.z = length(D.xy - cMobius(T,C.xy + vec2(C.z, 0)));
    return D;
}

vec3 getInversionCircle(int i) {
    float theta = pi / float(numCircles - 1);
    float r0 = tan(theta);
    float r1 = 1. / cos(theta);
    if(i == numCircles - 1) return vec3(0, 0, r1 - r0); // Central circle
    return vec3(cos(float(i) * theta * 2.) * r1, sin(float(i) * theta * 2.) * r1, r0);
}

vec3 getLimitCircle(int i) {
    float theta = pi / float(numCircles - 1);
    float r0 = tan(theta);
    float r1 = 1. / cos(theta);
    float r = (r1 - r0) * tan(theta);
    float r2 = (r1 - r0) / cos(theta);
    if(i == numCircles - 1) return vec3(0, 0, 1);
    return vec3(-cos((float(i)) * theta * 2.) * r2, sin((float(i)) * theta * 2.) * r2, r);
}

mat4x2 makeMobiusForInversionInCircle(vec3 ic) {
    mat4x2 ma = mat4x2(vec2(1. / ic.z, 0), vec2(-ic.x / ic.z, ic.y / ic.z), vec2(0, 0), vec2(1, 0));
    mat4x2 mb = mat4x2(vec2(ic.x, ic.y), vec2(ic.z, 0), vec2(1, 0), vec2(0, 0));
    return cMobiusConcat(mb, ma);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    vec2 p = -1.0 + 2.0 * fragCoord.xy / iResolution.xy;
    p.x *= iResolution.x / iResolution.y;
    vec2 z = vec2(p.x, p.y);
    mat4x2 mi = midentity;

    for(int i = 0; i < 1000; ++i) {
        int k = -1;
        mat4x2 m;
        vec3 ic;
        for(int j = 0; j < numCircles; ++j) {
            vec3 c = getInversionCircle(j);
            if(distance(z.xy, c.xy * vec2(1, -1)) < c.z) {
                k = j;
                ic = c;
                break;
            }
        }
        if(k == -1) break;
        ic.x += 1e-9;
        m = makeMobiusForInversionInCircle(ic);
        mi = cMobiusConcat(m,mi);
        z = cMobius( m, z );
    }

    mi = cMobiusInverse(mi); // Get inverse transformation

    vec3 col = vec3(0);
    for(int i = 0; i < numCircles; ++i) {
        vec3 C = getLimitCircle(i);
        vec3 D = cMobiusOnCircle(mi, C);
        if(D.z > 1e-9 && D.z < 1. && abs(D.z - 1.) > .01) {
            vec2 v = p.xy - D.xy;
            if(length(v) < D.z) {
               vec2 uv = 0.5*v/D.z;  // <-- the per-circle local UV
               col = texture(iChannel0,uv+0.5).rgb;
               break;
            }
        }
    }
    col = pow(col, vec3(1. / 2.2));
    fragColor = vec4(col,1);
}
```

Note this shader accumulates the composed transformation matrix `mi`
throughout the settle loop, then inverts it ONCE at the end and applies
it to each of the N fixed "limit circles" (the base circles' images) to
find where they actually ended up in screen space for THIS pixel's
settle path — the reverse of this project's current approach (which
folds the pixel's position forward through the circles, never tracking
the accumulated transform itself). Bridging this to GenExpr (no matrix
type, no `break`) is the real design problem for item #3, not yet solved.


