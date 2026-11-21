#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float aspect;
    vec4 drop0;
    vec4 drop1;
    vec4 drop2;
    vec4 drop3;
    vec4 drop4;
    vec4 drop5;
    vec4 drop6;
    vec4 drop7;
} ubuf;

layout(binding = 1) uniform sampler2D source;

void applyDrop(vec2 uv, vec4 drop, inout vec2 offset, inout float caustic) {
    if (drop.z < 0.0) return;
    float age = ubuf.time - drop.z;
    if (age < 0.0 || age > 1.85) return;

    vec2 diff = uv - drop.xy;
    diff.x *= ubuf.aspect;
    float dist = length(diff);
    vec2 dir = dist > 0.0001 ? (diff / dist) : vec2(0.0);

    // Gelombang air menyebar mulus dari titik sentuh / titik huruf
    float radius = age * 0.44;
    float d1 = dist - radius;
    float env1 = exp(-abs(d1) * 34.0) * exp(-age * 2.35) * drop.w;

    float d2 = dist - (radius - 0.036);
    float env2 = exp(-abs(d2) * 42.0) * exp(-age * 2.85) * drop.w * 0.48;

    float waveSlope = cos(d1 * 110.0) * env1 + cos(d2 * 124.0) * env2;
    offset += dir * waveSlope * 0.021;
    caustic += (sin(d1 * 110.0) * env1 * 0.65 + sin(d2 * 124.0) * env2 * 0.35);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 totalOffset = vec2(0.0);
    float totalCaustic = 0.0;

    applyDrop(uv, ubuf.drop0, totalOffset, totalCaustic);
    applyDrop(uv, ubuf.drop1, totalOffset, totalCaustic);
    applyDrop(uv, ubuf.drop2, totalOffset, totalCaustic);
    applyDrop(uv, ubuf.drop3, totalOffset, totalCaustic);
    applyDrop(uv, ubuf.drop4, totalOffset, totalCaustic);
    applyDrop(uv, ubuf.drop5, totalOffset, totalCaustic);
    applyDrop(uv, ubuf.drop6, totalOffset, totalCaustic);
    applyDrop(uv, ubuf.drop7, totalOffset, totalCaustic);

    vec2 refractedUv = clamp(uv - totalOffset, vec2(0.001), vec2(0.999));
    vec3 color = texture(source, refractedUv).rgb;

    // Kilau refraksi permukaan air alami (specular water crest)
    float crest = max(0.0, totalCaustic);
    color += vec3(0.78, 0.92, 1.0) * pow(crest, 1.5) * 0.24;
    color -= vec3(0.04, 0.06, 0.09) * max(0.0, -totalCaustic) * 0.16;

    fragColor = vec4(color, 1.0) * ubuf.qt_Opacity;
}
