use types::c;

export type Color = struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
};

export type Vec2 = struct {
	x: f32,
	y: f32,
};

export type Vec3 = struct {
	x: f32,
	y: f32,
	z: f32,
};

export type Rectangle = struct {
	x: f32,
	y: f32,
	w: f32,
	h: f32
};

@symbol("InitWindow") fn internal_init_window(width: size, height: size, title: const *c::char) void;
export fn init_window(width: size, height: size, title: str) void = {
	internal_init_window(width, height, c::fromstr(title)!);
};

@symbol("GetScreenWidth") fn internal_get_screen_width() size;
@symbol("GetScreenHeight") fn internal_get_screen_height() size;

export @symbol("WindowShouldClose") fn window_should_close() bool;
export @symbol("CloseWindow") fn close_window() void;
export @symbol("IsKeyPressed") fn is_key_pressed(key: int) bool;
export @symbol("IsKeyDown") fn is_key_down(key: int) bool;
export @symbol("GetFrameTime") fn get_frame_time() f32;
export @symbol("GetTime") fn get_time() f64;

// Cursor-related functions
export @symbol("ShowCursor") fn cursor_show() void; // Shows cursor
export @symbol("HideCursor") fn cursor_hide() void; // Hides cursor
export @symbol("IsCursorHidden") fn cursor_hidden() bool; // Check if cursor is not visible
export @symbol("EnableCursor") fn cursor_enable() void;   // Enables cursor (unlock cursor)
export @symbol("DisableCursor") fn cursor_disable() void; // Disables cursor (lock cursor)
export @symbol("IsCursorOnScreen") fn cursor_is_on_screen() bool; // Check if cursor is on the screen

// NOTE: Drawing Functions
export @symbol("BeginDrawing") fn begin_drawing() void;
export @symbol("EndDrawing") fn end_drawing() void;

// NOTE: Blending modes
export @symbol("BeginBlendMode") fn begin_blending_mode(mode: int) void;
export @symbol("EndBlendMode") fn end_blending_mode() void;

// NOTE: Color operations
export @symbol("GetColor") fn get_color(color: int) Color;
export @symbol("ClearBackground") fn clear_background(color: Color) void;
export @symbol("ColorFromHSV") fn color_from_hsv(h: f32, s: f32, v: f32) Color;
export fn color_from_hsv_vector(in: Vec3) Color = {
	return color_from_hsv(in.x, in.y, in.z);
};

export @symbol("DrawCircle") fn draw_circle(cx: int, cy: int, r: f32, c: Color) void;
export @symbol("DrawRectangle") fn draw_rectangle(x: int, y: int, w: int, h: int, c: Color) void;
export @symbol("DrawRectangleV") fn draw_rectangle_v(pos: Vec2, sz: Vec2, c: Color) void;
export @symbol("DrawRectangleRec") fn draw_rectangle_rec(rec: Rectangle, c: Color) void;

// NOTE: Collisions
export @symbol("CheckCollisionRecs") fn check_collision_recs(rec1: Rectangle, rec2: Rectangle) bool;

// NOTE: Text Utilities
export @symbol("DrawFPS") fn draw_fps(x: int, y: int) void;

def DEFAULT_TEXT_COLOR = Color { r= 229,  g= 229, b= 229, a= 255 };

@symbol("DrawText") fn DrawText(text: const *c::char, x: size, y: size, font_size: size, color: Color) void;
export fn draw_text(text: str, posX: size, posY: size, font_size: size, color: Color) void = {
	DrawText(c::fromstr(text)!, posX, posY, font_size, color);
};

@symbol("MeasureText") fn internal_measure_text(text: const *c::char, fontSize: size) size;
export fn measure_text(text: str, font_size: size) size = {
	return internal_measure_text(c::fromstr(text)!,  font_size);
};

export fn draw_text_at_center(text: str, font_size: size) void = {
	draw_colored_text_at_center(text, font_size, DEFAULT_TEXT_COLOR);
};

fn draw_colored_text_at_center(text: str, font_size: size, color: Color) void = {
	const half_window_width  = (internal_get_screen_width():f32  * 0.5):size;
	const half_window_height = (internal_get_screen_height():f32 * 0.5):size;
	const text_width = measure_text(text, font_size): f32;
	const half_text_width = (text_width * 0.5):size;
	const text_x = half_window_width - half_text_width;
	const text_y = half_window_height;
	draw_text(text, text_x, text_y, font_size, color);
};
