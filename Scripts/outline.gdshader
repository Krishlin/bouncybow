shader_type canvas_item;
// Draws a coloured outline around a sprite. Used for the red "took damage" outline
// on the player and boss, and the always-on red outline on the boss's arrows.

uniform vec4 outline_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
// thickness in sprite pixels. 0 turns the outline off
uniform float outline_width = 0.0;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 result = tex * tint;

	if (outline_width > 0.0 && tex.a < 0.5) {
		// this pixel is empty. if any pixel next to it is solid, its part of the outline
		vec2 o = TEXTURE_PIXEL_SIZE * outline_width;
		float near = 0.0;
		near = max(near, texture(TEXTURE, UV + vec2(o.x, 0.0)).a);
		near = max(near, texture(TEXTURE, UV + vec2(-o.x, 0.0)).a);
		near = max(near, texture(TEXTURE, UV + vec2(0.0, o.y)).a);
		near = max(near, texture(TEXTURE, UV + vec2(0.0, -o.y)).a);
		near = max(near, texture(TEXTURE, UV + vec2(o.x, o.y)).a);
		near = max(near, texture(TEXTURE, UV + vec2(-o.x, o.y)).a);
		near = max(near, texture(TEXTURE, UV + vec2(o.x, -o.y)).a);
		near = max(near, texture(TEXTURE, UV + vec2(-o.x, -o.y)).a);
		if (near > 0.5) {
			result = vec4(outline_color.rgb, outline_color.a * tint.a);
		}
	}

	COLOR = result;
}
