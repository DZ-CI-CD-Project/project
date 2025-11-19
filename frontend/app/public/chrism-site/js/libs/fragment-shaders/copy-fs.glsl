uniform sampler2D tInput;
uniform vec2 resolution;

varying vec2 vUv;

void main() {
	gl_FragColor = texture2D(tInput, vUv);
}

