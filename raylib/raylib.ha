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

export type Rectangle = struct {
	x: f32,
	y: f32,
	w: f32,
	h: f32
};

@symbol("InitWindow") fn InitWindow(width: size, height: size, title: const *c::char) void;
export fn init_window(width: size, height: size, title: str) void = {
	InitWindow(width, height, c::fromstr(title)!);
};

export @symbol("WindowShouldClose") fn window_should_close() bool;
export @symbol("CloseWindow") fn close_window() void;
export @symbol("GetColor") fn get_color(color: int) Color;
export @symbol("ClearBackground") fn clear_background(color: Color) void;
export @symbol("IsKeyPressed") fn is_key_pressed(key: int) bool;
export @symbol("IsKeyDown") fn is_key_down(key: int) bool;
export @symbol("GetFrameTime") fn get_frame_time() f32;

// NOTE: Drawing Functions
export @symbol("BeginDrawing") fn begin_drawing() void;
export @symbol("EndDrawing") fn end_drawing() void;

export @symbol("DrawCircle") fn draw_circle(cx: int, cy: int, r: f32, c: Color) void;
export @symbol("DrawRectangle") fn draw_rectangle(x: int, y: int, w: int, h: int, c: Color) void;
export @symbol("DrawRectangleV") fn draw_rectangle_v(pos: Vec2, sz: Vec2, c: Color) void;
export @symbol("DrawRectangleRec") fn draw_rectangle_rec(rec: Rectangle, c: Color) void;

// NOTE: Collisions
export @symbol("CheckCollisionRecs") fn check_collision_recs(rec1: Rectangle, rec2: Rectangle) bool;

// NOTE: Text Utilities
export @symbol("DrawFPS") fn draw_fps(x: int, y: int) void;

@symbol("DrawText") fn DrawText(text: const *c::char, x: size, y: size, font_size: size, color: Color) void;
export fn draw_text(text: str, posX: size, posY: size, font_size: size, color: Color) void = {
	DrawText(c::fromstr(text)!, posX, posY, font_size, color);
};

