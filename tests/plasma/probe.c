#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wayland-client.h>
#include "background-effect-client.h"

static struct wl_compositor *compositor;
static struct ext_background_effect_manager_v1 *manager;
static unsigned fixes_version;

static void global(void *data, struct wl_registry *registry, uint32_t name,
                   const char *interface, uint32_t version)
{
    (void)data;
    if (!strcmp(interface, "wl_compositor"))
        compositor = wl_registry_bind(registry, name, &wl_compositor_interface,
                                      version < 4 ? version : 4);
    else if (!strcmp(interface, "ext_background_effect_manager_v1"))
        manager = wl_registry_bind(registry, name,
                  &ext_background_effect_manager_v1_interface, 1);
    else if (!strcmp(interface, "wl_fixes"))
        fixes_version = version;
}

static void removed(void *data, struct wl_registry *registry, uint32_t name)
{
    (void)data;
    (void)registry;
    (void)name;
}

int main(void)
{
    const char *expected = getenv("PROBE_EXPECT_FIXES_VERSION");
    struct wl_display *display = wl_display_connect(NULL);
    if (!display) return 2;
    struct wl_registry *registry = wl_display_get_registry(display);
    static const struct wl_registry_listener listener = {global, removed};
    wl_registry_add_listener(registry, &listener, NULL);
    if (wl_display_roundtrip(display) < 0 || !compositor || !manager) return 3;
    printf("wl_fixes version=%u\n", fixes_version);
    fflush(stdout);
    if (expected && *expected && fixes_version != (unsigned)atoi(expected)) return 4;

    for (int i = 0; i < 200; ++i) {
        struct wl_surface *surface = wl_compositor_create_surface(compositor);
        struct ext_background_effect_surface_v1 *effect =
            ext_background_effect_manager_v1_get_background_effect(manager, surface);
        struct wl_region *region = wl_compositor_create_region(compositor);
        wl_region_add(region, 0, 0, 20, 20);
        ext_background_effect_surface_v1_set_blur_region(effect, region);
        wl_region_destroy(region);
        wl_surface_commit(surface);
        if (wl_display_roundtrip(display) < 0) return 5;

        wl_surface_destroy(surface);
        /* Reproduce KDE 522547 without touching the real desktop. */
        ext_background_effect_surface_v1_set_blur_region(effect, NULL);
        if (wl_display_roundtrip(display) < 0) {
            fprintf(stderr, "stale blur disconnected the client, iteration=%d\n", i);
            wl_display_disconnect(display);
            return 10;
        }
        ext_background_effect_surface_v1_destroy(effect);
    }
    if (wl_display_roundtrip(display) < 0) return 6;
    puts("PASS: 200 valid/stale blur cycles; Wayland connection survived");
    ext_background_effect_manager_v1_destroy(manager);
    wl_compositor_destroy(compositor);
    wl_registry_destroy(registry);
    wl_display_disconnect(display);
    return 0;
}
