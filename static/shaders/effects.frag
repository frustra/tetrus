precision mediump float;

uniform sampler2D u_buffer;
uniform vec2 u_size;

void main(void) {
  gl_FragColor = texture2D(u_buffer, gl_FragCoord.xy / u_size);
}
