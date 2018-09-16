" ============================================================================
" FILE: kolor.vim
" AUTHOR: koturn <jeak.koutan.apple@gmail.com>
" DESCRIPTION: {{{
" Koturn's color utility.
" }}}
" ============================================================================
if exists('g:loaded_kolor')
  finish
endif
let g:loaded_kolor = 1
let s:save_cpo = &cpo
set cpo&vim


command! -bar KolorShowPalette256  call kolor#show_palette256()
command! -bar -nargs=+ KolorEcho  call kolor#echo(<f-args>)
command! -bar -nargs=+ KolorEchoNr  call kolor#echonr(<f-args>)


let &cpo = s:save_cpo
unlet s:save_cpo
