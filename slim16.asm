file_count  dw (end-$)/24

db     "not_exist.exe",0,"      "
dw     90          ;起始扇区
dw     2            ;所占扇区

db     "hello.exe",0,"          "
dw     100          ;起始扇区
dw     2            ;所占扇区

db     "invaders.exe",0,"       "
dw     102          ;起始扇区
dw     8            ;所占扇区

db     "int_21_handler",0,"     "
dw     110
dw     1

db     "hacker_typer.exe",0,"   "
dw     111
dw     2

db     "hello2.exe",0,"         "
dw     113
dw     1

db     "int_01_handler",0,"     "
dw     114          ;起始扇区
dw     2            ;所占扇区

end times  4606 -($-$$) db 0
db	55h,0aah