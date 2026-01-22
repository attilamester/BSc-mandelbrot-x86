#include <SDL2/SDL.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

static SDL_Window *g_window = NULL;
static SDL_Renderer *g_renderer = NULL;
static SDL_Texture *g_texture = NULL;
static uint32_t *g_pixels = NULL;
static int g_w = 0;
static int g_h = 0;

int gfx_init_c(int w, int h, int fullscreen, const char *title) {
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
        return 0;
    }

    g_w = w;
    g_h = h;

    Uint32 flags = fullscreen ? SDL_WINDOW_FULLSCREEN : 0;
    g_window = SDL_CreateWindow(
        title ? title : "Mandelbrot",
        SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED,
        w,
        h,
        flags
    );
    if (!g_window) {
        fprintf(stderr, "SDL_CreateWindow failed: %s\n", SDL_GetError());
        return 0;
    }

    g_renderer = SDL_CreateRenderer(g_window, -1, SDL_RENDERER_ACCELERATED);
    if (!g_renderer) {
        fprintf(stderr, "SDL_CreateRenderer failed: %s\n", SDL_GetError());
        return 0;
    }

    g_texture = SDL_CreateTexture(
        g_renderer,
        SDL_PIXELFORMAT_BGRA32,
        SDL_TEXTUREACCESS_STREAMING,
        w,
        h
    );
    if (!g_texture) {
        fprintf(stderr, "SDL_CreateTexture failed: %s\n", SDL_GetError());
        return 0;
    }

    g_pixels = (uint32_t *)malloc((size_t)w * (size_t)h * 4u);
    if (!g_pixels) {
        fprintf(stderr, "malloc framebuffer failed\n");
        return 0;
    }

    return 1;
}

void gfx_destroy_c(void) {
    if (g_pixels) {
        free(g_pixels);
        g_pixels = NULL;
    }
    if (g_texture) {
        SDL_DestroyTexture(g_texture);
        g_texture = NULL;
    }
    if (g_renderer) {
        SDL_DestroyRenderer(g_renderer);
        g_renderer = NULL;
    }
    if (g_window) {
        SDL_DestroyWindow(g_window);
        g_window = NULL;
    }
    SDL_Quit();
}

void *gfx_map_c(void) {
    return g_pixels;
}

void gfx_unmap_c(void) {
}

void gfx_draw_c(void) {
    if (!g_pixels) {
        return;
    }
    SDL_UpdateTexture(g_texture, NULL, g_pixels, g_w * 4);
    SDL_RenderClear(g_renderer);
    SDL_RenderCopy(g_renderer, g_texture, NULL, NULL);
    SDL_RenderPresent(g_renderer);
}

int gfx_getevent_c(void) {
    SDL_Event e;
    while (SDL_PollEvent(&e)) {
        if (e.type == SDL_QUIT) {
            return 23;
        }

        if (e.type == SDL_KEYDOWN || e.type == SDL_KEYUP) {
            int down = (e.type == SDL_KEYDOWN);
            SDL_Keycode key = e.key.keysym.sym;
            if (key == SDLK_ESCAPE) {
                return down ? 27 : -27;
            }
            if (key >= SDLK_a && key <= SDLK_z) {
                int ch = (int)key;
                return down ? ch : -ch;
            }
            continue;
        }

        if (e.type == SDL_MOUSEBUTTONDOWN || e.type == SDL_MOUSEBUTTONUP) {
            int down = (e.type == SDL_MOUSEBUTTONDOWN);
            int btn = e.button.button;
            return down ? btn : -btn;
        }

        if (e.type == SDL_MOUSEWHEEL) {
            if (e.wheel.y > 0) {
                return 4;
            }
            if (e.wheel.y < 0) {
                return 5;
            }
            continue;
        }

        if (e.type == SDL_MOUSEMOTION) {
            continue;
        }
    }

    return 0;
}

void gfx_getmouse_c(int *x, int *y) {
    SDL_PumpEvents();
    SDL_GetMouseState(x, y);
}

void gfx_showcursor_c(int show) {
    SDL_ShowCursor(show ? SDL_ENABLE : SDL_DISABLE);
}
