#version 300 es

uniform mat4 uProjMat;
uniform vec2 uOrientation;

in vec2 aVertexPosition;
in vec2 aPosition;
in vec2 aVelocity;
in float aSize;
in float aDepth;
in vec2 aPointCoord;
in float aSeed;

out float vSize;
out float vDepth;
out vec2 vPosition;
out vec2 vPointCoord;
out float vSeed;

void main(void) {
    vec2 vertexPosition = aVertexPosition * (1.0 - aDepth);

    gl_Position = uProjMat * vec4(vertexPosition + aPosition + uOrientation * aDepth, 0.5, 1.0);

    vSize = aSize;
    vDepth = aDepth;
    vPosition = aPosition;
    vPointCoord = aPointCoord;
    vSeed = aSeed;
}
