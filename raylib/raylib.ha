use types::c;

export type Color = struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8
};

@symbol("InitWindow") fn InitWindow(width: size, height: size, title: const *c::char) void;

export fn init_window(width: size, height: size, title: str) void = {
	InitWindow(width, height, c::fromstr(title)!);
};


export @symbol("WindowShouldClose") fn window_should_close() bool;
export @symbol("CloseWindow") fn close_window() void;
export @symbol("ClearBackground") fn clear_background(color: Color) void;
export @symbol("BeginDrawing") fn begin_drawing() void;
export @symbol("EndDrawing") fn end_drawing() void;
export @symbol("GetColor") fn get_color(color: int) Color;
export @symbol("DrawRectangle") fn draw_rectangle(x: int, y: int, w: int, h: int, c: Color) void;
export @symbol("IsKeyPressed") fn is_key_pressed(key: int) bool;
export @symbol("IsKeyDown") fn is_key_down(key: int) bool;
export @symbol("GetFrameTime") fn get_frame_time() f32;

