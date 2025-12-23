#include <uefi.h>

int main(int argc, char **argv)
{
    ST->BootServices->SetWatchdogTimer(0, 0, 0, NULL);
    ST->ConOut->ClearScreen(ST->ConOut);
    ST->ConIn->Reset(ST->ConIn, false);

    printf("Booting WyrmOSV2...\n");

    while(1);
    return 0;
}
