precision mediump float;

uniform sampler2D u_board;
uniform vec2 u_boardsize;
uniform float u_blocksize;

void main(void) {
  vec2 block = floor(gl_FragCoord.xy / u_blocksize);

  if (block.x < u_boardsize.x && block.y < u_boardsize.y) {
    vec2 pixel = mod(gl_FragCoord.xy, u_blocksize);
    vec4 color = texture2D(u_board, (block + vec2(0.5)) / u_boardsize);

    float shade = 0.0;
    float shade2 = 1.0;
    if (pixel.x > pixel.y) {
      if (max(pixel.x, u_blocksize - pixel.y) > u_blocksize - (u_blocksize / 8.0)) {
        shade2 = 0.8;
      } else {
        shade = 0.03;
        shade2 = 0.9;
      }
    } else {
      if (min(pixel.x, u_blocksize - pixel.y) < u_blocksize / 8.0) {
        shade = 0.15;
        shade2 = 1.05;
      } else {
        shade = 0.05;
        shade2 = 0.95;
      }
    }

    gl_FragColor = color * vec4(vec3(shade2), 1.0) + vec4(vec3(shade), 0.0);
  } else {
    gl_FragColor = vec4(vec3(0.0), 1.0);
  }
}
