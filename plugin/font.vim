"" font.vim
" user interface

" if MySys() == "windows"
"     set gfn=Consolas:h10:cANSI gfw=新宋体:h10:cANSI
" "    set gfn=Courier_New:h10:cANSI gfw=新宋体:h10:cANSI
" elseif MySys() == "linux"
"     set gfn=Courier\ New\ 10
" endif

" FIXME 2010-11-11
" from autoload/font.vim		change font setting 
autocmd GUIEnter * call font#font_ui_init()
"autocmd GUIEnter * call font#Restore_font_setting()

" | call font#Save_font_settings()
