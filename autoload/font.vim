" "Windows"
"    set gfn=Consolas:h10:cANSI gfw=新宋体:h10:cANSI
"    set gfn=Courier_New:h10:cANSI gfw=新宋体:h10:cANSI
" "Linux"
"    set gfn=Courier\ New\ 10 gfw=文泉驿等宽微米黑\ 10

" command! -nargs=0 MonoFont		call font#Set_mono_font()
" command! -nargs=0 TextFont		call font#Set_text_font()
" command! -bar -count=10 FontSize	call font#FontSize(<count>)
" nnoremap <A-+>			:call font#FontSize_Enlarge()<CR>
" nnoremap <A-->			:call font#FontSize_Reduce()<CR>

"" TODO
" 添加字体风格选择模式——mono、text等等
"" TODO
" 不知道是什么原因，在vim_script内部，你不能readfile(另外一个vim_script文件，
" 而只能使用source或者readfile(一个非.vim后缀的文件……Orz
"
" 已解决！
"
" readfile默认使用text模式读取文件；当文件的第一个字符为'{'，由于某种内部的机
" 制，vim不会读取文件的内容。
"
" 因此，应该显式使用'b'指令。Orz

" NOTE:
" 在编写用户接口函数时——需要的数据，必须从外存中读取——以外存的为主。即，需
" 要保证某些资源已经被正确创建了。
"
" 而内部的函数，则没有必要——因为如果已经在调用内部的函数时候，说明需要的数据已经读取完毕。

" User Interface Functions		{{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function font#Set_mono_font()		" {{{2
    call <SID>GetUserDefineFSets()
    call <SID>ChooseFontScheme('mono')
    call <SID>SetFont()
endfunction

function font#Set_text_font()		" {{{2
    call <SID>GetUserDefineFSets()
    call <SID>ChooseFontScheme('text')
    call <SID>SetFont()
endfunction

" TODO 2010-11-07
" 仿照 colorscheme
" 所有的 font scheme 是保存在一个单独的文件中；在需要读取的时候再读取。
" 读取的时候，记录一个时间戳；当外部文件被修改以后，若遇到读取的命令，则与这个
" 时间戳进行比较，看是否需要重新读取。
" ——即：font scheme以外部文件内容为准。
function font#FontScheme(name)		" {{{2
    call <SID>GetUserDefineFSets()
    call <SID>ChooseFontScheme(a:name)
    call <SID>SetFont()
endfunction

" command -complete=custom,font#FontSchemeNames
" For the "customlist" argument, the function should return the completion
" candidates as a Vim List.  Non-string items in the list are ignored.
function font#FontSchemeNames(ArgLead, CmdLine, CursorPos)	" {{{2
"	ArgLead		the leading portion of the argument currently being
"			completed on
"	CmdLine		the entire command line
"	CursorPos	the cursor position in it (byte index)
    let _table_=<SID>GetUserDefineFSets()
    return join(sort(keys(_table_)), "\n")
endfunction

" 此处在调用的时候，需要提供一个自动补全。
"
" 初始值为当前font scheme的名字。用户可以在此基础上进行修改。
function font#Add_Current_font_setting(name)		" {{{2
    let _table_=<SID>GetUserDefineFSets()
    " Sarrow:2010-11-07
    " no matter has_key(_table_, a:name) or not, just assign!
    " 由于g:guiFont会经常被修改，因此弄一个副本过去。
    let _table_[a:name]=deepcopy(g:guiFont['data'])
endfunction

function font#Manage_UserDefineFSet()		" {{{2
    " 根据内存中的 font scheme 设置更新外部文件中的版本。
    " 然后打开外部文件。
    " 待用户推出该文件的 buffer 后，再次检查——有必要使用autocmd 吗？
    " 好像没有必要。因为，当用户调用接口函数时，每次都会按需要地更新数据。
    " TODO open file ... edit and save and quit...
endfunction

function font#FontSize(num)		" {{{2
    if a:num <= 0
	return
    endif
    " 由于vim用户可能手动修改gfn以及gfw的值，所以
    " 在赋值以及修改操作之前，需要先调用GetFontSetting
    let _fset_=<SID>GetFontSetting()['data']
    let _fset_['size'] = a:num
    call <SID>SetFont()
    call font#FontInfo()
endfunction

function font#FontSize_Enlarge()		" {{{2
    call <SID>FontSizeEnlarge()
    call <SID>SetFont()
    call font#FontInfo()	" 加入此句的本意是显示更改后的Font信息——但是
				" ，由于在修改字体信息后，屏幕会复写。于是，刚
				" 刚写到命令行的信息，马上就丢失了。
endfunction

function font#FontSize_Reduce()		" {{{2
    call <SID>FontSizeReduce()
    call <SID>SetFont()
    call font#FontInfo()
endfunction

function font#Save_font_setting()		" {{{2
    call <SID>GetFontSetting()
    call <SID>WriteFontSetting()
endfunction

" 恢复上次vim运行的font设置。
" 如果外部文件存在，从外部文件中恢复；
" 反之，从默认值恢复。——不用管之前g:guiFont是否存在。
function font#Restore_font_setting()		" {{{2
    let _font_set_fname_=<SID>GetFontSettingFName()
    if filereadable(_font_set_fname_)
	"redir =>> @a
	"echom 'redingfont'
	"redir END
	call <SID>ReadFontSetting()
    else
	let g:guiFont={'data': <SID>Get{util#MySys()}DefaultValue(), 'name': 'default'}
	"echom string(g:guiFont)
    endif
    call <SID>SetFont()
endfunction

" 用一行来显示当前font scheme名字；以及当前gfn与gfw的设置。
function font#FontInfo()		" {{{2
    " Sarrow: 2011-05-06
    silent redraw
    " End:
    let _fset_=<SID>GetFontSetting()['data']

    let _msg_=''
    for i in ['normal', 'wide']
	if has_key(_fset_, i)
	    let _msg_ .= 'gf'.i[0].'='
			\ . iconv(<SID>To{util#MySys()}FontStr(i), g:system_encoding, &encoding).' '
	endif
    endfor
    if strlen(_msg_)
	echom g:guiFont['name'].' '._msg_
    else
	echom 'g:guiFont data error!'
    endif
endfunction

" Utility Interface Functions		{{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function s:Is_Need_Update_FSets_File()	" {{{2
    return !filereadable(<SID>GetUserDefineFSetsFName())
		\ || (exists('g:guiFont_s_timestamp')
		\ && g:guiFont_s_timestamp > getftime(<SID>GetUserDefineFSetsFName()))
endfunction

function s:Is_Need_Update_FSets()	" {{{2
    return !exists('g:guiFont_s') || (filereadable(<SID>GetUserDefineFSetsFName())
		\ && exists('g:guiFont_s_timestamp')
		\ && g:guiFont_s_timestamp < getftime(<SID>GetUserDefineFSetsFName()))
endfunction

" 从外部文件恢复Dictionary类型的font scheme数据。
" 并记录外部文件的时间戳。
" 注意，在修改guiFont_s后，要同时用localtime()更新g:guiFont_s_timestamp，以便
" 比较。
function s:GetUserDefineFSets()		" {{{2
    if <SID>Is_Need_Update_FSets()
	let _lines_=readfile(<SID>GetUserDefineFSetsFName(), 'b')
	let g:guiFont_s={}
	for _line_ in _lines_
	    " TODO 2010-11-08
	    " need safety checking!
	    execute 'let _fset_='. matchstr(_line_, '{[^}]\{-}}')
	    execute 'let _fsch_='. matchstr(_line_, "'.\\{-}'")
	    if <SID>IsFontSettingValid(_fset_) && strlen(_fsch_)
		" do not need deepcopy()
		let g:guiFont_s[_fsch_]=_fset_
	    endif
	endfor
	let g:guiFont_s_timestamp=getftime(<SID>GetUserDefineFSetsFName())
    endif
    " reasign the 'default' value
    let g:guiFont_s['default']=<SID>Get{MySys}DefaultValue()
    return g:guiFont_s
endfunction

function s:ChooseFontScheme(name)		" {{{2
    let _table_=<SID>GetUserDefineFSets()
    if has_key(_table_, a:name)
	" 由于g:guiFont经常被修改，因此保存_table_的副本即可
	let g:guiFont={'data': deepcopy(_table_[a:name]), 'name': a:name}
    endif
endfunction

function s:GetwindowsDefaultValue()		" {{{2
     return {'normal': 'Consolas', 'wide': '新宋体', 'size': 10}
endfunction

function s:GetlinuxDefaultValue()		" {{{2
     "return {'normal': 'Courier New', 'wide': '文泉驿等宽微米黑', 'size': 10}
     return {'normal': 'Courier', 'wide': '文泉驿等宽微米黑', 'size': 10}
endfunction

function s:TowindowsFontStr(style)		" {{{2
    let _fset_=g:guiFont['data']
    return substitute(iconv(_fset_[a:style], &encoding, g:system_encoding), ' ', '_', 'g')
		\ .':h'.string(_fset_['size']).':cANSI'
endfunction

function s:TolinuxFontStr(style)		" {{{2
    let _fset_=g:guiFont['data']
    " return escape(_fset_[a:style], ' ') . '\ ' . string(_fset_['size'])
    return escape(_fset_[a:style] . ' ' . string(_fset_['size']), ' ')
endfunction

function s:SetFont()		" {{{2
    let _fset_=g:guiFont['data']
    for i in ['normal', 'wide']
	if has_key(_fset_, i)
	    execute 'set gf'.i[0].'='. <SID>To{util#MySys()}FontStr(i)
	endif
    endfor
endfunction

function s:FontSizeReduce()		" {{{2
    let _fset_=<SID>GetFontSetting()['data']
    if _fset_['size'] > 1
	let _fset_['size']-=1
    endif
endfunction

function s:FontSizeEnlarge()		" {{{2
    let _fset_=<SID>GetFontSetting()['data']
    let _fset_['size']+=1
endfunction

"" 因为当前的字体风格是频繁变化的；而总的字体主题是相对固定的；
"所以分别用autoload/font_settings和autoload/font_setting来存储以上设置。
function s:GetUserDefineFSetsFName()		" {{{2
    " font_settings 文件中的内容形如：
    " 'name': {'normal': 'Courier New', 'wide': '', 'size': 10}
    if !exists('g:_fontsets_fname_')
	let g:_fontsets_fname_=fnamemodify(globpath(&rtp, 'autoload/font.vim'), ':p:h')
		    \ .'/font_settings'
    endif
    return g:_fontsets_fname_
endfunction

function s:GetFontSettingFName()		" {{{2
    if !exists('g:_font_set_fname_')
	let g:_font_set_fname_=fnamemodify(globpath(&rtp, 'autoload/font.vim'), ':p:h')
		    \ .'/font_setting.' . strpart(util#MySys(), 0, 3)
    endif
    return g:_font_set_fname_
endfunction

function s:IsFontSettingValid(_fset_)		" {{{2
    return type(a:_fset_) == type({}) && (has_key(a:_fset_, 'normal') || has_key(a:_fset_, 'wide'))
		\ && has_key(a:_fset_, 'size')
endfunction

function s:FileData2String(fname)		" {{{2
    let _data_=[]
    if filereadable(a:fname)
	let _data_=readfile(a:fname, 'b')
    endif
    return join(_data_, '')
endfunction

function s:ReadFontSetting()		" {{{2
    let _font_set_fname_=<SID>GetFontSettingFName()
    let _line_=<SID>FileData2String(_font_set_fname_)
    if strlen(_line_) && _line_ =~ '^{.\{-}}$'
	" && _line_ =~ '{\(''.\{-}''\s*:\s*''.\{-}''\s*,\s*\)\+'
	execute 'let _fset_='._line_
	let _fsch_='restore'
    endif
    if !exists('_fset_') || !<SID>IsFontSettingValid(_fset_)
	"echom 'reading file `'._font_set_fname_.'` error!'
	if exists('_fset_')
	    unlet _fset_
	endif
	let _fset_=<SID>Get{util#MySys()}DefaultValue()
	let _fsch_='default'
    endif
    let g:guiFont={'data': _fset_, 'name': _fsch_}
endfunction

function s:FromwindowsFontStr(style, _str)		" {{{2
    let _str=system#ToVimEnc(substitute(a:_str, '_', ' ', 'g'))
    let g:guiFont['data'][a:style]=matchstr(_str, '^[^:]\+')
    let g:guiFont['data']['size']=str2nr(matchstr(_str, ':h\zs\d\+\ze:'))
endfunction

function s:FromlinuxFontStr(style, _str)		" {{{2
    let g:guiFont['data'][a:style]=matchstr(a:_str, '^\zs.\{-}\ze \d\+$')
    let g:guiFont['data']['size']=str2nr(matchstr(a:_str, '\<\d\+$'))
endfunction

" 从内存创建g:guiFont
function s:GetFontSetting()		" {{{2
    if !exists('g:guiFont')
	"echom 'g:guiFont not exists!'
    endif
    let g:guiFont['data']={}
    for i in ['normal', 'wide']
	" Sarrow: 2011-11-10
	" 注意，在 linux 下，为 gfn 、gfw 赋值 的时候，空格需要 被 escape;
	" 但，返回值，是没有 '\' 的。
	let _str=eval('&gf'.i[0])
	if empty(_str)
	    continue
	endif
	call font#FontInfoCachedUpdate(i, _str)
    endfor
    return g:guiFont
endfunction
function font#FontInfoCachedUpdate(style, _str)	"{{{2
    call <SID>From{util#MySys()}FontStr(a:style, a:_str)
    if !has_key(g:guiFont.data, 'normal') && has_key(g:guiFont.data, 'wide')
	let g:guiFont.data['normal'] = g:guiFont.data['wide']
    endif
endfunction
function s:WriteFontSetting()		" {{{2
    let _font_set_fname_=<SID>GetFontSettingFName()

    let _line_=<SID>FileData2String(_font_set_fname_)
    let _data_=g:guiFont['data']
    if strlen(_line_)
	execute 'let _fset_='._line_
	if <SID>IsFontSettingValid(_fset_) && _fset_==_data_
	    return
	endif
    endif
    call writefile([string(_data_)], _font_set_fname_, 'b')
endfunction

function font#font_ui_init()
    " 注意，以下的命令，只有在GUI模式下，才有效！
    " 终端模式下，不能修改字体方面(字型、大小)的设置。
    command! -nargs=0 FontInfo		call font#FontInfo()
    command! -nargs=0 MonoFont		call font#Set_mono_font()
    command! -nargs=0 TextFont		call font#Set_text_font()
    command! -bar -count=10 FontSize	call font#FontSize(<count>)
    command! -nargs=1 -complete=custom,font#FontSchemeNames FontScheme		call font#FontScheme()
    command! -nargs=1 FontAddCurrent	call font#Add_Current_font_setting()
    command! -nargs=0 FontSchemeManage	call font#Manage_UserDefineFSet()
    nnoremap <A-+>			:call font#FontSize_Enlarge()<CR>
    nnoremap <A-->			:call font#FontSize_Reduce()<CR>
    autocmd VimLeavePre * call font#Save_font_setting()

    call font#Restore_font_setting()
endfunction
