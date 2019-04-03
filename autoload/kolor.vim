" ============================================================================
" FILE: kolor.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" Koturn's color utility.
" }}}
" ============================================================================
let s:save_cpo = &cpo
set cpo&vim

 " {{{ Constants
let s:pi = acos(-1)
let s:ccvalues = [0x00, 0x5F, 0x87, 0xAF, 0xD7, 0xFF]
let s:base16_values = [
      \ [0x00, 0x00, 0x00],
      \ [0xCD, 0x00, 0x00],
      \ [0x00, 0xCD, 0x00],
      \ [0xCD, 0xCD, 0x00],
      \ [0x00, 0x00, 0xEE],
      \ [0xCD, 0x00, 0xCD],
      \ [0x00, 0xCD, 0xCD],
      \ [0xE5, 0xE5, 0xE5],
      \ [0x7F, 0x7F, 0x7F],
      \ [0xFF, 0x00, 0x00],
      \ [0x00, 0xFF, 0x00],
      \ [0xFF, 0xFF, 0x00],
      \ [0x5C, 0x5C, 0xFF],
      \ [0xFF, 0x00, 0xFF],
      \ [0x00, 0xFF, 0xFF],
      \ [0xFF, 0xFF, 0xFF]]
let s:header_lines = [
      \ "if !has('vim_starting')",
      \ '  hi clear',
      \ 'endif',
      \ "if exists('syntax_on')",
      \ '  syntax reset',
      \ 'endif',
      \ "let g:colors_name = expand('<sfile>:t:r')",
      \ '',
      \ "let s:gui_running = has('gui_running')",
      \ "let s:true_colors = has('termguicolors') && &termguicolors",
      \ ''
      \]
let s:attrkey_attr_dict = {
      \ 'bold': 'bold',
      \ 'underline': 'underline',
      \ 'undercurl': 'undercurl',
      \ 'strike': 'strikethrough',
      \ 'reverse': 'reverse',
      \ 'italic': 'italic',
      \ 'standout': 'standout',
      \}
let s:t_number = type(0)
let s:t_list = type([])
let s:t_string = type('')
" }}}

function! kolor#palette256_to_rgb(esc) abort " {{{
  return s:palette256_to_rgb(a:esc)
endfunction " }}}

function! kolor#rgb_to_palette256(...) abort " {{{
  return call('s:rgb_to_palette256', call('s:to_rgb_list', a:000))
endfunction " }}}

function! kolor#show_palette256() abort " {{{
  let palette = s:build_palette256()
  for i in map(range(0, 31), 'v:val * 8')
    for [r, g, b, idx] in map(map(range(0, 7), 'v:val + i'), '[palette[v:val][0], palette[v:val][1], palette[v:val][2], v:val]')
      execute printf('highlight! KolorPalette256Tmp ctermfg=%d ctermbg=NONE guifg=#%02x%02x%02x guibg=NONE', idx, r, g, b)
      echohl KolorPalette256Tmp
      echon printf('%4d', idx)
      execute printf('highlight! KolorPalette256Tmp ctermfg=NONE ctermbg=%d guifg=NONE guibg=#%02x%02x%02x', idx, r, g, b)
      echohl KolorPalette256Tmp
      echon '    '
    endfor
    echo ''
    echohl None
  endfor
  highlight! clear KolorPalette256Tmp
  echohl None
endfunction " }}}

function! kolor#rgb_to_yuv(...) abort " {{{
  return call('s:rgb_to_yuv', call('s:to_rgb_list', a:000))
endfunction " }}}

function! kolor#rgb_to_hsv(...) abort " {{{
  return call('s:rgb_to_hsv', call('s:to_rgb_list', a:000))
endfunction " }}}

function! kolor#rgb_to_hsl(...) abort " {{{
  return call('s:rgb_to_hsl', call('s:to_rgb_list', a:000))
endfunction " }}}

function! kolor#rgb_to_hsi(...) abort " {{{
  return call('s:rgb_to_hsi', call('s:to_rgb_list', a:000))
endfunction " }}}

function! kolor#yuv_to_rgb(...) abort " {{{
  return call('s:yuv_to_rgb', call('s:to_yuv_list', a:000))
endfunction " }}}

function! kolor#hsv_to_rgb(...) abort " {{{
  return call('s:hsv_to_rgb', call('s:to_hsx_list', a:000))
endfunction " }}}

function! kolor#hsl_to_rgb(...) abort " {{{
  return call('s:hsl_to_rgb', call('s:to_hsx_list', a:000))
endfunction " }}}

function! kolor#hsi_to_rgb(...) abort " {{{
  return call('s:hsi_to_rgb', call('s:to_hsx_list', a:000))
endfunction " }}}

function! kolor#generate_colordef_from_jsonfile(filepath) abort " {{{
  return kolor#generate_colordef(json_decode(join(readfile(expand(a:filepath)), '')))
endfunction " }}}

function! kolor#generate_colorscheme_from_jsonfile(dstfile, filepath) abort " {{{
  call writefile(
        \ s:generate_colorscheme_lines(kolor#generate_colordef(json_decode(join(readfile(expand(a:filepath)), '')))),
        \ a:dstfile)
endfunction " }}}

function! kolor#export_current_colorscheme_to_jsonfile(filename) " {{{
  call writefile([json_encode(s:extract_current_highlight())], a:filename)
endfunction " }}}


function! s:generate_colorscheme_lines(colordef) abort " {{{
  if has_key(a:colordef, 'dark')
    let dark_theme_lines = s:generate_colorscheme_body_lines(a:colordef.dark)
  endif
  if has_key(a:colordef, 'light')
    let light_theme_lines = s:generate_colorscheme_body_lines(a:colordef.light)
  endif

  if exists('dark_theme_lines') && exists('light_theme_lines')
    let header_lines = copy(s:header_lines)
    let body_lines = ["if &background ==# 'dark' \" {{{ (Dark theme)"]
    call extend(body_lines, map(dark_theme_lines, "'  ' . v:val"))
    call extend(body_lines, ['" }}}', "else \" {{{ (Light theme)"])
    call extend(body_lines, map(light_theme_lines, "'  ' . v:val"))
    call add(body_lines, 'endif " }}}')
  elseif exists('dark_theme_lines')
    let header_lines = extend(s:generate_set_bg_lines('dark'), copy(s:header_lines))
    let body_lines = dark_theme_lines
  elseif exists('light_theme_lines')
    let header_lines = extend(s:generate_set_bg_lines('light'), copy(s:header_lines))
    let body_lines = light_theme_lines
  else
    throw '[vim-kolor] Cannot find theme neither "dark" or "light"'
  endif

  return extend(header_lines, body_lines)
endfunction " }}}

function! s:generate_set_bg_lines(bg) abort " {{{
  return [
        \ "if &background !=# '" . a:bg . "'",
        \ '  set background=' . a:bg,
        \ 'endif'
        \]
endfunction " }}}

function! s:generate_colorscheme_body_lines(theme_colordef) abort " {{{
  let lines = has_key(a:theme_colordef, 'Normal') ? [a:theme_colordef.Normal.def] : []
  if !empty(lines)
    call remove(a:theme_colordef, 'Normal')
  endif
  for kind in ['def', 'link']
    call extend(lines, map(filter(values(a:theme_colordef), "v:val.kind ==# kind"), 'v:val.def'))
    call add(lines, '')
  endfor
  if has_key(a:theme_colordef, '*Terminal')
    let term_color_dict = a:theme_colordef['*Terminal'].def
    call add(lines, 'let s:terminal_ansi_colors = [' . join(map(term_color_dict.gui, 'string(v:val)'), ', ') . ']')
    call extend(lines, [
          \ "if has('nvim') \" {{{ Terminal colors",
          \ '  let s:idx = 0',
          \ '  if s:gui_running || s:true_colors',
          \ '    for color in s:terminal_ansi_colors',
          \ '      let g:terminal_color_{s:idx} = color',
          \ '      let s:idx += 1',
          \ '    endfor',
          \ '  else',
          \ '    for color in [' . join(term_color_dict.cui, ', ') . ']',
          \ '      let g:terminal_color_{s:idx} = color',
          \ '      let s:idx += 1',
          \ '    endfor',
          \ '  endif',
          \ '  unlet s:idx',
          \ "elseif (s:gui_running || s:true_colors) && exists('*term_setansicolors')",
          \ '  let g:terminal_ansi_colors = s:terminal_ansi_colors',
          \ 'endif',
          \ 'unlet s:terminal_ansi_colors " }}}"'
          \])
  endif
  return lines
endfunction " }}}

function! kolor#generate_colordef(colordef_dict) abort " {{{
  let palette = map(s:build_palette256(), 'printf("#%02x%02x%02x", v:val[0], v:val[1], v:val[2])')
  let colordef = {}
  for theme in filter(['dark', 'light'], 'has_key(a:colordef_dict, v:val)')
    let colordef[theme] = map(copy(a:colordef_dict[theme]), 's:generate_hldef_dict(v:key, s:correct_hldef(v:val, palette))')
  endfor
  return colordef
endfunction " }}}

function! kolor#echo(msg, fg, ...) abort " {{{
  execute s:generate_hldef_string('KolorEchoTmp', s:correct_hldef({
        \ 'guifg': s:to_rgb_string(a:fg),
        \ 'guibg': a:0 > 0 ? s:to_rgb_string(a:1) : '#000000'
        \}, s:build_palette256()))
  echohl KolorEchoTmp
  echo a:msg
  echohl None
endfunction " }}}

function! kolor#echonr(msg, fg, ...) abort " {{{
  execute s:generate_hldef_string('KolorEchoTmp', s:correct_hldef({
        \ 'ctermfg': a:fg,
        \ 'ctermbg': a:0 > 0 ? a:1 : 0
        \}, s:build_palette256()))
  echohl KolorEchoTmp
  echo a:msg
  echohl None
endfunction " }}}


function! s:to_rgb_list(...) abort " {{{
  if a:0 == 1
    if type(a:1) == s:t_number
      return map([a:1 / 65536, a:1 / 256, a:1], 'v:val % 256')
    elseif type(a:1) == s:t_list
      return [a:1[0], a:1[1], a:1[2]]
    elseif type(a:1) == s:t_string
      let str = a:1[0] ==# '#' ? a:1[1 :] : a:1
      if match(str, '\X') != -1
        throw '[vim-kolor] Invalid RGB string, detect invalid character: ' . str
      endif
      let strlen = len(str)
      if strlen != 3 && strlen != 6
        throw '[vim-kolor] Invalid RGB string, RGB string length must be three or six in hex form: ' . str
      endif
      return strlen == 3 ? map([str[0], str[1], str[2]], 'str2nr(v:val . v:val, 16)') : map([str[: 1], str[2 : 3], str[4 : ]], 'str2nr(v:val, 16)')
    else
      throw '[vim-kolor] Invalid argument type, first argument must be a integer, list or color string in case of single argument calling'
    endif
  elseif a:0 == 3
    return [a:1, a:2, a:3]
  else
    throw '[vim-kolor] Invalid argument, argument must be one (list or string) or three'
  endif
endfunction " }}}

function! s:to_rgb_string(...) abort " {{{
  return call('printf', extend(['#%02x%02x%02x'], call('s:to_rgb_list', a:000)))
endfunction " }}}

function! s:to_yuv_list(...) abort " {{{
  if a:0 == 1
    if type(a:1) == s:t_list
      return [a:1[0], a:1[1], a:1[2]]
    else
      throw '[vim-kolor] Invalid argument type, first argument must be a list in case of single argument calling'
    endif
  elseif a:0 == 3
    return [a:1, a:2, a:3]
  else
    throw '[vim-kolor] Invalid argument, argument must be one (list or string) or three'
  endif
endfunction " }}}

function! s:to_hsx_list(...) abort " {{{
  if a:0 == 1 && type(a:1) == s:t_list
    let hsx = a:1
  elseif a:0 == 3
    let hsx = a:000
  else
    throw '[vim-kolor] Invalid HS* arguments, HS* arguments must be three arguments or a list which has three elements: ' . string(a:000)
  endif
  let hue = hsx[0]
  if hue < 0 || hue > 360.0
    throw '[vim-kolor] Invalid hue value: ' . string(hue) . '. Hue value must be 0.0 ~ 360.0'
  endif
  return hsx
endfunction " }}}

function! s:rgb_to_palette256(r, g, b) abort " {{{
  let [diff, index] = [pow(0xff, 2.0) * 3, 0]
  for [r, g, b, i] in map(range(0, 255), 'add(s:palette256_to_rgb(v:val), v:val)')
    let d = pow(r - a:r, 2.0) + pow(g - a:g, 2.0) + pow(b - a:b, 2.0)
    if d < diff
      let [diff, index] = [d, i]
    endif
  endfor
  return index
endfunction " }}}

function! s:rgb_to_yuv(r, g, b) abort " {{{
  return map([
        \ 0.299 * a:r + 0.587 * a:g + 0.114 * a:b,
        \ -0.169 * a:r - 0.331 * a:g + 0.500 * a:b,
        \ 0.500 * a:r - 0.419 * a:g - 0.081 * a:b
        \], 'float2nr(round(v:val))')
endfunction " }}}

function! s:rgb_to_hsv(r, g, b) abort " {{{
  let [r, g, b, rgbmin, rgbmax] = s:normalize_rgb(a:r, a:g, a:b)
  if rgbmin == rgbmax
    return [0.0, 0.0, rgbmax]
  endif
  let d = rgbmax - rgbmin
  let h = (rgbmax == r ? (g - b) / d
        \ : rgbmax == g ? (b - r) / d + 2.0
        \ : (r - g) / d + 4.0) * 60.0
  return [h < 0.0 ? h + 360.0 : h, d / rgbmax, rgbmax]
endfunction " }}}

function! s:rgb_to_hsl(r, g, b) abort " {{{
  let [r, g, b, rgbmin, rgbmax] = s:normalize_rgb(a:r, a:g, a:b)
  let l = (rgbmin + rgbmax) / 2.0
  if rgbmin == rgbmax
    return [0.0, 0.0, l]
  endif
  let d = rgbmax - rgbmin
  let h = (rgbmax == r ? (g - b) / d
        \ : rgbmax == g ? (b - r) / d + 2.0
        \ : (r - g) / d + 4.0) * 60.0
  return [
        \ h < 0.0 ? h + 360.0 : h,
        \ l < 0.5 ? d / (rgbmin + rgbmax) : d / (2.0 - rgbmin - rgbmax),
        \ l
        \]
endfunction " }}}

function! s:rgb_to_hsi(r, g, b) abort " {{{
  let [r, g, b, rgbmin, rgbmax] = map([a:r, a:g, a:b, min([a:r, a:g, a:b]), max([a:r, a:g, a:b])], 'v:val / 255.0')
  let i = (r + g + b) / 3.0
  if rgbmin == rgbmax
    return [0.0, 0.0, i]
  endif
  let d = rgbmax - rgbmin
  let h = (rgbmax == r ? (g - b) / d
        \ : rgbmax == g ? (b - r) / d + 2.0
        \ : (r - g) / d + 4.0) * 60.0
  return [h < 0.0 ? h + 360.0 : h, 1.0 - rgbmin / i, i]
endfunction " }}}

function! s:normalize_rgb(r, g, b) abort " {{{
  return map([a:r, a:g, a:b, min([a:r, a:g, a:b]), max([a:r, a:g, a:b])], 'v:val / 255.0')
endfunction " }}}

function! s:yuv_to_rgb(y, u, v) abort " {{{
  return map([
        \ a:y + 1.402 * a:v,
        \ a:y - 0.344 * a:u - 0.714 * a:v,
        \ a:y + 1.772 * a:u
        \], 'float2nr(round(v:val))')
endfunction " }}}

function! s:hsv_to_rgb(h, s, v) abort " {{{
  if a:s == 0
    return map(repeat([a:v], 3), 'float2nr(round(v:val * 255.0))')
  endif
  let dh = a:h / 60.0
  let i = float2nr(dh)
  let f = dh - i
  let [p, q] = [a:v * (1.0 - a:s), a:v * (1.0 - (i % 2 == 0 ? (1.0 - f) : f) * a:s)]
  return map(i == 0 ? [a:v, q, p]
        \ : i == 1 ? [q, a:v, p]
        \ : i == 2 ? [p, a:v, q]
        \ : i == 3 ? [p, q, a:v]
        \ : i == 4 ? [q, p, a:v]
        \ : [a:v, p, q], 'float2nr(round(v:val * 255.0))')
endfunction " }}}

function! s:hsl_to_rgb(h, s, l) abort " {{{
  if a:s == 0
    return map(repeat([a:l], 3), 'float2nr(round(v:val * 255.0))')
  endif
  let dh = a:h / 60.0
  let i = float2nr(dh)
  let c = 2.0 * a:s * (a:l < 0.5 ? a:l : (1.0 - a:l))
  let m = a:l - c / 2.0
  let [p, q] = [c + m, a:l + (i % 2 == 0 ? c : -c) * (dh - i - 0.5)]
  return map(i == 0 ? [p, q, m]
        \ : i == 1 ? [q, p, m]
        \ : i == 2 ? [m, p, q]
        \ : i == 3 ? [m, q, p]
        \ : i == 4 ? [q, m, p]
        \ : [p, m, q], 'float2nr(round(v:val * 255.0))')
endfunction " }}}

function! s:hsi_to_rgb(h, s, i) abort " {{{
  let [p, si] = [s:pi / 180.0, a:s * a:i]
  if a:h < 120.0
    let [r, b] = [a:i + si * cos(p * a:h) / cos(p * (60.0 - a:h)), a:i - si]
    return map([r, 3.0 * a:i - r - b, b], 'float2nr(round(v:val * 255.0))')
  elseif a:h < 240.0
    let [r, g] = [a:i - si, a:i + si * cos(p * (a:h - 120.0)) / cos(p * (180.0 - a:h))]
    return map([r, g, 3.0 * a:i - r - g], 'float2nr(round(v:val * 255.0))')
  else
    let [g, b] = [a:i - si, a:i + si * cos(p * (a:h - 240.0)) / cos(p * (300.0 - a:h))]
    return map([3.0 * a:i - g - b, g, b], 'float2nr(round(v:val * 255.0))')
  endif
endfunction " }}}

function! s:correct_hldef(hldef, palette) abort " {{{
  let hldef = a:hldef
  if !has_key(hldef, 'ctermfg') && has_key(hldef, 'guifg')
    let hldef.ctermfg = s:to_term_color(hldef.guifg)
  endif
  if !has_key(hldef, 'ctermbg') && has_key(hldef, 'guibg')
    let hldef.ctermbg = s:to_term_color(hldef.guibg)
  endif
  if !has_key(hldef, 'guifg') && has_key(hldef, 'ctermfg')
    let hldef.guifg = s:to_gui_color(a:palette[str2nr(hldef.ctermfg)])
  endif
  if !has_key(hldef, 'guibg') && has_key(hldef, 'ctermbg')
    let hldef.guibg = s:to_gui_color(a:palette[str2nr(hldef.ctermbg)])
  endif
  if has_key(hldef, 'attr')
    let hldef.cterm = extend(s:get_attr(hldef, 'cterm'), s:get_attr(hldef, 'attr'))
    let hldef.gui = extend(s:get_attr(hldef, 'gui'), s:get_attr(hldef, 'attr'))
    let hldef.term = extend(s:get_attr(hldef, 'term'), s:get_attr(hldef, 'attr'))
  endif
  return hldef
endfunction " }}}

function! s:to_term_color(gui_color) abort " {{{
  try
    return kolor#rgb_to_palette256(a:gui_color)
  catch
    return a:gui_color
  endtry
endfunction " }}}

function! s:to_gui_color(cui_color) abort " {{{
  try
    return s:to_rgb_string(a:cui_color)
  catch
    return a:cui_color
  endtry
endfunction " }}}

function! s:get_attr(hldef, key) abort " {{{
  let attr = get(a:hldef, a:key, [])
  return type(attr) == s:t_string ? [attr] : attr
endfunction " }}}

function! s:generate_hldef_dict(hlgroup, hldef) abort " {{{
  if a:hlgroup ==# '*Terminal'
    if !has_key(a:hldef, 'cui') && has_key(a:hldef, 'gui')
      let a:hldef.cui = map(copy(a:hldef.gui), 'kolor#rgb_to_palette256(v:val)')
    endif
    if !has_key(a:hldef, 'ctermbg') && has_key(a:hldef, 'guibg')
      let a:hldef.gui = map(copy(a:hldef.cui), 's:to_rgb_string(a:palette[str2nr(v:val)])')
    endif
    return {
          \ 'kind': 'terminal',
          \ 'def': {
          \   'gui': a:hldef.gui,
          \   'cui': a:hldef.cui
          \ }
          \}
  elseif has_key(a:hldef, 'link')
    return {'kind': 'link', 'def': ('hi! link ' . a:hlgroup . ' ' . a:hldef.link)}
  else
    return {'kind': 'def', 'def': s:generate_hldef_string(a:hlgroup, a:hldef)}
  endif
endfunction " }}}

function! s:generate_hldef_string(hlgroup, hldef) abort " {{{
  let line = 'hi! ' . a:hlgroup
  let fgbgs = map(filter(['ctermfg', 'ctermbg', 'guifg', 'guibg'], 'has_key(a:hldef, v:val)'), 'v:val . "=" . a:hldef[v:val]')
  if !empty(fgbgs)
    let line .= ' ' . join(fgbgs)
  endif
  return line . ' ' . join(map(['cterm', 'gui', 'term'], "v:val . '=' . (has_key(a:hldef, v:val) ? join(a:hldef[v:val], ',') : 'NONE')"))
endfunction " }}}

function! s:build_palette256() abort " {{{
  return copy(s:base16_values)
        \ + map(range(0, 215), '[s:ccvalues[v:val / 36], s:ccvalues[(v:val / 6) % 6], s:ccvalues[v:val % 6]]')
        \ + map(range(0, 23), 'repeat([8 + v:val * 10], 3)')
endfunction " }}}

function! s:_palette256_to_rgb1(esc) abort " {{{
  let [s:palette256, s:palette256_to_rgb] = [s:build_palette256(), function('s:_palette256_to_rgb2')]
  return copy(s:palette256[a:esc])
endfunction " }}}

function! s:_palette256_to_rgb2(esc) abort " {{{
  return copy(s:palette256[a:esc])
endfunction " }}}

let s:palette256_to_rgb = function('s:_palette256_to_rgb1')


function! s:extract_current_highlight() abort " {{{
  let hldef = {}
  for name1 in getcompletion('', 'highlight')
    let id1 = hlID(name1)
    let id2 = synIDtrans(id1)
    let name2 = synIDattr(id2, 'name')
    if id1 != id2
      call extend(hldef, {name1: {'link': name2}})
      continue
    endif
    let def = {}
    for mode in ['cterm', 'gui', 'term']
      for what in ['fg#', 'bg#']
        let color = synIDattr(id1, what, mode)
        if color !=# ''
          call extend(def, {(mode . what[: 1]): color})
        endif
      endfor
      let attrs = map(filter(['bold', 'italic', 'reverse', 'standout', 'underline', 'undercurl', 'strike'], "synIDattr(id1, v:val, mode) ==# '1'"), 's:attrkey_attr_dict[v:val]')
      if !empty(attrs)
        call extend(def, {mode: attrs})
      endif
    endfor
    if !empty(def)
      call extend(hldef, {name1: def})
    endif
  endfor
  return {&bg: hldef}
endfunction " }}}


let &cpo = s:save_cpo
unlet s:save_cpo
