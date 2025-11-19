uniform sampler2D tInput;
uniform vec2 resolution;
uniform float amount;

varying vec2 vUv;

void main() {
	vec2 d = 1.0 / resolution;
	vec2 coord = vUv;
	coord = floor(coord * amount) / amount;
	coord += d * 0.5;
	gl_FragColor = texture2D(tInput, coord);
}

