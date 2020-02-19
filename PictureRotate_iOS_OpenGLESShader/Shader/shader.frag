varying lowp vec2 varyTexCoord;

uniform sampler2D colorMap;

void main()
{
    gl_FragColor = texture2D(colorMap, varyTexCoord);
}
