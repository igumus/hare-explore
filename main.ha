use raylib::*;

export fn main() void = {
	const width: f32 = 800.0;
	const height: f32 = 600.0;
	init_window(width: size, height: size, "Hello from Hare");
	defer close_window();

	const red_color = Color {
		r= 255,
		g= 0,
		b= 0,
		a= 255,
	};
	const background_color = get_color(0x181818FF);

	let playerX: f32 = 0.0;
	let playerY: f32 = 0.0;
	let playerW: f32 = 100.0;
	const deltaX: f32 = 200.0;

	for(!window_should_close()) {
		begin_drawing();
		const frame_time: f32 = get_frame_time();

		if (is_key_down('D')) {
			playerX = (playerX + deltaX * frame_time);
		} else if (is_key_down('A')) {
			playerX = (playerX - deltaX * frame_time);
		} else if (is_key_down('W')) {
			playerY = (playerY - deltaX * frame_time);
		} else if (is_key_down('S')) {
			playerY = (playerY + deltaX * frame_time);
		};

		if (playerX < 0.0 || playerX > width) playerX = 0.0;
		if (playerY < 0.0 || playerY > height) playerY = 0.0;

		clear_background(background_color);
		draw_rectangle(playerX :int , playerY :int, playerW: int , playerW: int, red_color);
		end_drawing();
	};

};
