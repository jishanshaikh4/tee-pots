#version 300 es

precision highp float;

// -- LENS FLARE --
// Draws a warm-orange flare of concentric circles centered on
// uCenter, and three light lines. Everything falling outside lit area
// will be dimmed.
// NOTE: this shader produces color values with  pre-multiplied alpha.
// Use glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA).

// time - for randomness
uniform float uTime;
// a value from 0 (fully transparent) to 1 (max)
uniform float uIntensity;

// [screen width, screen hight]
uniform vec2 uResolution;
// flare center
uniform vec2 uCenter;

out vec4 oColor;

float random(in vec2 st) {
    return
        fract(sin(dot(st, vec2(12.9898,78.233)))
              * 43758.5453123);
}

float interpolate(in float sw, in float nw, in float se, in float ne, in vec2 p) {
    float l = mix(sw, nw, p.y);
    float r = mix(se, ne, p.y);
    return mix(l, r, p.x);
}

float noise(in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    vec2 u = smoothstep(0.0, 1.0, f);

    float sw = random(i + vec2(0.0, 0.0));
    float nw = random(i + vec2(0.0, 1.0));
    float se = random(i + vec2(1.0, 0.0));
    float ne = random(i + vec2(1.0, 1.0));

    return interpolate(sw, nw, se, ne, u);
}

float bumpStep(in float mid, in float thicknessH, in float x) {
  return
    smoothstep(mid - thicknessH, mid,              x) -
    smoothstep(mid,              mid + thicknessH, x);
}

float decline(in float x, in float factor) {
  return max(0.0, 1.0 - pow(clamp(x, 0.0, 1.0), factor));
}

// computes shortest distance from st to line defined by p1 and p2.
float lineDist(vec2 p1, vec2 p2, vec2 st) {
  vec2 dp = p2 - p1;
  float num = abs(dp.y * st.x -
                  dp.x * st.y +
                  p2.x * p1.y -
                  p2.y * p1.x);
  float den = length(dp);
  return num / den;
}

// circle alpha mappers

float smoothAlpha(vec2 center, float radius, vec2 st) {
  float d = distance(st, center);
  return 1.0 - smoothstep(0.0, radius, d);
}

float sphereAlpha(vec2 center, float radius, vec2 st, float factor) {
  float d = distance(st, center);
  return decline(d / radius, factor);
}

float min3(float a, float b, float c) {
  return min(a, min(b, c));
}

// blenc src with dest - produces pre-multiplied alpha
vec4 blend(vec3 srcCol, float srcAlpha, vec4 dest) {
  float invSrcAlpha = 1.0 - srcAlpha;
  return vec4(srcCol* srcAlpha + dest.rgb * invSrcAlpha,
              srcAlpha + dest.a * invSrcAlpha);
}

void main() {
  const vec3 cCenterColor       = vec3(1.0);
  const vec3 cLightColor        = vec3(0.92, 0.68, 0.50);
  const vec3 cDimColor          = vec3(0.0,  0.0,  0.0);

  // radius of light area, as a factor of width
  const float cRadius = 0.19;
  // factor for linear darkening outside light area - a percentage of
  // smallest screen side
  const float cGradualFadeFactor = 1.18;

  // intensities - used for fading in and out
  float dimIntensity   = smoothstep(0.0, 0.5, uIntensity);
  float lightIntensity = smoothstep(0.5, 1.0, uIntensity);

  // units
  float base = min(uResolution.x, uResolution.y);
  float fragSize = 1.0 / base;
  vec2 st = gl_FragCoord.xy / base;
  float relW = uResolution.x / base;
  float relH = uResolution.y / base;

  float radius = cRadius * relW * lightIntensity;

  // fluctuations
  const float cBrightnessFluctPeriod = 0.67;
  const float cPointRefFluctPeriod   = 2.0;
  // a value in [-1; +1] - positive values make screen brighter,
  // negative values make screen darker
  float brightnessFluct =
    noise(vec2(4.7 + uTime * cBrightnessFluctPeriod, 12.4)) * 2.0 - 1.0;
  // a value in [-1; +1] - used to offset one axis of line reference points
  float pointRefFluct =
    noise(vec2(3.1 + uTime * cPointRefFluctPeriod,    9.3)) * 2.0 - 1.0;

  // line reference points
  const float lineHorizontalEdgeDist = 0.1;
  float lineHorizontalY = uCenter.y - relH / 15.0;
  // point at horizontal middle, almost-top of screen
  vec2 cLineRef1 = vec2(0.5 * relW, relH - 0.2);
  // point to left of screen, slightly below center
  vec2 cLineRef2 = vec2(relW * (0.0 - lineHorizontalEdgeDist), lineHorizontalY);
  // point to right of screen, slightly below center
  vec2 cLineRef3 = vec2(relW * (1.0 + lineHorizontalEdgeDist), lineHorizontalY);

  cLineRef1.x += pointRefFluct * 0.11;
  cLineRef2.y += pointRefFluct * 0.09;
  cLineRef3.y += pointRefFluct * 0.09;

  float centerDist = distance(st, uCenter);

  // smooth-step for edge fade-off
  float outerFadeRadius = radius + 0.0625 * relW;
  float edgeFade = smoothstep(radius, outerFadeRadius, centerDist);

  // lines
  float lineThicknessH = 1.4 * fragSize;
  float minLineDist = min3(lineDist(uCenter, cLineRef1, st),
                            lineDist(uCenter, cLineRef2, st),
                            lineDist(uCenter, cLineRef3, st));
  float minLineProximity = bumpStep(0.0, lineThicknessH, minLineDist);
  float lineFade = (1.0 - edgeFade) * minLineProximity;
  float lineAlpha = 0.03 * minLineProximity * lineFade;

  // a bright white point in the center
  float centerRadius = radius * 0.2;
  float centerStep = 1.0 - step(centerRadius, centerDist);
  float centerAlpha = 0.62 *
    smoothAlpha(uCenter, centerRadius, st);

  // accumulate alpha for all contributions to cLightColor
  float insideAlpha = 0.0;
  insideAlpha += 0.22 *
    sphereAlpha(uCenter,
                radius,
                st,
                1.3);
  insideAlpha += 0.12 *
    smoothAlpha(uCenter,
                radius * 0.8,
                st);
  insideAlpha += 0.15 *
    smoothAlpha(uCenter,
                radius * 0.3,
                st);

  // everything outside light area is dimmed
  float dimAlpha =
    min(0.8,
        max(
            // edge fade-off
            0.4 * edgeFade,
            // gradual fade-off
            centerDist / cGradualFadeFactor));

  // apply fluctuations
  centerAlpha *= (1.0 + brightnessFluct * 0.12);
  insideAlpha *= (1.0 + brightnessFluct * 0.25);
  dimAlpha    *= (1.0 - brightnessFluct * 0.08);
  lineAlpha   *= (1.0 + brightnessFluct * 1.00);

  // apply fade
  dimAlpha    *= dimIntensity;
  centerAlpha *= lightIntensity;
  insideAlpha *= lightIntensity;
  lineAlpha   *= lightIntensity;

  vec4 col = vec4(cDimColor, dimAlpha);
  col = blend(cLightColor,  insideAlpha, col);
  col = blend(cCenterColor, centerAlpha, col);
  col = blend(cCenterColor, lineAlpha,   col);

  oColor = col;
}
