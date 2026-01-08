use fmt;
use raylib::*;

// NOTE: Color Constants
def COLOR_BAR    = Color { r= 255, g= 0, b= 0, a= 255 };
def COLOR_PROJ   = Color { r= 255, g= 255, b= 255, a= 255 };
def COLOR_TARGET = Color { r= 0,   g= 255, b= 0, a= 255 };
def COLOR_WINDOW = Color { r= 34,  g= 34, b= 34, a= 255 };
def COLOR_TEXT   = Color { r= 229,  g= 229, b= 229, a= 255 };

// NOTE: Window Constants
def WINDOW_WIDTH: f32  = 1600.0;
def WINDOW_HEIGHT: f32 = 900.0;
def WINDOW_WIDTH_HALF: f32  = (WINDOW_WIDTH  * 0.5);
def WINDOW_HEIGHT_HALF: f32 = (WINDOW_HEIGHT * 0.5);

// NOTE: Text Constants
def TEXT_FONT_SIZE: size = 20;
def TEXT_PIXEL_HEIGHT_FACTOR: f32 = 0.042;
def TEXT_HEIGHT: int = TEXT_PIXEL_HEIGHT_FACTOR:int * WINDOW_HEIGHT:int;

// NOTE: Projectile Constants
def PROJ_SIZE: f32  = 20.0;
def PROJ_DEFAULT_X: f32 = (WINDOW_WIDTH_HALF - (PROJ_SIZE * 0.5));
def PROJ_DEFAULT_Y: f32 = WINDOW_HEIGHT - BAR_THICNESS - BAR_PADDING_Y - PROJ_SIZE;
def PROJ_SPEED: f32 = 400.0;

// NOTE: Bar Constants
def BAR_LEN: f32 = 100.0;
def BAR_PADDING_Y: f32 = 100.0;
def BAR_LEN_HALF: f32  = BAR_LEN * 0.5;
def BAR_THICNESS: f32  = 20.0;
def BAR_DEFAULT_Y: f32 = WINDOW_HEIGHT - BAR_THICNESS - BAR_PADDING_Y;
def BAR_DEFAULT_X: f32 = WINDOW_WIDTH_HALF - BAR_LEN_HALF;
def BAR_SPEED: f32 = 700.0;

// NOTE: Target Constants
def TARGET_ROWS: size = 9;
def TARGET_COLS: size = 10;
def TARGET_CAPACITY: size = TARGET_ROWS * TARGET_COLS;
def TARGET_GRID_Y: f32  = 50.0;
def TARGET_WIDTH: f32   = 100.0;
def TARGET_HEIGHT: f32  = 20.0;
def TARGET_PADDING_X: f32 = 20.0;
def TARGET_PADDING_Y: f32 = 20.0;

// NOTE: Score section Constants
def SCORE_PADDING_LEFT         : int   = 40;
def SCORE_PADDING_TOP          : int   = 30;

type Target = struct {
	rect: Rectangle,
	dead: bool,
};

type game_state = struct {
	over: bool,
	running: bool,
	debug: bool,
	proj_rect: Rectangle,
	proj_vel: Vec2,
	bar_rect: Rectangle,
	bar_dx: f32,
	dead_target_count: size,
	score: i32,
};

fn update(state: *game_state, targets: []Target, dt: f32) void = {
	const proj_delta: f32 = PROJ_SPEED * dt;
	const bar_delta: f32  = BAR_SPEED * dt;

	let rect = Rectangle {
		x = state.proj_rect.y,
		y = state.proj_rect.y,
		w = state.proj_rect.w,
		h = state.proj_rect.h,
	};

	let proj_nx: f32 = state.proj_rect.x + (state.proj_vel.x * proj_delta);
	rect.x=proj_nx;
	let cond_x: bool = (proj_nx < 0.0 || (proj_nx + PROJ_SIZE) > WINDOW_WIDTH || check_collision_recs(rect, state.bar_rect));
	for (let target &.. targets) {
		if (!target.dead) {
			const collide_with_proj = check_collision_recs(rect, target.rect);
			if (collide_with_proj) {
				state.dead_target_count = state.dead_target_count + 1;
				target.dead=true;
				state.score += 1;
				cond_x = cond_x || collide_with_proj;
				break;
			};
		};
	};
	if (cond_x) {
		state.proj_vel.x *= -1.0;
		proj_nx = state.proj_rect.x + (state.proj_vel.x * proj_delta);
	};
	state.proj_rect.x = proj_nx;

	let proj_ny: f32 = state.proj_rect.y + (state.proj_vel.y * proj_delta);
	rect.y=proj_ny;
	let cond_y: bool = (proj_ny < 0.0 || (proj_ny + PROJ_SIZE) > WINDOW_HEIGHT || check_collision_recs(rect, state.bar_rect));
	for (let target &.. targets) {
		if (!target.dead) {
			const collide_with_proj = check_collision_recs(rect, target.rect);
			if (collide_with_proj) {
				state.dead_target_count = state.dead_target_count + 1;
				target.dead=true;
				state.score += 1;
				cond_y = cond_y || collide_with_proj;
				break;
			};
		};
	};
	if (cond_y) {
		state.proj_vel.y *= -1.0;
		proj_ny = state.proj_rect.y + (state.proj_vel.y * proj_delta);
	};
	state.proj_rect.y = proj_ny;

	const bar_nx: f32 = state.bar_rect.x + (state.bar_dx * bar_delta);
	if (bar_nx > 0.0 && (bar_nx + BAR_LEN) < WINDOW_WIDTH) {
		state.bar_rect.x = bar_nx;
	};

	if (state.proj_rect.y > state.bar_rect.y) state.over=true;
};

fn render(state: *game_state, targets: []Target) void = {
	begin_drawing();
	clear_background(COLOR_WINDOW);
	draw_rectangle_rec(state.proj_rect,  COLOR_PROJ);
	draw_rectangle_rec(state.bar_rect,   COLOR_BAR);
	for (let target &.. targets) {
		if (!target.dead) {
			draw_rectangle_rec(target.rect,  COLOR_TARGET);
		};
	};
	const score_text = fmt::asprintf("Score: {:.3}", state.score)!;
	defer free(score_text);
	draw_text(score_text, SCORE_PADDING_LEFT:size,(SCORE_PADDING_TOP + TEXT_HEIGHT):size, TEXT_FONT_SIZE, COLOR_TEXT);
	end_drawing();
};

fn reset(state: *game_state) void = {
	state.over = false;
	state.debug = false;
	state.running = false;
	state.proj_rect = Rectangle {
		x = PROJ_DEFAULT_X,
		y = PROJ_DEFAULT_Y,
		w = PROJ_SIZE,
		h = PROJ_SIZE,
	};
	state.proj_vel = Vec2 {
		x = -1.0,
		y = -1.0,
	};
	state.bar_rect = Rectangle {
		x = BAR_DEFAULT_X,
		y = BAR_DEFAULT_Y,
		w= BAR_LEN,
		h= BAR_THICNESS,
	};
	state.bar_dx = 0.0;
};

fn init_targets(targets: []Target) void = {
	const target_grid_width = (TARGET_COLS:f32 *TARGET_WIDTH + (TARGET_COLS:f32)*TARGET_PADDING_X);
	const target_grid_x = WINDOW_WIDTH/2.0 - target_grid_width/2.0;

	let index: size = 0;
	for (let target &.. targets) {
		target.rect.x = (target_grid_x + (TARGET_WIDTH:f32 + TARGET_PADDING_X) * (index % TARGET_COLS):f32);
		target.rect.y = (TARGET_GRID_Y + (TARGET_HEIGHT:f32 + TARGET_PADDING_Y) * (index % TARGET_ROWS):f32);
		index += 1;
	};
};

export fn main() void = {
	init_window(WINDOW_WIDTH: size, WINDOW_HEIGHT: size, "Breaking Hare");
	defer close_window();
	let quit: bool = false;

	let game = game_state {...};
	reset(&game);

	let targets: [TARGET_CAPACITY]Target = [Target{rect=Rectangle{x=0.0, y=0.0, w=TARGET_WIDTH, h=TARGET_HEIGHT}, dead=false}...];
	init_targets(&targets);


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
		if (game.running) {
			update(&game, targets, dt);
			quit = (game.dead_target_count >= TARGET_CAPACITY);
		};

		render(&game, targets);
	};

};
