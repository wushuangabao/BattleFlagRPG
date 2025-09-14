shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;

uniform sampler2D u_frame_tex;

void fragment() {
	vec4 tex = texture(u_frame_tex, UV);
	vec4 white_color = vec4(1.0, 1.0, 1.0, tex.a);
	ALBEDO = mix(tex, white_color, 0.5).rgb;
	ALPHA = white_color.a;
}