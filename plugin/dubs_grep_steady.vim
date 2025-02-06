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
" User map <Plug>s
" ------------------------------------------------------

function! s:CreateMaps__CreatePlugs() abort
  nnoremap <silent> <script> <Plug>(grep-steady-prompt-simple)
    \ :call g:embrace#grep_steady#GrepPrompt_Simple("", 0, 0, 0)<CR><CR>

  vnoremap <silent> <script> <Plug>(grep-steady-prompt-simple-selected)
    \ :<C-U>
    \ <CR>gvy
    \ :call g:embrace#grep_steady#GrepPrompt_Simple(@@, 0, 0, 0)<CR>
endfunction

call s:CreateMaps__CreatePlugs()

" ------------------------------------------------------

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Search Mappings
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" ------------------------------------------------------

" *** Generic Search: Prompt for Query and Path
" 
" - Default: \g

function! s:CreateMaps__GrepPrompt_Simple(key_sequence = '<Leader>g') abort
  execute 'nnoremap <silent> ' .. a:key_sequence .. ' <Plug>(grep-steady-prompt-simple)'
  execute 'inoremap <silent> ' .. a:key_sequence .. ' <C-O><Plug>(grep-steady-prompt-simple)'

  " A previous approach:
  "   vnoremap <Leader>g :<C-U>
  "     \ let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  "     \ gvy
  "     \ :call g:embrace#grep_steady#GrepPrompt_Simple(@@, 0, 0, 0)<CR>
  "     \ gV
  "     \ :call setreg('"', old_reg, old_regtype)<CR>
  " A better approach: (Keeps selection selected):
  execute 'vnoremap <silent> ' .. a:key_sequence .. ' <Plug>(grep-steady-prompt-simple-selected)'
endfunction

" ***

function! s:WireSearchMappings() abort
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

  nnoremap <silent> <F4> :call g:embrace#grep_steady#GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>
  inoremap <silent> <F4> <C-O>:call g:embrace#grep_steady#GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>
  " Selected word
  vnoremap <silent> <F4> :<C-U>
    \ <CR>gvy
    \ :call g:embrace#grep_steady#GrepPrompt_Auto_Prev_Location(@@)<CR>

  " This time, prompt for location
  nnoremap <silent> <S-F4> :call g:embrace#grep_steady#GrepPrompt_Auto_Ask_Location("<C-R><C-W>")<CR>
  inoremap <silent> <S-F4> <C-O>:call g:embrace#grep_steady#GrepPrompt_Auto_Ask_Location("<C-R><C-W>")<CR>
  " Selected word
  vnoremap <silent> <S-F4> :<C-U>
    \ <CR>gvy
    \ :call g:embrace#grep_steady#GrepPrompt_Auto_Ask_Location(@@)<CR>

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
  nnoremap <silent> <M-F4> :call g:embrace#grep_steady#GrepPrompt_Term_Prev_Location("<C-R><C-W>")<CR>
  inoremap <silent> <M-F4> <C-O>:call g:embrace#grep_steady#GrepPrompt_Term_Prev_Location("<C-R><C-W>")<CR>
endfunction

call s:WireSearchMappings()

call s:CreateMaps__GrepPrompt_Simple('<Leader>g')

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
    \ g:embrace#grep_steady#Toggle_GrepAllTheCases()

  execute 'nnoremap <silent> ' .. a:key_sequence .. ' <Plug>(grep-steady-toggle-multicase)'
  execute 'inoremap <silent> ' .. a:key_sequence .. ' <C-O><Plug>(grep-steady-toggle-multicase)'
endfunction

call s:CreateMaps__ToggleMulticase('<Leader>dg')

" -------------------------------------------------------------------

function! s:CreateMaps__ToggleColumnNumbers(key_sequence = '<Leader>dg') abort
  nnoremap <silent> <expr> <script> <Plug>(grep-steady-toggle-column-numbers)
    \ g:embrace#grep_steady#Toggle_GrepIncludeColumnNumbers()

  execute 'nnoremap <silent> ' .. a:key_sequence .. ' <Plug>(grep-steady-toggle-column-numbers)'
  execute 'inoremap <silent> ' .. a:key_sequence .. ' <C-O><Plug>(grep-steady-toggle-column-numbers)'
endfunction

call s:CreateMaps__ToggleColumnNumbers('<Leader>dn')

" -------------------------------------------------------------------

" Use \dp (or call :GrepSteadyReload) to reload the `dubs_projects.vim` file.
if mapcheck('<Plug>(grep-steady-load-user-projects)') == ''
  nnoremap <silent> <Plug>(grep-steady-load-user-projects)
    \ :<C-u>call g:embrace#grep_steady#LoadUsersGrepProjects(1)<CR>
endif
if mapcheck('<Leader>dp', 'n') == ''
  nnoremap <silent> <unique> <Leader>dp <Plug>(grep-steady-load-user-projects)
  inoremap <silent> <unique> <Leader>dp <C-O><Plug>(grep-steady-load-user-projects)
endif

command! -nargs=0 GrepSteadyReload :call g:embrace#grep_steady#LoadUsersGrepProjects(1)

if mapcheck('<Plug>(grep-steady-edit-user-projects)') == ''
  nnoremap <silent> <Plug>(grep-steady-edit-user-projects)
    \ :<C-u>call g:embrace#grep_steady#OpenUsersGrepProjects()<CR>
endif
if mapcheck('<Leader>dP', 'n') == ''
  nnoremap <silent> <unique> <Leader>dP <Plug>(grep-steady-edit-user-projects)
  inoremap <silent> <unique> <Leader>dP <C-O><Plug>(grep-steady-edit-user-projects)
endif

command! -nargs=0 GrepSteadyEdit :call g:embrace#grep_steady#OpenUsersGrepProjects()

" -------------------------------------------------------------------

call g:embrace#grep_steady#LoadUsersGrepProjects(0)

