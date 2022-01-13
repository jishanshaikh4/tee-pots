#version 300 es

uniform mat4 uProjMat;
uniform vec2 uOffset;

in vec2 aPosition;
in float aOffset;

void main(void) {
    gl_Position = uProjMat * vec4(aPosition.x + uOffset.x, aPosition.y + uOffset.y + aOffset, 0.0, 1.0);
}
