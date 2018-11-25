file_count  dw  4

db     "not_exist.exe",0,"      "
dw     90          ;起始扇区
dw     2            ;所占扇区

db     "hello.exe",0,"          "
dw     100          ;起始扇区
dw     2            ;所占扇区

db     "invaders.exe",0,"       "
dw     102          ;起始扇区
dw     8            ;所占扇区

db     "shift_hold.int",0,"     "
dw     110
dw     1

times  4606 -($-$$) db 0
db	55h,0aah