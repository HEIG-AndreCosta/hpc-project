
#include <lvgl.h>
#include <string.h>
#include <unistd.h>

static lv_display_t *sdl_init(int32_t w, int32_t h)
{
	lv_group_set_default(lv_group_create());

	lv_display_t *disp = lv_sdl_window_create(w, h);

	lv_indev_t *mouse = lv_sdl_mouse_create();
	lv_indev_set_group(mouse, lv_group_get_default());
	lv_indev_set_display(mouse, disp);
	lv_display_set_default(disp);

	lv_obj_t *cursor_obj;
	cursor_obj = lv_image_create(lv_screen_active());
	lv_indev_set_cursor(mouse, cursor_obj);

	lv_indev_t *mousewheel = lv_sdl_mousewheel_create();
	lv_indev_set_display(mousewheel, disp);
	lv_indev_set_group(mousewheel, lv_group_get_default());

	lv_indev_t *kb = lv_sdl_keyboard_create();
	lv_indev_set_display(kb, disp);
	lv_indev_set_group(kb, lv_group_get_default());

	return disp;
}
void init_ui(void)
{
	static lv_style_t style;
	lv_style_init(&style);
	lv_font_t *font = lv_tiny_ttf_create_file("A:myriadpro.ttf", 30);
	lv_style_set_text_font(&style, font);
	lv_style_set_text_align(&style, LV_TEXT_ALIGN_CENTER);
	lv_obj_t *label = lv_label_create(lv_screen_active());
	lv_obj_add_style(label, &style, 0);
	lv_label_set_text(
		label,
		"Lorem ipsum dolor sit amet consectetur adipiscing elit."
		"Quisque faucibus ex sapien vitae pellentesque sem placerat."
		"In id cursus mi pretium tellus duis convallis."
		"Tempus leo eu aenean sed diam urna tempor."
		"Pulvinar vivamus fringilla lacus nec metus bibendum egestas."
		"Iaculis massa nisl malesuada lacinia integer nunc posuere."
		"Ut hendrerit semper vel class aptent taciti sociosqu."
		"Ad litora torquent per conubia nostra inceptos himenaeos."
		"Lorem ipsum dolor sit amet consectetur adipiscing elit."
		"Quisque faucibus ex sapien vitae pellentesque sem placerat."
		"In id cursus mi pretium tellus duis convallis."
		"Tempus leo eu aenean sed diam urna tempor."
		"Pulvinar vivamus fringilla lacus nec metus bibendum egestas."
		"Iaculis massa nisl malesuada lacinia integer nunc posuere."
		"Ut hendrerit semper vel class aptent taciti sociosqu."
		"Ad litora torquent per conubia nostra inceptos himenaeos."
		"Lorem ipsum dolor sit amet consectetur adipiscing elit."
		"Quisque faucibus ex sapien vitae pellentesque sem placerat."
		"In id cursus mi pretium tellus duis convallis."
		"Tempus leo eu aenean sed diam urna tempor."
		"Pulvinar vivamus fringilla lacus nec metus bibendum egestas."
		"Iaculis massa nisl malesuada lacinia integer nunc posuere."
		"Ut hendrerit semper vel class aptent taciti sociosqu."
		"Ad litora torquent per conubia nostra inceptos himenaeos."
		"Lorem ipsum dolor sit amet consectetur adipiscing elit."
		"Quisque faucibus ex sapien vitae pellentesque sem placerat."
		"In id cursus mi pretium tellus duis convallis."
		"Tempus leo eu aenean sed diam urna tempor."
		"Pulvinar vivamus fringilla lacus nec metus bibendum egestas."
		"Iaculis massa nisl malesuada lacinia integer nunc posuere."
		"Ut hendrerit semper vel class aptent taciti sociosqu."
		"Ad litora torquent per conubia nostra inceptos himenaeos."
		"Lorem ipsum dolor sit amet consectetur adipiscing elit."
		"Quisque faucibus ex sapien vitae pellentesque sem placerat."
		"In id cursus mi pretium tellus duis convallis."
		"Tempus leo eu aenean sed diam urna tempor."
		"Pulvinar vivamus fringilla lacus nec metus bibendum egestas."
		"Iaculis massa nisl malesuada lacinia integer nunc posuere."
		"Ut hendrerit semper vel class aptent taciti sociosqu."
		"Ad litora torquent per conubia nostra inceptos himenaeos."
		"Lorem ipsum dolor sit amet consectetur adipiscing elit."
		"Quisque faucibus ex sapien vitae pellentesque sem placerat."
		"In id cursus mi pretium tellus duis convallis."
		"Tempus leo eu aenean sed diam urna tempor."
		"Pulvinar vivamus fringilla lacus nec metus bibendum egestas."
		"Iaculis massa nisl malesuada lacinia integer nunc posuere."
		"Ut hendrerit semper vel class aptent taciti sociosqu."
		"Ad litora torquent per conubia nostra inceptos himenaeos.");

	lv_obj_center(label);
	lv_label_set_long_mode(label, LV_LABEL_LONG_SCROLL_CIRCULAR);
	lv_obj_set_width(label, lv_pct(150));

	lv_anim_t anim;
	lv_anim_init(&anim);
	lv_anim_set_var(&anim, label);
	lv_anim_set_exec_cb(&anim, (lv_anim_exec_xcb_t)lv_obj_set_x);
	lv_anim_set_values(&anim, -200, 200);
	lv_anim_set_time(&anim, 3000);
	lv_anim_set_repeat_count(&anim, LV_ANIM_REPEAT_INFINITE);
	lv_anim_set_path_cb(&anim, lv_anim_path_ease_in_out);
	lv_anim_set_playback_time(&anim, 3000);
	lv_anim_start(&anim);
}

int main(int argc, char **argv)
{
	bool render_only = false;
	if (argc > 1) {
		render_only = strcmp(argv[1], "--first-render-only") == 0;
	}

	lv_init();
	sdl_init(860, 540);
	init_ui();

	/* The first refr call will both update the layout and render */
	uint32_t t = lv_tick_get();
	lv_refr_now(NULL);
	LV_LOG_USER("Time for first render (rendering + layout) %u ms\n",
		    lv_tick_elaps(t));
	if (render_only) {
		return 0;
	}
	/* 
	 * By invalidating the current screen, the next call to refr will rerender the whole screen
	 * In this case, the layouts won't change so this will mesure the pure rendering time
	 */
	lv_obj_invalidate(lv_screen_active());

	t = lv_tick_get();
	lv_refr_now(NULL);
	LV_LOG_USER("Time for rendering only (no layout) %u ms\n",
		    lv_tick_elaps(t));

	while (1) {
		const uint32_t sleep_time_ms = lv_timer_handler();
		usleep(sleep_time_ms * 1000);
	}
	return 0;
}
