#version 300 es

precision highp float;

uniform sampler2D uGradient;

in vec2 vSt;
in vec2 vSeed;

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

void main() {
  // Controls wobbliness
  const float cNoiseScale = 4.0;

  float intensity = noise(vSeed + vec2(vSt.t, 0.0) * cNoiseScale);

  intensity = smoothstep(0.0, 1.0, intensity);

  // distance to nearest edge, in [0; 1]
  float edgeDist = 2.0 * abs(vSt.s - 0.5);

  float thickness = 0.3 + 0.6 * intensity;  // in [0.1; 0.9]
  float leftEdge = 1.0 - thickness;
  float rightEdge = leftEdge + 0.1;

  float alpha = 0.7 * smoothstep(leftEdge, rightEdge, 1.0 - edgeDist);

  vec2 st = vec2(intensity,
                 0.0);
  vec4 col = texture(uGradient, st);
  oColor = vec4(col.rgb, alpha);
}
