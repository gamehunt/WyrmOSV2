#include <uefi.h>
#include <stdbool.h>
#include <boot.h>
#include <elf.h>

boot_info bp;

void squish(mmap* mem)
{
    if (mem->size == 0)
        return;

    size_t write = 0;

    for (size_t read = 1; read < mem->size; ++read) {
        mmap_entry *cur  = &mem->entries[read];
        mmap_entry *last = &mem->entries[write];

        if (last->type == cur->type &&
            last->start + last->pages * 0x1000 == cur->start) {
            last->pages += cur->pages;
        } else {
            ++write;
            mem->entries[write] = *cur;
        }
    }

    mem->size = write + 1;
    mem->entries = realloc(mem->entries, mem->size * sizeof(mmap_entry));
}

int fill_memory_map() {
    efi_memory_descriptor_t *memory_map = NULL, *mement;
    uintn_t memory_map_size=0, map_key=0, desc_size=0;
    enum mmap_entry_type types[] = {
        Unusable,
        Available,
        Available,
        Available,
        Available,
        Unusable,
        Unusable,
        Available,
        Unusable,
        ACPI,
        Unusable,
        Unusable,
        Unusable,
        Unusable,
    };

    efi_status_t status;

    status = BS->GetMemoryMap(&memory_map_size, NULL, &map_key, &desc_size, NULL);
    if(status != EFI_BUFFER_TOO_SMALL || !memory_map_size) goto err;
    
    memory_map_size += 4 * desc_size;
    memory_map = (efi_memory_descriptor_t*) malloc(memory_map_size);
    if(!memory_map) {
        fprintf(stderr, "unable to allocate memory\n");
        return 0;
    }

    status = BS->GetMemoryMap(&memory_map_size, memory_map, &map_key, &desc_size, NULL);
    if(EFI_ERROR(status)) {
err:    fprintf(stderr, "Unable to get memory map\n");
        return 0;
    }

    int entry_amount = memory_map_size / desc_size;
    bp.mem.size = entry_amount;
    bp.mem.entries = malloc(sizeof(mmap_entry) * entry_amount);

    const char* names[] = {
        "Available",
        "Unavailable",
        "ACPI" 
    };

    int i = 0;
    for(mement = memory_map; (uint8_t*)mement < (uint8_t*)memory_map + memory_map_size;
        mement = NextMemoryDescriptor(mement, desc_size)) {
        bp.mem.entries[i].start = mement->PhysicalStart;
        bp.mem.entries[i].pages = mement->NumberOfPages;
        bp.mem.entries[i].type  = types[mement->Type];
        i++;
    }
    free(memory_map);

    squish(&bp.mem);

    printf("MMAP entries: %d\n", bp.mem.size);
    printf("ADDRESS          PAGES      TYPE\n");
    for(int i = 0; i < bp.mem.size; i++) {
        printf("%016x %10d %s\n", bp.mem.entries[i].start, bp.mem.entries[i].pages, names[bp.mem.entries[i].type]);
    }

    return 1;
}

int setup_framebuffer() {
    return 1;
}

uintptr_t load_kernel(const char* path) {
    FILE* f = fopen(path, "r"); 
    if(!f) {
        return 0;
    }

    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    fseek(f, 0, SEEK_SET);
    void * buff = malloc(size + 1);
    if(!buff) {
        fprintf(stderr, "unable to allocate memory\n");
        return 0;
    }

    fread(buff, size, 1, f);
    fclose(f);

    Elf64_Ehdr* elf = (Elf64_Ehdr *)buff;
    Elf64_Phdr* phdr = NULL;
    int i = 0;
    uintptr_t entry = 0;
    if( elf->e_ident.magic == ELF_MAGIC&&    /* magic match? */
        elf->e_ident.class == ELF_CLASS64 &&     /* 64 bit? */
        elf->e_ident.data == ELFDATA2LSB &&     /* LSB? */
        elf->e_type == ET_EXEC &&                   /* executable object? */
        // elf->e_machine == EM_MACH &&                /* architecture match? */
        elf->e_phnum > 0) {                         /* has program headers? */
            /* load segments */
            for(phdr = (Elf64_Phdr *)(buff + elf->e_phoff), i = 0;
                i < elf->e_phnum;
                i++, phdr = (Elf64_Phdr *)((uint8_t *)phdr + elf->e_phentsize)) {
                    if(phdr->p_type == PT_LOAD) {
                        memcpy((void*)phdr->p_vaddr, buff + phdr->p_offset, phdr->p_filesz);
                        memset((void*)(phdr->p_vaddr + phdr->p_filesz), 0, phdr->p_memsz - phdr->p_filesz);
                    }
                }
            entry = elf->e_entry;
    } else {
        fprintf(stderr, "not a valid ELF executable for this architecture\n");
        return 0;
    }
    /* free resources */
    free(buff);
    return entry;
}

int main(int argc, char **argv)
{
    ST->BootServices->SetWatchdogTimer(0, 0, 0, NULL);
    ST->ConOut->ClearScreen(ST->ConOut);
    ST->ConIn->Reset(ST->ConIn, false);

    memset(&bp, 0, sizeof(boot_info));

    printf("Booting WyrmOSV2...\n");

    int has_mmap = fill_memory_map();
    if (has_mmap) {
        bp.features |= BOOT_FEATURE_MMAP;
    }

    int has_fb = setup_framebuffer();
    if (has_fb) {
        bp.features |= BOOT_FEATURE_FRAMEBUFFER;
    }

    if(argc > 1) {
        bp.argc = argc - 1;
        bp.argv = (char**)malloc(argc * sizeof(char*));
        if(bp.argv) {
            int i = 0;
            for(i = 0; i < bp.argc; i++)
                if((bp.argv[i] = (char*)malloc(strlen(argv[i + 1]) + 1)))
                    strcpy(bp.argv[i], argv[i + 1]);
            bp.argv[i] = NULL;
        }
    }

    uintptr_t kernel_entry = load_kernel("\\wyrm.bin");

    if(!kernel_entry) {
        fprintf(stderr, "Failed to load kernel");
        return 0;
    }

    printf("Loaded kernel, moving on...");
    ST->ConOut->ClearScreen(ST->ConOut);

    if(exit_bs()) {
        fprintf(stderr, "Failed to exit boot services.\n");
        return 0;
    }

    (*((void(* __attribute__((sysv_abi)))(boot_info *))(kernel_entry)))(&bp);

    while(1);
    return 0;
}
