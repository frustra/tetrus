precision mediump float;

uniform sampler2D u_piece;
uniform vec2 u_piecepos;
uniform vec2 u_piecesize;
uniform vec2 u_boardsize;
uniform float u_blocksize;
uniform float u_xoffset;

uniform sampler2D u_buffer;
uniform vec2 u_size;

void main(void) {
  gl_FragColor = texture2D(u_buffer, gl_FragCoord.xy / u_size);
  if (u_size.x == 0.0 && u_size.y == 0.0) gl_FragColor = vec4(0.0);

  vec2 offset = vec2(u_piecepos.x, u_boardsize.y - u_piecepos.y - u_piecesize.y);
  vec2 block = floor(vec2(gl_FragCoord.x - (u_xoffset * u_blocksize), gl_FragCoord.y) / u_blocksize) - offset;

  if (block.x >= 0.0 && block.y >= 0.0 && block.x < u_piecesize.x && block.y < u_piecesize.y) {
    vec2 pixel = mod(vec2(gl_FragCoord.x - (u_xoffset * u_blocksize), gl_FragCoord.y), u_blocksize);
    vec2 tmp = (block + vec2(0.5)) / u_piecesize;
    vec4 color = texture2D(u_piece, vec2(tmp.x, 1.0 - tmp.y));

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

    vec4 src = color * vec4(vec3(shade2), 1.0) + vec4(vec3(shade), 0.0);
    vec4 dst = gl_FragColor;
    float outa = src.a + dst.a * (1.0 - src.a);
    gl_FragColor = vec4((src.rgb * src.a + dst.rgb * dst.a * (1.0 - src.a)) / outa, outa);
  }
}
