uniform sampler2D tInput;
uniform vec2 resolution;
uniform vec2 delta;

varying vec2 vUv;

void main() {
	vec4 color = vec4(0.0);
	color += texture2D(tInput, vUv + vec2(-delta.x, -delta.y));
	color += texture2D(tInput, vUv + vec2(0.0, -delta.y));
	color += texture2D(tInput, vUv + vec2(delta.x, -delta.y));
	color += texture2D(tInput, vUv + vec2(-delta.x, 0.0));
	color += texture2D(tInput, vUv);
	color += texture2D(tInput, vUv + vec2(delta.x, 0.0));
	color += texture2D(tInput, vUv + vec2(-delta.x, delta.y));
	color += texture2D(tInput, vUv + vec2(0.0, delta.y));
	color += texture2D(tInput, vUv + vec2(delta.x, delta.y));
	color /= 9.0;
	gl_FragColor = color;
}

