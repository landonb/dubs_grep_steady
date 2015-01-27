" File: dubs_grep_steady.vim
" Author: Landon Bouma (dubsacks &#x40; retrosoft &#x2E; com)
" Last Modified: 2015.01.26
" Project Page: https://github.com/landonb/dubs_grep_steady
" Summary: Dubsacks Text Search Commands
" License: GPLv3
" -------------------------------------------------------------------
" Copyright © 2009-2015, 2015 Landon Bouma.
" 
" This file is part of Dubsacks.
" 
" Dubsacks is free software: you can redistribute it and/or
" modify it under the terms of the GNU General Public License
" as published by the Free Software Foundation, either version
" 3 of the License, or (at your option) any later version.
" 
" Dubsacks is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty
" of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
" the GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with Dubsacks. If not, see <http://www.gnu.org/licenses/>
" or write Free Software Foundation, Inc., 51 Franklin Street,
"                     Fifth Floor, Boston, MA 02110-1301, USA.
" ===================================================================

" ------------------------------------------
" About:

" This script sets up a powerful text search utility.

if exists("g:plugin_dubs_grep_steady") || &cp
  finish
endif
let g:plugin_dubs_grep_steady = 1

" ------------------------------------------------------
" Choose the Best Search Utility
" ------------------------------------------------------

" The author recommends The Silver Searcher.
" If that's not installed, we'll use egrep.
" On Windows, the default searcher is findstr,
" so this code ensures we use Cygwin's grep.

" The Silver Searcher vs. egrep
" ------------------------------------------------------
" egrep is classic and great. The silver searcher is newer and faster.
" You probably won't notice much performance difference searching
" smaller projects or searching on faster, modern machines. Also, silver
" searcher doesn't recognize the regular expression /<blah/> to search
" for exact word hits, so use \bword\b boundaries instead. But the silver
" searcher lets you ignore files with a specific file path, whereas egrep
" only lets you ignore files matching a specific name or file within a
" specific parent directory.

if filereadable("/usr/bin/ag")
  " *nix w/ The Silver Searcher
  " -A --after [LINES]      Print lines before match (Default: 2)
  " -B --before [LINES]     Print lines after match (Default: 2)
  " -S --smart-case         Match case insensitively unless PATTERN contains
  "                         uppercase characters
  set grepprg=ag\ -A\ 0\ -B\ 0\ --smart-case\ --hidden
else
  " Grep options:
  "  -n makes grep show line numbers
  "  -R recurses directories
  "  -i --ignore-case
  "  -E uses extended regexp (same as egrep) 
  "       so that alternation (|) works, 
  "       among other opts
  "  --exclude-from specifies a file containing
  "                 filename globs used to exclude
  "                 files from the search
  " Example Vim Grep command:
  "  :grep "Sentence fragment" "C:\my\project\path"
  " NOTE: The --exclude-from file (grep-exclude) can only specifies file
  "         to ignore.
  "       To ignore directories by name (but not path), use --exclude-dir.
  " DEVS: If you want to exclude directories, add said switch, e.g.,
  "         set grepprg=egrep\ --exclude-dir=\"build\"\ ...
  " EXPLAIN: Doesn't it seem odd that egrep let's you specify basenames
  "          to ignore using a file, but directories to ignore must be
  "          specified on the command line, and there's no way to exclude
  "          files based on a more complete path?
  if filereadable($HOME . "/.vim/grep-exclude")
    " *nix w/ egrep
    set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"$HOME/.vim/grep-exclude\"
  elseif filereadable($USERPROFILE . "/vimfiles/grep-exclude")
    " Windows w/ egrep
    set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"$USERPROFILE/vimfiles/grep-exclude\"
  else
    let l:exclf = findfile('grep-exclude',
                           \ pathogen#split(&rtp)[0] . "/**")
    if l:exclf != ''
      " Turn into a full path. See :h filename-modifiers
      let l:exclf = fnamemodify(l:exclf, ":p")
      execute 'set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"'.l:exclf.'\"'
    else
      echomsg 'Warning: Dubs could find grep-exclude file'
    endif
  endif
endif

" Grep notes:
" NOTE: The grep exclude-from file *must* be saved 
"       in unix format 
"       i.e., if :set ff is 'dos', it won't work! 
"       so :set ff=unix
" NOTE: The exclude-from file has one file glob 
"       per line, i.e.,
"         *.sql
"         *.skipme
"         *.etc

" FIXME: Map the quickfix navigation commands to, um,
"        maybe alt-right and alt-left (in quickfix only)
"        so you can search one term, then another, and then
"        return to the first term's result.
" DISCOVER: Can you show search results in a window's location list?
"           Would you want to?

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Setup Search Features
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

let s:simple_grep_last_i = 0

" ------------------------------------------------------
" GrepPrompt_Simple
" ------------------------------------------------------

"" Map <Leader>G0 to the Grep Prompt
"if !hasmapto('<Plug>GrepPrompt_Simple')
"  map <silent> <unique> <Leader>g
"    \ <Plug>GrepPrompt_Simple
"endif

" Map <Plug> to an <SID> function
map <silent> <unique> <script> 
  \ <Plug>GrepPrompt_Simple 
  \ :call <SID>GrepPrompt_Simple("", 0)<CR><CR>

" And finally thunk to the script fcn.
""function <SID>GrepPrompt_Simple()
""  call s:GrepPrompt_Simple()
""endfunction

" Let the user map their own command to the
" toggle function by making it a <Plug>
"   1. Make the <Plug>
""map <silent> <unique> <script> 
""  \ <Plug>GrepPrompt_Simple 
""  \ :call <SID>GrepPrompt_Simple()<CR>
"   2. Thunk the <Plug>
"
" GrepPrompt_Simple: term is the term to search, or 
"                      "" if we should ask the user
"                    locat_index is the location index
"                      to search, or 0 to ask user for it
" If the callee supplies both term and locat_index, we automatically complete
" the search. However, this bypasses input(), which means term doesn't get
" added to the input() history. This is annoying if you auto-search a lot and
" want to go back to a previous search term (though I suppose you could just
" use :cold to jump back in the quickfix history). I don't think we can add to
" the histories, and I can't think of a good solution (we could call input()
" with a default value, but that's probably annoying).
function s:GrepPrompt_Simple(term, locat_index)
  call inputsave()
  let the_term = a:term
  if a:term == ""
    " There's a newline in the buffer, so call inputsave
    "call inputsave()
    let the_term = input("Search for: ")
    "call inputrestore()
    "echo "The term is" . the_term
    "let TBD = input("Hit any key to continue: ")
  endif
  " Check for <ESC> lest we dismiss a help 
  " page (or something not in the buffer list)
  if the_term != ""
    " Ask the user to enter/confirm the search location
    let new_i = a:locat_index
    if new_i == 0
      "call inputsave()
      let new_i = inputlist(s:GrepPrompt_Simple_GetInputlist(
        \ s:simple_grep_last_i))
      "call inputrestore()
    endif
    "echo "=== new_i: " . new_i
    "let TBD = input("Hit any key to continue: ")
    " If the user hits Enter or Escape, inputlist returns 0, which is also
    " the very first item in the list. However, we put "Search in:" as the
    " first item, so we can assume the user hit Enter or Escape. In the past,
    " we interpreted that to mean the user wants us to search in the last
    " used location. But I [lb] got annoyed that Escape wouldn't cancel the
    " operation.  I considerd making the next row (value 1) say "Cancel",
    " but that seems awkward, and I still want to be able to reclaim Escape,
    " so there's now a separate keyboard shortcut to search again in the
    " same location.  UG. This lasted ten minutes. I can't live without
    " double-return, either!
    " Trying "1" as the cancel indicator
    if new_i == 0
      let new_i = s:simple_grep_last_i
      if new_i == 0
        "call inputsave()
        let new_i = inputlist(s:GrepPrompt_Simple_GetInputlist(
          \ s:simple_grep_last_i))
        "call inputrestore()
      endif
    endif
    "if new_i > 0
    if new_i > 1
      let locat = g:ds_simple_grep_locat_lookup[new_i]
      execute "silent gr! \"" . the_term . "\" " . locat
      let s:simple_grep_last_i = new_i
      :QFix!(0)
      ":QFix(1, 1)
    endif
  endif
  call inputrestore()
endfunction

function s:GrepPrompt_Simple_GetInputlist(i_highlight)
  let ilist = [g:ds_simple_grep_locat_lookup[0]]
  for i in range(1, g:ds_simple_grep_locat_lookup_len - 1)
    let ilist = add(ilist, s:GrepPrompt_Simple_GetInputlistItem(
      \ i, i == a:i_highlight))
  endfor
  return ilist
endfunction

function s:GrepPrompt_Simple_GetInputlistItem(idx, do_highlight)
  let listitem = "    "
  if a:do_highlight
    let listitem = "(*) "
  endif
  let listitem .= a:idx . ". " . g:ds_simple_grep_locat_lookup[a:idx]
  return listitem
endfunction

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

" ------------------------------------------------------
" Search Mappings
" ------------------------------------------------------

" Generic Search: Prompt for Query and Path
" ------------------------------------------------------
" \g

"map <silent> <unique> <Leader>g <Plug>GrepPrompt_Simple
noremap <silent> <Leader>g :call <SID>GrepPrompt_Simple("", 0)<CR>
inoremap <silent> <Leader>g <C-O>:call <SID>GrepPrompt_Simple("", 0)<CR>
"cnoremap <silent> <unique> <Leader>g <C-C>:call <SID>GrepPrompt_Simple("", 0)<CR>
" Can't do unique on onoremap 'cause it's already set?
" onoremap <silent> <unique> <Leader>g <C-C>:call <SID>GrepPrompt_Simple("", 0)<CR>
" Selected word
"vnoremap <silent> <Leader>g :<C-U>call <SID>GrepPrompt_Auto_Ask_Location(<C-R>)<CR>
"vnoremap <Leader>g :<C-U>echo "Hello ". @"

" NOTE I'm not sure we need to store registers like this but we do
"vnoremap <Leader>g :<C-U>
"  \ let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
"  \ gvy
"  \ :call <SID>GrepPrompt_Simple(@@, 0)<CR>
"  \ gV
"  \ :call setreg('"', old_reg, old_regtype)<CR>
" Better: (keeps stuff selected)
vnoremap <silent> <Leader>g :<C-U>
  \ <CR>gvy
  \ :call <SID>GrepPrompt_Simple(@@, 0)<CR>

"xnoremap <silent> <Leader>g <C-U>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-R>")<CR>
"snoremap <silent> <Leader>g <C-U>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R>")<CR>

" Search for Word under Cursor
" ------------------------------------------------------
" F4s

noremap <silent> <F4> :call <SID>GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>
inoremap <silent> <F4> <C-O>:call <SID>GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>
cnoremap <silent> <F4> <C-C>:call <SID>GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>
onoremap <silent> <F4> <C-C>:call <SID>GrepPrompt_Auto_Prev_Location("<C-R><C-W>")<CR>
" Selected word
vnoremap <silent> <F4> :<C-U>
  \ <CR>gvy
  \ :call <SID>GrepPrompt_Auto_Prev_Location(@@)<CR>

" This time, prompt for location
noremap <silent> <S-F4> :call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-W>")<CR>
inoremap <silent> <S-F4> <C-O>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-W>")<CR>
cnoremap <silent> <S-F4> <C-C>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-W>")<CR>
onoremap <silent> <S-F4> <C-C>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-W>")<CR>

" NOTE Cannot get <C-8> or <C-*> to work (both still call :nohlsearch)
" NOTE <C-R><C-W> is Vim-speak for the word under the cursor
" FIXME Move this to EditPlus.vim or something...
noremap <silent> <C-F4> :call <SID>GrepPrompt_Term_Prev_Location("<C-R><C-W>")<CR>
inoremap <silent> <C-F4> <C-O>:call <SID>GrepPrompt_Term_Prev_Location("<C-R><C-W>")<CR>
cnoremap <silent> <C-F4> <C-C>:call <SID>GrepPrompt_Term_Prev_Location("<C-R><C-W>")<CR>
onoremap <silent> <C-F4> <C-C>:call <SID>GrepPrompt_Term_Prev_Location("<C-R><C-W>")<CR>

function s:GrepPrompt_Term_Prev_Location(term)
  call s:GrepPrompt_Simple("", s:simple_grep_last_i)
endfunction

function s:GrepPrompt_Auto_Prev_Location(term)
  if a:term != ""
    call s:GrepPrompt_Simple(a:term, s:simple_grep_last_i)
  endif
endfunction

function s:GrepPrompt_Auto_Ask_Location(term)
  if a:term != ""
    call s:GrepPrompt_Simple(a:term, 0)
  endif
endfunction

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Default Search Directory Choices
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
" DEVS: Override this list using a dubsgrep_blah.vim script,
"       or dubs_grep_steady/dubs_projects.vim.
" ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

" Hint: For locations searched frequently, avoid numbers '6' through '0'
"       so you can type it out using just the left hand.

" NOTE: If you want to map two or more directories to the
"       same number, just use spaces comma dummy comma egee
"         \ "/ccp/dev/cp/pyserver "
"         \   . "/ccp/dev/cp/scripts "
"         \   . "/ccp/dev/cp/services "
"         \   . "/ccp/dev/cp/mapserver "
"         \   . "/ccp/dev/cp/mediawiki ",

" NOTE: The numbers are just placeholders. Replace them with
"       project directories, leave them alone, or delete them.
"       However, because of the line continuation backslash,
"       you cannot use a comment to indicate the number mappings
"       in the array definition.

" FIXME: Make DRY. This fcn. was copied to dubs_file_finder
"        and dubs_edit_juice.
"
" See if the user made a project search listing and use that.
let s:d_projs = findfile('dubs_projects.vim',
                       \ pathogen#split(&rtp)[0] . "/**")
if s:d_projs != ''
  " Turn into a full path. See :h filename-modifiers
  let s:d_projs = fnamemodify(s:d_projs, ":p")
else
  " No file, but there should be a template we can copy.
  let s:tmplate = findfile('dubs_projects.vim.template',
                         \ pathogen#split(&rtp)[0] . "/**")
  if s:tmplate != ''
    let s:tmplate = fnamemodify(s:tmplate, ":p")
    " See if dubs_all is there.
    let s:dubcor = fnamemodify(
      \ finddir('dubs_all', pathogen#split(&rtp)[0] . "/**"), ":p")
    " Get the filename root, i.e., drop the ".template".
    let s:d_projs = fnamemodify(s:tmplate, ":r")
    " Make a copy of the template.
    execute '!/bin/cp ' . s:tmplate . ' ' . s:d_projs
    if isdirectory(s:dubcor)
      let s:ln_projs = s:dubcor . '/' . fnamemodify(s:tmplate, ":t:r")
      silent execute '!/bin/ln -s ' . s:d_projs . ' ' . s:ln_projs
    endif
  else
    echomsg 'Warning: Dubsacks could not find dubs_projects.vim.template'
  endif
endif
if s:d_projs != ''
  execute 'source ' . s:d_projs
else
  echomsg 'Warning: Dubsacks could not find dubs_projects.vim'
endif

" Obsolete. Has since been extracted and templatized...
"
" " If the user did not make a project search listing, we'll
" " set it using the first default we find from the project-specific
" " config files.
" let files = glob("$HOME/.vim/plugin/dubsgrext_*.vim")
" if files != ''
"   let files_l = split(files, '\n')
"   for file_n in files_l
"     " MAYBE: Do we care that Vim will source these files a second time?
"     "        No complaints so far...
"     exec "source " . file_n
"   endfor
" endif

" If all else fails, use a really generic project listing.
if !exists('g:ds_simple_grep_locat_lookup')

  let g:ds_simple_grep_locat_lookup = [
    \ "Search in:",
    \ "[Enter 1 to Cancel]",
    \ "path/to/my/project",
    \ "another/project",
    \ "4",
    \ "5",
    \ "6",
    \ "7",
    \ $HOME . "/.vim",
    \ "`echo " . $HOME . "/.bashrc*`",
    \ "10",
    \ "11",
    \ "12",
    \ "13",
    \ "14",
    \ "15",
    \ "16",
    \ "17",
    \ "18",
    \ "19",
    \ "20",
    \ "21",
    \ "22",
    \ "23",
    \ "24",
    \ "25",
    \ "26",
    \ "27",
    \ "28",
    \ "29",
    \ "30",
    \ "31",
    \ "32",
    \ "33",
    \ "34",
    \ "35",
    \ "36"
    \]

  let g:ds_simple_grep_locat_lookup_len = 
    \ len(g:ds_simple_grep_locat_lookup)

endif

" ------------------------------------------------------
" ------------------------------------------------------
" ------------------------------------------------------

