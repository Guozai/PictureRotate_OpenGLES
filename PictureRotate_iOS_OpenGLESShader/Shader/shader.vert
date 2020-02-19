attribute vec4 position;
attribute vec2 texCoordinates;
uniform mat4 rotateMatrix;

varying lowp vec2 varyTexCoord;

void main()
{
    varyTexCoord = texCoordinates;
    
    vec4 vPos = position;

    vPos = vPos * rotateMatrix;

    gl_Position = vPos;
}
