#version 300 es

precision mediump float;

uniform sampler2D uTexture;

in float vSize;
in float vDepth;
in vec2 vPosition;
in vec2 vPointCoord;
in float vSeed;

out vec4 oColor;

const float GRID_SIZE = 2.0;

void main(void) {
    float gridStep = 1.0 / GRID_SIZE;
    float i = vSeed * GRID_SIZE * GRID_SIZE;
    float texX = floor(mod(i, GRID_SIZE)) / GRID_SIZE;
    float texY = floor(i / GRID_SIZE) / GRID_SIZE;
    vec4 texColor = texture(uTexture, vec2(texX, texY) + vPointCoord / GRID_SIZE);

    oColor = vec4(texColor.rgb, sqrt(1.0 - vDepth) * texColor.a);
}
