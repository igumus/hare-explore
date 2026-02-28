use fmt;
use raylib::*;
use math;
use math::random;
use time::*;

// NOTE: Window Constants
def WINDOW_WIDTH: f32  = 1600.0;
def WINDOW_HEIGHT: f32 = 900.0;
def WINDOW_WIDTH_HALF: f32  = (WINDOW_WIDTH  * 0.5);
def WINDOW_HEIGHT_HALF: f32 = (WINDOW_HEIGHT * 0.5);
def WINDOW_COLOR = Color { r= 34,  g= 34, b= 34, a= 255 };

// NOTE: Text Constants
def TEXT_FONT_SIZE: size = 20;
def TEXT_PIXEL_HEIGHT_FACTOR: f32 = 0.042;
def TEXT_HEIGHT: int = TEXT_PIXEL_HEIGHT_FACTOR:int * WINDOW_HEIGHT:int;
def TEXT_COLOR = Color { r= 229,  g= 229, b= 229, a= 255 };

// NOTE: Projectile Constants
def PROJ_SIZE: f32  = 20.0;
def PROJ_DEFAULT_X: f32 = (WINDOW_WIDTH_HALF - (PROJ_SIZE * 0.5));
def PROJ_DEFAULT_Y: f32 = WINDOW_HEIGHT - BAR_THICNESS - BAR_PADDING_Y - PROJ_SIZE;
def PROJ_SPEED: f32 = 400.0;
def PROJ_COLOR = Color { r= 255, g= 255, b= 255, a= 255 };

// NOTE: Bar Constants
def BAR_LEN: f32 = 100.0;
def BAR_PADDING_Y: f32 = 100.0;
def BAR_LEN_HALF: f32  = BAR_LEN * 0.5;
def BAR_THICNESS: f32  = 20.0;
def BAR_DEFAULT_Y: f32 = WINDOW_HEIGHT - BAR_THICNESS - BAR_PADDING_Y;
def BAR_DEFAULT_X: f32 = WINDOW_WIDTH_HALF - BAR_LEN_HALF;
def BAR_SPEED: f32 = 700.0;
def BAR_COLOR = Color { r= 255, g= 0, b= 0, a= 255 };

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

// NOTE: Particle Constants
def PARTICLE_CAPACITY: size = 1024;
def PARTICLE_LIFE_TIME: f32 = 2.0;
def PARTICLE_BASE_SIZE: f32 = 10.0;
def PARTICLE_BASE_VELOCITY: f32 = 100.0;
//
// NOTE: Particle Emitter Constants
def PARTICLE_EMITTER_PERIOD: f32 = 0.001;
def PARTICLE_EMITTER_CAPACITY: size = 128;
def PARTICLE_EMITTER_LIFETIME: f32 = 0.01;

// NOTE: global variables
let particles: [PARTICLE_CAPACITY]Particle = [Particle{...}...];
let particleEmitters: [PARTICLE_EMITTER_CAPACITY]ParticleEmitter = [ParticleEmitter{...}...];
let targets: [TARGET_CAPACITY]Target = [Target{...}...];
let proj: Projectile = Projectile{...};
let bar: Bar = Bar{...};

type Target = struct {
	rect: Rectangle,
	dead: bool,
	hsv: Vec3
};

type Projectile = struct {
	rect: Rectangle,
	vel: Vec2,
};

type Bar = struct {
	rect: Rectangle,
	vel: Vec2,
};

type Particle = struct {
	rect: Rectangle,
	vel: Vec2,
	lifeTime: f32,
	color: Color
};

type ParticleEmitter = struct {
	x: f32,
	y: f32,
	color: Color,
	lifeTime: f32,
	period: f32
};

type Collision= enum {
	NONE = 0,
	WALL = 1,
	BAR  = 2,
	TARGET = 3
};

type game_state = struct {
	over: bool,
	running: bool,
	debug: bool,
	dead_target_count: size,
	score: i32,
};

fn particle_emitter_emit(x: f32, y: f32, lifeTime: f32, color: Color) void = {
	for (let emitter &.. particleEmitters) {
		if (emitter.lifeTime <= 0.0) {
			emitter.x = x;
			emitter.y = y;
			emitter.color = color;
			emitter.lifeTime = lifeTime;
			emitter.period = PARTICLE_EMITTER_PERIOD;
			return;
		};
	};
};

fn particle_emit(x: f32, y: f32, color: Color) void = {
	for (let particle &.. particles) {
		if (particle.lifeTime <= 0.0) {
			let now = now(clock::MONOTONIC);
			let rnd = random::init(now.nsec: u64);

			particle.rect.x = x;
			particle.rect.y = y;
			particle.lifeTime = PARTICLE_LIFE_TIME;
			particle.color = color;
			let random_from_zero_to_one = random::f64rand(&rnd);

			let sizeFactor = (0.5 + random_from_zero_to_one): f32;
			particle.rect.w = PARTICLE_BASE_SIZE * sizeFactor;
			particle.rect.h = PARTICLE_BASE_SIZE * sizeFactor;

			let random_angle_value = random::f64rand(&rnd);
			let angle = random_angle_value * math::TAU;
			let cos = math::cosf64(angle): f32;
			let sin = math::sinf64(angle): f32;
			particle.vel.x = (cos * PARTICLE_BASE_VELOCITY) * sizeFactor;
			particle.vel.y = (sin * PARTICLE_BASE_VELOCITY) * sizeFactor;
			return;
		};
	};
};

fn update_particle_emitter(emitter: *ParticleEmitter, dt: f32) void = {
	if (emitter.lifeTime <=0.0) return;
	emitter.lifeTime -= dt;
	emitter.period -= dt;
	if (emitter.period <= 0.0) {
		let n: int = (math::absf32(emitter.period) / PARTICLE_EMITTER_PERIOD): int;
		for (n > 0; n -=1) {
			particle_emit(emitter.x, emitter.y, emitter.color);
		};
		emitter.period = PARTICLE_EMITTER_PERIOD;
	};
};

fn update_particle_emitters(dt: f32) void = {
	for (let particleEmitter &.. particleEmitters) {
		update_particle_emitter(particleEmitter, dt);
	};
};

fn update_particles(dt: f32) void = {
	for (let particle &.. particles) {
		if (particle.lifeTime > 0.0) {
			horz_collision(&particle.rect, &particle.vel, 1.0, dt);
			vert_collision(&particle.rect, &particle.vel, 1.0, dt);
			particle.lifeTime -= dt;
		};
	};
};

fn target_hit(state: *game_state, targetIndex: int) void = {
	let target = &targets[targetIndex];
	if (target.dead) return;
	target.dead=true;
	let color = color_from_hsv_vector(target.hsv);
	particle_emitter_emit(proj.rect.x + PROJ_SIZE / 2.0, proj.rect.y + PROJ_SIZE / 2.0, PARTICLE_EMITTER_LIFETIME, color);
	state.dead_target_count = state.dead_target_count + 1;
	state.score += 1;
};

fn target_collision(rect: *Rectangle) Collision = {
	let index = 0z;
	for (let target &.. targets) {
		if (!target.dead) {
			const collide_with_proj = check_collision_recs(*rect, target.rect);
			if (collide_with_proj) {
				return (Collision::TARGET:int + index:int): Collision;
			};
		};
		index += 1;
	};
	return Collision::NONE;
};


fn horz_collision(rect: *Rectangle, vel: *Vec2, speed: f32, dt: f32) Collision = {
	const nx: f32 = rect.x + (vel.x * speed * dt);

	if (nx < 0.0 || (nx + rect.w) > WINDOW_WIDTH) {
		vel.x *= -1.0;
		return Collision::WALL;
	};

	let nrect = Rectangle {
		x = nx,
		y = rect.y,
		w = rect.w,
		h = rect.h,
	};

	if (check_collision_recs(nrect, bar.rect)) {
		vel.x *= -1.0;
		return Collision::BAR;
	};

	const targetCollide = target_collision(&nrect);
	if (targetCollide:int >= Collision::TARGET:int) {
		vel.x *= -1.0;
		return targetCollide;
	};

	rect.x = nx;
	return Collision::NONE;
};

fn vert_collision(rect: *Rectangle, vel: *Vec2, speed: f32, dt: f32) Collision = {
	const ny: f32 = rect.y + (vel.y * speed * dt);

	if (ny < 0.0 || (ny + rect.h) > WINDOW_HEIGHT) {
		vel.y *= -1.0;
		return Collision::WALL;
	};

	let nrect = Rectangle {
		x = rect.x,
		y = ny,
		w = rect.w,
		h = rect.h,
	};

	if (check_collision_recs(nrect, bar.rect)) {
		vel.y *= -1.0;
		return Collision::BAR;
	};

	const targetCollide = target_collision(&nrect);
	if (targetCollide:int >= Collision::TARGET:int) {
		vel.y *= -1.0;
		return targetCollide;
	};

	rect.y = ny;
	return Collision::NONE;
};

fn handle_projectile_collision(state: *game_state, collision: Collision) void = {
	if (collision == Collision::NONE || collision == Collision::WALL) return;

	let halfProjSize = PROJ_SIZE / 2.0;
	if (collision == Collision::BAR) {
		particle_emitter_emit(proj.rect.x + halfProjSize, proj.rect.y + halfProjSize, PARTICLE_EMITTER_LIFETIME, BAR_COLOR);
	} else {
		let target_index =(collision: int) - (Collision::TARGET: int);
		target_hit(state, target_index);
	};
};


fn update_projectile(state: *game_state, dt: f32) void = {
	let collision = horz_collision(&proj.rect, &proj.vel, PROJ_SPEED, dt);
	handle_projectile_collision(state,collision);

	collision = vert_collision(&proj.rect, &proj.vel, PROJ_SPEED, dt);
	handle_projectile_collision(state,collision);
};

fn update(state: *game_state, dt: f32) void = {
	update_projectile(state, dt);

	const bar_nx: f32 = bar.rect.x + (bar.vel.x * BAR_SPEED * dt);
	if (bar_nx > 0.0 && (bar_nx + BAR_LEN) < WINDOW_WIDTH) {
		bar.rect.x = bar_nx;
	};


	update_particles(dt);
	update_particle_emitters(dt);
};

fn render_particles() void = {
	for (let particle &.. particles) {
		if (particle.lifeTime > 0.0) {
			particle.color.a = (255.0 * (particle.lifeTime / PARTICLE_LIFE_TIME)):u8;
			draw_rectangle_rec(particle.rect,  particle.color);
		};
	};
};

fn render_targets() void = {
	for (let target &.. targets) {
		if (!target.dead) {
			let color = color_from_hsv_vector(target.hsv);
			draw_rectangle_rec(target.rect,  color);
		};
	};
};

fn render_score(state: *game_state) void = {
	const score_text = fmt::asprintf("Score: {:.3}", state.score)!;
	defer free(score_text);
	draw_text(score_text, SCORE_PADDING_LEFT:size,(SCORE_PADDING_TOP + TEXT_HEIGHT):size, TEXT_FONT_SIZE, TEXT_COLOR);
};

fn render(state: *game_state, targets: []Target, particles: []Particle) void = {
	begin_drawing();
	clear_background(WINDOW_COLOR);
	begin_blending_mode(0);

	draw_rectangle_rec(proj.rect,  PROJ_COLOR);
	draw_rectangle_rec(bar.rect,   BAR_COLOR);

	render_targets();
	render_particles();
	render_score(state);

	end_blending_mode();

	end_drawing();
};

fn reset_bar() void = {
	bar.rect.x = BAR_DEFAULT_X;
	bar.rect.y = BAR_DEFAULT_Y;
	bar.rect.w= BAR_LEN;
	bar.rect.h= BAR_THICNESS;
	bar.vel.x = 0.0;
	bar.vel.y = 0.0;
};

fn reset_projectile() void = {
	proj.rect.x = PROJ_DEFAULT_X;
	proj.rect.y = PROJ_DEFAULT_Y;
	proj.rect.w = PROJ_SIZE;
	proj.rect.h = PROJ_SIZE;
	proj.vel.x = -1.0;
	proj.vel.y = -1.0;
};


fn init_targets() void = {
	const target_grid_width = (TARGET_COLS:f32 *TARGET_WIDTH + (TARGET_COLS:f32)*TARGET_PADDING_X);
	const target_grid_x = WINDOW_WIDTH/2.0 - target_grid_width/2.0;

	let index: size = 0;
	for (let target &.. targets) {
		let rowIndex = (index % TARGET_ROWS):f32;
		let colIndex = (index % TARGET_COLS):f32;
		target.rect.x = (target_grid_x + (TARGET_WIDTH:f32 + TARGET_PADDING_X) * colIndex);
		target.rect.y = (TARGET_GRID_Y + (TARGET_HEIGHT:f32 + TARGET_PADDING_Y) * rowIndex);
		target.rect.w = TARGET_WIDTH;
		target.rect.h = TARGET_HEIGHT;
		target.dead = false;
		target.hsv.x = rowIndex * 30.0;
		target.hsv.y = 0.9;
		target.hsv.z = 0.8;
		index += 1;
	};
};

fn reset(state: *game_state) void = {
	state.over = false;
	state.debug = false;
	state.running = false;

	reset_bar();
	reset_projectile();
};

export fn main() void = {
	init_window(WINDOW_WIDTH: size, WINDOW_HEIGHT: size, "Breaking Hare");
	defer close_window();
	let quit: bool = false;

	let game = game_state {...};
	reset(&game);

	init_targets();

	for(!quit) {
		if (window_should_close() || is_key_pressed('Q')) {
			quit = true;
			continue;
		};

		if (game.over) reset(&game);

		const dt: f32 = get_frame_time();

		if (is_key_down('D')) {
			bar.vel.x = 1.0;
		} else if (is_key_down('A')){
			bar.vel.x = -1.0;
		} else {
			bar.vel.x = 0.0;
		};

		if(is_key_pressed('I')) game.debug = !game.debug;
		if(is_key_pressed(' ')) game.running = !game.running;
		if (game.running) {
			update(&game, dt);
			quit = (game.dead_target_count >= TARGET_CAPACITY);
		};

		render(&game, targets, particles);
	};

};
