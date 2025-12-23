#ifndef _BOOT_H
#define _BOOT_H

#include <stddef.h>

#ifndef _STDINT_H
#include <stdint.h>
#endif

#define BOOT_FEATURE_MMAP        (1 << 0)
#define BOOT_FEATURE_FRAMEBUFFER (1 << 1)

enum mmap_entry_type {
    Available,
    Unusable,
    ACPI
};

typedef struct {
    uintptr_t start; 
    size_t pages;
    enum mmap_entry_type type;
} mmap_entry;

typedef struct {
    size_t size;
    mmap_entry* entries;
} mmap;

typedef struct {
    void* addr;
    unsigned int width;
    unsigned int height;
    unsigned int pitch;
} framebuffer;

typedef struct {
    int         features;
    framebuffer fb;
    mmap        mem;
    int         argc;
    char**      argv;
} boot_info;

#endif
