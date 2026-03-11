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
def LIFE_COLOR = Color { r= 230, g= 41, b= 55, a= 255 };

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
def TARGET_RIGIDITY_FACTOR: f32 = 80.0;

// NOTE: Score section Constants
def SCORE_PADDING_LEFT : int   = 40;
def SCORE_PADDING_TOP  : int   = 30;

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

type Target_Rigidity = enum {
	STANDART,
	MEDIUM,
	HARD,
	EXTRA,

	MAX_RIGIDITY
};

fn random_target_rigidity() Target_Rigidity = {
	const now = now(clock::MONOTONIC);
	const rnd = random::init(now.nsec: u64);
	const next = random::u32n(&rnd, Target_Rigidity::MAX_RIGIDITY:u32):int;
	return next:Target_Rigidity;
};

type Target = struct {
	rect: Rectangle,
	dead: bool,
	color: Color,
	rigidity: Target_Rigidity
};

type Projectile = struct {
	rect: Rectangle,
	vel: Vec2,
	color: Vec3
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

type Collision = enum {
	NONE          = 0,
	BORDER_LEFT   = 1,
	BORDER_RIGHT  = 2,
	BORDER_TOP    = 3,
	BORDER_BOTTOM = 4,
	BAR           = 5,
	TARGET        = 6
};

type Game_State = enum {
	START    = 0,
	PLAY     = 1,
	PAUSE    = 2,
	GAMEOVER = 3,
	RESTART  = 4,
	VICTORY  = 5
};

type Game = struct {
	state: Game_State,
	debug: bool,
	dead_target_count: size,
	score: i32,
	lifes: i8,
	deathCoolDown: f32,
	bar: Bar,
	projectile: Projectile,
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

fn update_particles(game: *Game, dt: f32) void = {
	for (let particle &.. particles) {
		if (particle.lifeTime > 0.0) {
			horz_collision(game, &particle.rect, &particle.vel, 1.0, dt);
			vert_collision(game, &particle.rect, &particle.vel, 1.0, dt);
			particle.lifeTime -= dt;
		};
	};
};

fn target_hit(game: *Game, targetIndex: int) void = {
	let target = &targets[targetIndex];
	if (target.dead) return;
	const rigidity = target.rigidity:int;
	if (rigidity > 0) {
		target.rigidity = (rigidity - 1):Target_Rigidity;
		target.color.a = (255.0 - (TARGET_RIGIDITY_FACTOR * (target.rigidity:int):f32)):u8;
	} else {
		target.dead=true;
		game.dead_target_count = game.dead_target_count + 1;
		game.score += 1;
		particle_emitter_emit(game.projectile.rect.x + PROJ_SIZE / 2.0, game.projectile.rect.y + PROJ_SIZE / 2.0, PARTICLE_EMITTER_LIFETIME, target.color);
	};
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


fn horz_collision(game: *Game, rect: *Rectangle, vel: *Vec2, speed: f32, dt: f32) Collision = {
	const nx: f32 = rect.x + (vel.x * speed * dt);

	if (nx < 0.0) {
		vel.x *= -1.0;
		return Collision::BORDER_LEFT;
	};
	if ((nx + rect.w) > WINDOW_WIDTH) {
		vel.x *= -1.0;
		return Collision::BORDER_RIGHT;
	};

	let nrect = Rectangle {
		x = nx,
		y = rect.y,
		w = rect.w,
		h = rect.h,
	};

	if (check_collision_recs(nrect, game.bar.rect)) {
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

fn vert_collision(game: *Game, rect: *Rectangle, vel: *Vec2, speed: f32, dt: f32) Collision = {
	const ny: f32 = rect.y + (vel.y * speed * dt);

	if (ny < 0.0) {
		vel.y *= -1.0;
		return Collision::BORDER_TOP;
	};
	if ((ny + rect.h) > WINDOW_HEIGHT) {
		vel.y *= -1.0;
		return Collision::BORDER_BOTTOM;
	};

	let nrect = Rectangle {
		x = rect.x,
		y = ny,
		w = rect.w,
		h = rect.h,
	};

	if (check_collision_recs(nrect, game.bar.rect)) {
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

fn handle_projectile_collision(game: *Game, collision: Collision) void = {
	switch(collision) {
	case Collision::NONE, Collision::BORDER_LEFT, Collision::BORDER_RIGHT, Collision::BORDER_TOP => return;
	case Collision::BORDER_BOTTOM =>
		let halfProjSize = PROJ_SIZE;
		particle_emitter_emit(game.projectile.rect.x + halfProjSize, game.projectile.rect.y - halfProjSize, PARTICLE_EMITTER_LIFETIME, PROJ_COLOR);
		let i = 0z;
		for (i < 10; i+= 1) {
			particle_emitter_emit(game.bar.rect.x + BAR_THICNESS , game.bar.rect.y - BAR_THICNESS, PARTICLE_EMITTER_LIFETIME, BAR_COLOR);
		};
		game.state = Game_State::GAMEOVER;
		return;
	case Collision::BAR =>
		let halfProjSize = PROJ_SIZE / 2.0;
		particle_emitter_emit(game.projectile.rect.x + halfProjSize, game.projectile.rect.y + halfProjSize, PARTICLE_EMITTER_LIFETIME, BAR_COLOR);
	case =>
		let target_index =(collision: int) - (Collision::TARGET: int);
		target_hit(game, target_index);
	};
};


fn update_projectile(game: *Game, dt: f32) void = {
	let collision = horz_collision(game, &game.projectile.rect, &game.projectile.vel, PROJ_SPEED, dt);
	handle_projectile_collision(game,collision);

	collision = vert_collision(game, &game.projectile.rect, &game.projectile.vel, PROJ_SPEED, dt);
	handle_projectile_collision(game,collision);
};

fn update_bar(game: *Game, dt: f32) void = {
	const bar_nx: f32 = game.bar.rect.x + (game.bar.vel.x * BAR_SPEED * dt);
	if (bar_nx > 0.0 && (bar_nx + game.bar.rect.w) < WINDOW_WIDTH) {
		game.bar.rect.x = bar_nx;
	};
};

fn update(game: *Game, dt: f32) void = {
	update_projectile(game, dt);
	update_bar(game, dt);
	update_particles(game, dt);
	update_particle_emitters(dt);
};


fn game_reset(game: *Game, full: bool = true) void = {
	// reset game
	game.state  =  Game_State::START;
	game.debug = false;
	game.deathCoolDown = 4.0;


	// reset bar
	game.bar.rect.x = BAR_DEFAULT_X;
	game.bar.rect.y = BAR_DEFAULT_Y;
	game.bar.rect.w= BAR_LEN;
	game.bar.rect.h= BAR_THICNESS;
	game.bar.vel.x = 0.0;
	game.bar.vel.y = 0.0;

	// reest projectile
	game.projectile.rect.x = PROJ_DEFAULT_X;
	game.projectile.rect.y = PROJ_DEFAULT_Y;
	game.projectile.rect.w = PROJ_SIZE;
	game.projectile.rect.h = PROJ_SIZE;
	game.projectile.vel.x = -1.0;
	game.projectile.vel.y = -1.0;
	game.projectile.color.x = 360.0;
	game.projectile.color.y = 0.0;
	game.projectile.color.z = 1.0;

	if (full) {
		game.dead_target_count = 0;
		game.score = 0;
		game.lifes = 3;

		// reset targets
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

			target.rigidity = random_target_rigidity();
			target.color = color_from_hsv(rowIndex * 30.0, 0.9, 1.0);
			target.color.a = (255.0 - (TARGET_RIGIDITY_FACTOR * (target.rigidity:int):f32)):u8;

			index += 1;
		};
	};
};

type Game_Controller = struct {
	left: bool,
	right: bool,
	start: bool
};

type Game_Input = struct {
	controller: Game_Controller,
	deltaTime: f32,
	elapsedTime: f64
};

fn game_input_reset(input: *Game_Input) void = {
	input.deltaTime = 0.0;
	input.elapsedTime = 0.0;
	input.controller.left = false;
	input.controller.right = false;
	input.controller.start = false;
};

fn update_bar_velocity(game: *Game, input: *Game_Input) void = {
	if (input.controller.left) {
		game.bar.vel.x = -1.0;
	} else if (input.controller.right) {
		game.bar.vel.x = 1.0;
	} else {
		game.bar.vel.x = 0.0;
	};
};

fn game_update(game: *Game, input: *Game_Input) void = {
	switch(game.state) {
	case Game_State::START => if (input.controller.start) {
		game.state = Game_State::PLAY;
	} else {
		update_bar_velocity(game, input);
		update_bar(game, input.deltaTime);
		game.projectile.rect.x = game.bar.rect.x + BAR_LEN/2.0 - PROJ_SIZE/2.0;
		game.projectile.rect.y = (WINDOW_HEIGHT - PROJ_SIZE - BAR_PADDING_Y) - BAR_THICNESS/2.0 - PROJ_SIZE - 1.0;
	};
	case Game_State::PLAY => if (input.controller.start) {
		game.state = Game_State::PAUSE;
	} else {
		update_bar_velocity(game, input);
		update(game, input.deltaTime);
	};
	case Game_State::PAUSE => if (input.controller.start) {
		game.state = Game_State::PLAY;
	} else {
		update_particles(game, input.deltaTime);
		update_particle_emitters(input.deltaTime);
	};
	case Game_State::GAMEOVER =>
		update_particles(game, input.deltaTime);
		update_particle_emitters(input.deltaTime);
		game.deathCoolDown -= input.deltaTime;
		game.projectile.color.z -= input.deltaTime;
		if (game.lifes <= 0) {
			game.state = Game_State::RESTART;
		} else if (game.deathCoolDown <= 0.0) {
			game.lifes -= 1;
			game_reset(game, false);
		};
	case Game_State::RESTART  => if (input.controller.start) {
		game_reset(game);
	} else {
		update_particles(game, input.deltaTime);
		update_particle_emitters(input.deltaTime);
	};
	case Game_State::VICTORY  => fmt::println("game state = victory")!;
	};

};

fn update_and_render(game: *Game, input: *Game_Input) void = {
	game_update(game, input);

	// render
	begin_drawing();
	clear_background(WINDOW_COLOR);
	begin_blending_mode(0);

	if (game.state != Game_State::GAMEOVER && game.state != Game_State::RESTART) {
		const projectileColor = color_from_hsv_vector(game.projectile.color);
		draw_rectangle_rec(game.projectile.rect,  projectileColor);
		draw_rectangle_rec(game.bar.rect,   BAR_COLOR);
	};

	for (let target &.. targets) {
		if (!target.dead) {
			draw_rectangle_rec(target.rect,  target.color);
		};
	};

	for (let particle &.. particles) {
		if (particle.lifeTime > 0.0) {
			particle.color.a = (255.0 * (particle.lifeTime / PARTICLE_LIFE_TIME)):u8;
			draw_rectangle_rec(particle.rect,  particle.color);
		};
	};

	if (game.state == Game_State::GAMEOVER) {
		draw_text_at_center("Game Over",TEXT_FONT_SIZE * 2);
	};

	if (game.state == Game_State::RESTART) {
		draw_text_at_center("Press SPACE to restart game", TEXT_FONT_SIZE * 2);
	};

	const text_y = SCORE_PADDING_TOP + TEXT_HEIGHT;
	const score_text = fmt::asprintf("Score: {:.3}", game.score)!;
	defer free(score_text);
	draw_text(score_text, SCORE_PADDING_LEFT:size,text_y:size, TEXT_FONT_SIZE, TEXT_COLOR);

	let i = 0i;
	const pad: f32 = 10.0;
	const life_position_y: f32 = pad + text_y:f32 + TEXT_FONT_SIZE: f32;
	for ( i < game.lifes; i+=1) {
		const rect = Rectangle{...};
		rect.x = SCORE_PADDING_LEFT:f32 + i:f32 * (PROJ_SIZE + pad);
		rect.y = life_position_y;
		rect.w = PROJ_SIZE;
		rect.h = PROJ_SIZE;
		draw_rectangle_rec(rect,  LIFE_COLOR);
	};

	end_blending_mode();
	end_drawing();
};

export fn main() void = {
	init_window(WINDOW_WIDTH: size, WINDOW_HEIGHT: size, "Breaking Hare");
	defer close_window();
	let quit: bool = false;

	cursor_hide();

	let game = Game {...};
	game_reset(&game);

	const input = Game_Input{...};

	for(!quit) {
		if (window_should_close() || is_key_pressed('Q')) {
			quit  = true;
			continue;
		};

		game_input_reset(&input);
		input.deltaTime = get_frame_time();
		input.elapsedTime = get_time();
		if (is_key_pressed(' ')) {
			input.controller.start = true;
		} else if (is_key_down('D')) {
			input.controller.right  = true;
		} else if (is_key_down('A')) {
			input.controller.left  = true;
		};

		update_and_render(&game, &input);
	};

};
