#version 300 es

uniform mat4 uProjMat;
uniform vec2 uScale;
uniform vec2 uOffset;
uniform float uTime;
uniform float uDuration;

// vertex position
in vec2 aPosition;
// time offset for iteration
in float aTimeOffset;
// a per-spark constant seed value
in vec2 aSeed;

out vec2 vSt;
out vec2 vSeed;

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

mat2 rot(float a) {
  return mat2(cos(a), -sin(a),
              sin(a),  cos(a));
}

float decCurve(in float v, in float factor) {
  return 1.0 - pow(1.0 - v, 2.0 * factor);
}

void main() {
  const  float cTwoPi = 6.283;

  const float cGlobalOffsetScale = 0.09;
  const float cGlobalOffsetFreq = 3.0;

  const float cFlingProbability = 0.02;
  const float cFlingDistance = 1.7;

  const float cStrandAngleRange = cTwoPi / 4.0;

  vec2 globalOffset =
    cGlobalOffsetScale *
    vec2(2.0 * noise(uTime * cGlobalOffsetFreq * vec2(1.0, 0.0)) - 1.0,
         2.0 * noise(uTime * cGlobalOffsetFreq * vec2(0.0, 1.0)) - 1.0);

  // These vectors are added to per-iteration seed and used for randomness.
  // The values are not important, but they should all be different.
  const vec2 cFlingProbabilityVec = vec2(-1.7, 9.5);
  const vec2 cSparkLengthVec      = vec2(-3.1, 7.2);
  const vec2 cStrandLengthVec     = vec2(11.1, 4.0);
  const vec2 cStrandAngleVec      = vec2(-3.7, 2.3);
  const vec2 cStrandOffsetVec     = vec2(12.3, 1.2);

  float k = (aTimeOffset + uTime) / uDuration;
  // progress moves in [0; 1] for one iteration
  float progress = fract(k);
  // base monotonically increases for each iteration.
  // mod is used to avoid overflow, meaning base repeats from 1 to 100.
  int base = int(mod(floor(k), 100.0)) + 1;

  // per-iteration seed
  vec2 seed = float(base) * 1.1 * aSeed;

  float sparkAngle = random(seed) * cTwoPi;
  float sparkLength = 0.7 + 0.3 * random(seed + cSparkLengthVec);

  bool isStrand = gl_VertexID >= 4;
  // Index of strand, when applicable - for randomness
  float strandIndex = isStrand
    ? floor(float(gl_VertexID - 4) / 4.0)
    : 0.0;

  float strandLength = isStrand
    ? 0.7 + 0.3 * random(seed + strandIndex * cStrandLengthVec)
    : 1.0;
  float strandAngle = isStrand
    ? cStrandAngleRange * (random(seed + strandIndex * cStrandAngleVec) - 0.5)
    : 0.0;
  float strandOffset = isStrand
    ? sparkLength * (0.9 - 0.2 * random(seed + cStrandOffsetVec))
    : 0.0;

  // Fling constants
  bool isFling = random(seed + cFlingProbabilityVec) < cFlingProbability;
  float flingAngle = isFling ? progress * cTwoPi / 8.0 : 0.0;
  flingAngle = flingAngle * -sign(sparkAngle - cTwoPi / 2.0);
  float flingCurveAngle = flingAngle / 8.0;
  vec2 flingOffset = vec2(0.0,
                          isFling
                            ? cFlingDistance * decCurve(progress, 1.0)
                            : 0.0);

  vec2 pos = aPosition;

  // Apply strand transforms
  pos = pos * vec2(1.0, strandLength);
  pos = rot(strandAngle) * pos;
  pos += vec2(0.0, strandOffset);

  // Apply spark transforms
  pos = pos * vec2(1.0, sparkLength);
  pos = pos * vec2(1.0, decCurve(progress, 1.5));
  pos = rot(flingAngle) * pos;
  pos = pos + flingOffset;
  pos = rot(sparkAngle + flingCurveAngle) * pos;

  // Apply global offset
  pos += globalOffset;

  // Apply scale
  pos = pos * uScale;

  gl_Position = uProjMat * vec4(pos + uOffset, 0.0, 1.0);

  // TODO maybe pass this with vertex data instead of computing?
  vSt = vec2(aPosition.x <= 0.0 ? 0.0 : 1.0,
             aPosition.y <= 0.0 ? 0.0 : 1.0);

  vSeed = seed;
}
