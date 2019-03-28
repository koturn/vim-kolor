" {{{ themis includes
let s:suite = themis#suite('convert')
let s:assert = themis#helper('assert')
let s:scope = themis#helper('scope')
" }}}

let s:au_local_funcs = s:scope.funcs('autoload/kolor.vim')

function! s:suite.s_to_rgb_list() abort " {{{
  call s:assert.equals(s:au_local_funcs.to_rgb_list(0x4488cc), [0x44, 0x88, 0xcc])
  call s:assert.equals(s:au_local_funcs.to_rgb_list('#4488cc'), [0x44, 0x88, 0xcc])
  call s:assert.equals(s:au_local_funcs.to_rgb_list('4488cc'), [0x44, 0x88, 0xcc])
  call s:assert.equals(s:au_local_funcs.to_rgb_list('#48c'), [0x44, 0x88, 0xcc])
  call s:assert.equals(s:au_local_funcs.to_rgb_list('48c'), [0x44, 0x88, 0xcc])
  call s:assert.equals(s:au_local_funcs.to_rgb_list(0x44, 0x88, 0xcc), [0x44, 0x88, 0xcc])
endfunction " }}}

function! s:suite.s_build_palette256() abort " {{{
  let palette256 = s:au_local_funcs.build_palette256()
  call s:assert.length_of(palette256, 256)
  for rgb in palette256
    call s:assert.length_of(rgb, 3)
    for i in range(0, 2)
      call s:assert.compare(0, '<=', rgb[i])
      call s:assert.compare(rgb[i], '<=', 255)
    endfor
  endfor
endfunction " }}}

function! s:suite.rgb_yuv() abort " {{{
  let step = 16
  let indices = map(range(0, 256 / step - 1), 'v:val * step')
  for r in indices
    for g in indices
      for b in indices
        let rgb = [r, g, b]
        let yuv = kolor#rgb_to_yuv(rgb)
        call s:assert.compare(0, '<=', yuv[0])
        call s:assert.compare(yuv[0], '<=', 255)
        call s:assert.compare(-128, '<=', yuv[1])
        call s:assert.compare(yuv[1], '<=', 127)
        call s:assert.compare(-128, '<=', yuv[2])
        call s:assert.compare(yuv[2], '<=', 127)
        let rgb2 = kolor#yuv_to_rgb(yuv)
        for i in range(0, 2)
          call s:assert.true(abs(rgb[i] - rgb2[i]) <= 1)
        endfor
      endfor
    endfor
  endfor
endfunction " }}}

function! s:suite.rgb_hsv() abort " {{{
  let step = 16
  let indices = map(range(0, 256 / step - 1), 'v:val * step')
  for r in indices
    for g in indices
      for b in indices
        let rgb = [r, g, b]
        let hsv = kolor#rgb_to_hsv(rgb)
        call s:assert.compare(0.0, '<=', hsv[0])
        call s:assert.compare(hsv[0], '<=', 360.0)
        call s:assert.compare(0.0, '<=', hsv[1])
        call s:assert.compare(hsv[1], '<=', 1.0)
        call s:assert.compare(0.0, '<=', hsv[2])
        call s:assert.compare(hsv[2], '<=', 1.0)
        call s:assert.equals(rgb, kolor#hsv_to_rgb(hsv))
      endfor
    endfor
  endfor
endfunction " }}}

function! s:suite.rgb_hsl() abort " {{{
  let step = 16
  let indices = map(range(0, 256 / step - 1), 'v:val * step')
  for r in indices
    for g in indices
      for b in indices
        let rgb = [r, g, b]
        let hsl = kolor#rgb_to_hsl(rgb)
        call s:assert.compare(0.0, '<=', hsl[0])
        call s:assert.compare(hsl[0], '<=', 360.0)
        call s:assert.compare(0.0, '<=', hsl[1])
        call s:assert.compare(hsl[1], '<=', 1.0)
        call s:assert.compare(0.0, '<=', hsl[2])
        call s:assert.compare(hsl[2], '<=', 1.0)
        call s:assert.equals(rgb, kolor#hsl_to_rgb(hsl))
      endfor
    endfor
  endfor
endfunction " }}}

function! s:suite.rgb_hsi() abort " {{{
  let step = 16
  let indices = map(range(0, 256 / step - 1), 'v:val * step')
  for r in indices
    for g in indices
      for b in indices
        let rgb = [r, g, b]
        let hsi = kolor#rgb_to_hsi(rgb)
        call s:assert.compare(0.0, '<=', hsi[0])
        call s:assert.compare(hsi[0], '<=', 360.0)
        call s:assert.compare(0.0, '<=', hsi[1])
        call s:assert.compare(hsi[1], '<=', 1.0)
        call s:assert.compare(0.0, '<=', hsi[2])
        call s:assert.compare(hsi[2], '<=', 1.0)
        let rgb2 = kolor#hsi_to_rgb(hsi)
        for i in range(0, 2)
          call s:assert.true(abs(rgb[i] - rgb2[i]) <= 4)
        endfor
      endfor
    endfor
  endfor
endfunction " }}}
