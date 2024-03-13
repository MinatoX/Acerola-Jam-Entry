shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;

//Define rgb offsets
uniform vec2 rOff = vec2(-6.0, -6.0);
uniform vec2 gOff = vec2(-6.0, 6.0);
uniform vec2 bOff = vec2(-6.0, 6.0);


void fragment()
{
	//Merge offset with current screen info
	float r = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE*rOff), 0.0).r;
	float g = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE*gOff), 0.0).g;
	float b = texture(SCREEN_TEXTURE, SCREEN_UV + vec2(SCREEN_PIXEL_SIZE*bOff), 0.0).b;
	
	//Apply the merged colors
	COLOR = vec4(r, g, b, 1.0);
}