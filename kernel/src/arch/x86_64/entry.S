.code32

.extern kmain
.type kmain, @function

.global start
.type start, @function

start:
    call kmain 

    cli
    hlt

