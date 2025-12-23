#!/bin/bash
set -eou pipefail

make -C boot --always-make --dry-run \
  | grep -wE 'gcc|g\+\+' \
  | grep -w '\-c' \
  | jq -Rn '
    [inputs
     | select(length > 0)
     | {
         directory: "__ABSPATH__/boot",
         command: .,
         file: (match(" [^ ]+$").string[1:])
       }
    ]
  ' > compile_commands.bootloader.json

make system-except-bootloader DONT_EXPORT=1 --always-make --dry-run \
  | grep -wE 'gcc|g\+\+' \
  | grep -w '\-c' \
  | jq -Rn '
    [inputs
     | select(length > 0)
     | {
         directory: "__ABSPATH__",
         command: .,
         file: (match(" [^ ]+$").string[1:])
       }
    ]
  ' > compile_commands.system.json

jq -s 'flatten' compile_commands.bootloader.json compile_commands.system.json > compile_commands.json
sed -i "s|__ABSPATH__|$(pwd)|g" compile_commands.json
