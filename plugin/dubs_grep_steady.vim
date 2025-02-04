" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/dubs_grep_steady#🧐
" License: GPLv3
"   Copyright © 2009, 2015, 2017, 2020, 2024 Landon Bouma.
" Summary: Dubs Vim Text Search Commands

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_dubs_grep_steady_plugin
endif

if exists('g:loaded_dubs_grep_steady_plugin') || &cp

  finish
endif

let g:loaded_dubs_grep_steady_plugin = 1

" -------------------------------------------------------------------

" ------------------------------------------------------
" GrepPrompt_Simple
" ------------------------------------------------------

"" Map <Leader>G0 to the Grep Prompt
"if !hasmapto('<Plug>DubsGrepSteady_GrepPrompt_Simple')
"  map <silent> <unique> <Leader>g
"    \ <Plug>DubsGrepSteady_GrepPrompt_Simple
"endif

" Map <Plug> to an <SID> function
function! s:Map_GrepPrompt_Simple() abort
  if mapcheck('<Plug>DubsGrepSteady_GrepPrompt_Simple') == ''
    noremap <silent> <unique> <script>
      \ <Plug>DubsGrepSteady_GrepPrompt_Simple
      \ :call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 0, 0)<CR><CR>
  endif
endfunction

call s:Map_GrepPrompt_Simple()

" -------------------------------------------------------------------

" FIXME New fcn. 2011.01.08
"
" Quick-search selected item on last-used search location
" :noremap <Leader>G "sy:call <SID>GrepPrompt_Auto_Prev_Location("<C-r>s")<CR>
" NOTE Extra <CR> to avoid Quickfix's silly prompt,
"      'Press ENTER or type command to continue'
":noremap <Leader>G :call <SID>GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>

" FIXME: Add ability to restrict search by file extension.
"        Currently, you can search a folder and then search
"        the quickfix window by file extension.

" -------------------------------------------------------------------

" ------------------------------------------------------
" Search Mappings
" ------------------------------------------------------

function! s:WireSearchMappings() abort

  " Generic Search: Prompt for Query and Path
  " ------------------------------------------------------
  " \g

  "map <silent> <unique> <Leader>g <Plug>DubsGrepSteady_GrepPrompt_Simple
  nnoremap <silent> <Leader>g :call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 0, 0)<CR>
  inoremap <silent> <Leader>g <C-O>:call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 0, 0)<CR>
  " Can't do unique on onoremap 'cause it's already set?
  " onoremap <silent> <unique> <Leader>g <C-C>:call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 0, 0)<CR>
  " Selected word
  "vnoremap <silent> <Leader>g :<C-U>call <SID>GrepPrompt_Auto_Ask_Location(<C-R>)<CR>
  "vnoremap <Leader>g :<C-U>echo "Hello ". @"

  " NOTE I'm not sure we need to store registers like this but we do
  "vnoremap <Leader>g :<C-U>
  "  \ let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  "  \ gvy
  "  \ :call g:embrace#grep_steady#GrepPrompt_Simple(@@, 0, 0, 0)<CR>
  "  \ gV
  "  \ :call setreg('"', old_reg, old_regtype)<CR>
  " Better: (keeps stuff selected)
  vnoremap <silent> <Leader>g :<C-U>
    \ <CR>gvy
    \ :call g:embrace#grep_steady#GrepPrompt_Simple(@@, 0, 0, 0)<CR>

  "xnoremap <silent> <Leader>g <C-U>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-R>")<CR>
  "snoremap <silent> <Leader>g <C-U>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R>")<CR>

  " 2015.06.11: Early birthday present: Case-sensitive, for
  "             when you want ag to recognize all-lowercase.
  noremap <silent> <Leader>G :call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 1, 0)<CR>
  inoremap <silent> <Leader>G <C-O>:call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 1, 0)<CR>
  vnoremap <silent> <Leader>G :<C-U>
    \ <CR>gvy
    \ :call g:embrace#grep_steady#GrepPrompt_Simple(@@, 0, 1, 0)<CR>

  " Limit search results to one per file, if you
  " just want an idea which files contain matches.
  noremap <silent> <Leader>C :call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 0, 1)<CR>
  inoremap <silent> <Leader>C <C-O>:call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 0, 1)<CR>
  vnoremap <silent> <Leader>C :<C-U>
    \ <CR>gvy
    \ :call g:embrace#grep_steady#GrepPrompt_Simple(@@, 0, 0, 1)<CR>

  " Search for Word under Cursor
  " ------------------------------------------------------
  " F4s

  " NOTE <C-R><C-W> is Vim-speak for the word under the cursor
  " REFER: <C-R><C-W> — :help c_CTRL-R_CTRL-W

  nnoremap <silent> <F4> :call <SID>GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>
  inoremap <silent> <F4> <C-O>:call <SID>GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>
  " Selected word
  vnoremap <silent> <F4> :<C-U>
    \ <CR>gvy
    \ :call <SID>GrepPrompt_Auto_Prev_Location(@@)<CR>

  " This time, prompt for location
  nnoremap <silent> <S-F4> :call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-W>")<CR>
  inoremap <silent> <S-F4> <C-O>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-W>")<CR>
  " Selected word
  vnoremap <silent> <S-F4> :<C-U>
    \ <CR>gvy
    \ :call <SID>GrepPrompt_Auto_Ask_Location(@@)<CR>

  " Ask for search term but use previous location.
  "
  " - DUNNO/2024-12-27: This was <C-F4>, which works in Linux, but
  "   MacVim does not seem to honor <Ctrl-Fn> or <Ctrl-{number}>.
  "   - At least not in author's experience, but could be something else
  "     (though doesn't work with `gvim --noplugin` with mswin.vim loaded
  "     either).
  "   - You'll still see the map wired, though, e.g. :nmap <C-F4> prints:
  "       nv <C-F4> * <C-W>c
  "   - Note that mswin.vim maps Close window to <C-F4>, which works in
  "     Linux (now that this binding is moved to <M-F4>), but it doesn't
  "     do anything in MacVim. 
  "     - CXREF:
  "       /Applications/MacVim.app/Contents/Resources/vim/runtime/mswin.vim
  "   - UTEST: Try these to check your environment:
  "       nnoremap <C-F4> :echo 'foo'<CR>
  "       nnoremap <M-F4> :echo 'foo'<CR>
  "       nnoremap <C-4> :echo 'foo'<CR>
  nnoremap <silent> <M-F4> :call <SID>GrepPrompt_Term_Prev_Location("<C-R><C-W>")<CR>
  inoremap <silent> <M-F4> <C-O>:call <SID>GrepPrompt_Term_Prev_Location("<C-R><C-W>")<CR>
endfunction

call s:WireSearchMappings()

" -------------------------------------------------------------------

" Toggle GrepCase
" ------------------------------------------------------
" I.e., search for exact word; vs. include case permutations.
" - E.g., search for FOO_BAR; vs. search for fooBar, foo_bar, and foo-bar.
" 
" When g:DubsGrepSteady_GrepAllTheCases = 0, uses `rg --smart-case`.
" When g:DubsGrepSteady_GrepAllTheCases = 1, uses `rg --ignore-case`
"   and searches camel|snake|train variations.
"
" TRYME: You can try searching on these terms to demo now
" GrepAllTheCases behaves:
"   findmeplease
"   FINDmePLEASE
"   findMePlease
"   find_me_please
"   find-me-please
"   FIND_ME_PLEASE
"
" USAGE: Wire you own map sequence to toggle extravagant casing.
" - The author uses \dg, mnemonic: toggle 'Dubs Grep' casing.

function! s:CreateMaps__ToggleMulticase(key_sequence = '<Leader>dg') abort
  nnoremap <silent> <expr> <script> <Plug>(grep-steady-toggle-multicase)
    \ <SID>Toggle_GrepAllTheCases()

  execute 'nnoremap <silent> ' .. a:key_sequence .. ' <Plug>(grep-steady-toggle-multicase)'

  execute 'nnoremap <silent> ' .. a:key_sequence .. ' <Plug>(grep-steady-toggle-multicase)'
endfunction

call s:CreateMaps__ToggleMulticase('<Leader>dg')

" -------------------------------------------------------------------

call s:LoadUsersGrepProjects(0)

" Use \dp (or call :GrepSteadyReload) to reload the `dubs_projects.vim` file.
if mapcheck('<Plug>(DGS_LoadUsersGrepProjects)') == ''
  nnoremap <silent> <Plug>(DGS_LoadUsersGrepProjects) :<C-u>call <SID>LoadUsersGrepProjects(1)<CR>
endif
if mapcheck('<Leader>dp', 'n') == ''
  noremap <silent> <unique> <Leader>dp <Plug>(DGS_LoadUsersGrepProjects)
  inoremap <silent> <unique> <Leader>dp <C-O><Plug>(DGS_LoadUsersGrepProjects)
endif

command! -nargs=0 GrepSteadyReload :call <SID>LoadUsersGrepProjects(1)

if mapcheck('<Plug>(DGS_OpenUsersGrepProjects)') == ''
  nnoremap <silent> <Plug>(DGS_OpenUsersGrepProjects) :<C-u>call <SID>OpenUsersGrepProjects()<CR>
endif
if mapcheck('<Leader>dP', 'n') == ''
  noremap <silent> <unique> <Leader>dP <Plug>(DGS_OpenUsersGrepProjects)
  inoremap <silent> <unique> <Leader>dP <C-O><Plug>(DGS_OpenUsersGrepProjects)
endif

command! -nargs=0 GrepSteadyEdit :call <SID>OpenUsersGrepProjects()

