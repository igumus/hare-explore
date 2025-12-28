use fmt;
use raylib::*;

// NOTE: Window constants
const WINDOW_WIDTH: f32 = 800.0;
const WINDOW_HEIGHT: f32 = 600.0;
const WINDOW_COLOR = Color { r= 34, g= 34, b= 34, a= 255 };

// NOTE: projectile constants
const PROJ_SIZE: f32 = 10.0;
const PROJ_SPEED: f32 = 300.0;
const PROJ_COLOR = Color { r= 255, g= 0, b= 0, a= 255 };

// NOTE: bar constants
const BAR_LEN: f32 = 100.0;
const BAR_THICNESS: f32 = 10.0;
const BAR_Y_PAD: f32 = 100.0;
const BAR_COLOR = Color { r= 255, g= 255, b= 255, a= 255 };
const BAR_SPEED: f32 = 200.0;

type game_state = struct {
	over: bool,
	running: bool,
	debug: bool,
	proj_rect: Rectangle,
	proj_vel: Vec2,
	bar_rect: Rectangle,
	bar_dx: f32,
};

fn update(state: *game_state, frame_time: f32) void = {
	const proj_delta: f32 = PROJ_SPEED * frame_time;

	let rect = Rectangle {
		x = state.proj_rect.y,
		y = state.proj_rect.y,
		w = state.proj_rect.w,
		h = state.proj_rect.h,
	};

	let proj_nx: f32 = state.proj_rect.x + (state.proj_vel.x * proj_delta);
	rect.x=proj_nx;
	if (proj_nx < 0.0 || (proj_nx + PROJ_SIZE) > WINDOW_WIDTH || check_collision_recs(rect, state.bar_rect)) {
		state.proj_vel.x *= -1.0;
		proj_nx = state.proj_rect.x + (state.proj_vel.x * proj_delta);
	};
	state.proj_rect.x = proj_nx;

	let proj_ny: f32 = state.proj_rect.y + (state.proj_vel.y * proj_delta);
	rect.y=proj_ny;
	if (proj_ny < 0.0 || (proj_ny + PROJ_SIZE) > WINDOW_HEIGHT || check_collision_recs(rect, state.bar_rect)) {
		state.proj_vel.y *= -1.0;
		proj_ny = state.proj_rect.y + (state.proj_vel.y * proj_delta);
	};
	state.proj_rect.y = proj_ny;

	const bar_nx: f32 = state.bar_rect.x + (state.bar_dx * BAR_SPEED * frame_time);
	if (bar_nx > 0.0 && (bar_nx + BAR_LEN) < WINDOW_WIDTH) {
		state.bar_rect.x = bar_nx;
	};

	if (state.proj_rect.y > state.bar_rect.y) state.over=true;
};

fn render(state: *game_state) void = {
	begin_drawing();
	clear_background(WINDOW_COLOR);
	draw_rectangle_rec(state.proj_rect,  PROJ_COLOR);
	draw_rectangle_rec(state.bar_rect,   BAR_COLOR);
	if (state.debug) draw_fps(10,10);
	end_drawing();
};

fn reset(state: *game_state) void = {
	state.over = false;
	state.debug = false;
	state.running = false;
	state.proj_rect = Rectangle {
		x = WINDOW_WIDTH/2.0,
		y = WINDOW_HEIGHT - BAR_THICNESS - BAR_Y_PAD - PROJ_SIZE,
		w = PROJ_SIZE,
		h = PROJ_SIZE,
	};
	state.proj_vel = Vec2 {
		x = -1.0,
		y = -1.0,
	};
	state.bar_rect = Rectangle {
		x = WINDOW_WIDTH/2.0 - BAR_LEN/2.0,
		y = WINDOW_HEIGHT - BAR_THICNESS - BAR_Y_PAD,
		w= BAR_LEN,
		h= BAR_THICNESS,
	};
	state.bar_dx = 0.0;
};

export fn main() void = {
	init_window(WINDOW_WIDTH: size, WINDOW_HEIGHT: size, "Breaking Hare");
	defer close_window();
	let quit: bool = false;

	let game = game_state {...};
	reset(&game);

	for(!quit) {
		if (window_should_close() || is_key_pressed('Q')) {
			quit = true;
			continue;
		};

		if (game.over) reset(&game);

		const dt: f32 = get_frame_time();

		if (is_key_down('D')) {
			game.bar_dx = 1.0;
		} else if (is_key_down('A')){
			game.bar_dx = -1.0;
		} else {
			game.bar_dx = 0.0;
		};

		if(is_key_pressed('I')) game.debug = !game.debug;
		if(is_key_pressed(' ')) game.running = !game.running;
		if (game.running) update(&game, dt);

		render(&game);
	};

};
