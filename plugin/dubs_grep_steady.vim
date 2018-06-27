" File: dubs_grep_steady.vim
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Last Modified: 2017.11.12
" Project Page: https://github.com/landonb/dubs_grep_steady
" Summary: Dubsacks Text Search Commands
" License: GPLv3
" -------------------------------------------------------------------
" Copyright © 2009, 2015, 2017 Landon Bouma.
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

" See also another Ag plugin, https://github.com/rking/ag.vim.
" And the Perl-encoded Ack, at http://beyondgrep.com,
" and the list of other tools, http://betterthanack.com.

let s:using_ag = -1
let s:using_rg = -1

function! s:SetGrepprgRg()
  let s:using_ag = 0
  let s:using_rg = 1
  " 2017-09-13: Switching to `rg` b/c `ag` seeing a reST file as binary.
  " See comments for ag; the differences are: -U is --no-ignore-vcs,
  " and if not in a tty, ripgrep doesn't spit out line numbers.
  "
  " FIXME/2018-05-06: (lb): I finally want sorted, deterministic results!
  "   So what's faster? `rg --sort-files`, or `| sort` ?
  " The problem with sort is speed... so maybe I should set it just for
  "   certain projects?
  " Says Rip Grep:
  "    Sort results by file path. Note that this currently disables all
  "    parallelism and runs search in a single thread.
  " 2018-05-06: Hrmm. rg --sort-files results are always in the same order,
  "   but they're not alphabetical!
  "
  "set grepprg=rg\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --no-ignore-vcs\ --line-number\ --no-heading\ --with-filename\ --sort-files
  "
  " Use a wrapper I made that pipes to sort, because Vim don't pipe.
  " FIXME/2018-05-06: (lb): Support non-standard/non-Pathogen paths.
  "   Or let user override.
  let l:ripgrep_shim = $HOME . '/.vim/bundle/dubs_grep_steady/bin/vim-grepprg-rg-sort'
  if executable(l:ripgrep_shim)
    execute 'set grepprg=' . l:ripgrep_shim
  else
    set grepprg=rg\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --no-ignore-vcs\ --line-number\ --no-heading\ --with-filename
  endif
endfunction

function! s:SetGrepprgAg()
  let s:using_ag = 1
  let s:using_rg = 0
  " *nix w/ The Silver Searcher
  " -A --after [LINES]      Print lines before match (Default: 2).
  " -B --before [LINES]     Print lines after match (Default: 2).
  " -S --smart-case         Match case insensitively unless
  "                         PATTERN contains uppercase characters.
  " -f --follow             Follow symlinks.
  " SYNC: set grepprg=ag...
  "set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow
  " 2017-04-29: Ignore .gitignore files??
  set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ -U
  " Same, and more anal:
  "set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ $*
endfunction

function! s:SetGrepprgGrep()
  let s:using_ag = 0
  let s:using_rg = 0
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
    let s:exclf = findfile('grep-exclude',
                           \ pathogen#split(&rtp)[0] . "/**")
    if s:exclf != ''
      " Turn into a full path. See :h filename-modifiers
      let s:exclf = fnamemodify(s:exclf, ":p")
      execute 'set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"'.s:exclf.'\"'
    else
      "echomsg 'Warning: Dubs could find grep-exclude file'
      set grepprg=egrep\ -n\ -R\ -i
    endif
  endif
endfunction

" This is Vim's default grepformat. First to match wins.
" 1.  file:line:message
" 2.  file:linemessage
" 3.  file  linemessage
" Already set to:
"  set grepformat=%f:%l:%m,%f:%l%m,%f\ \ %l%m

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

function! s:SetGrepprg()
  if executable("rg")
    call s:SetGrepprgRg()
  elseif executable("ag")
    call s:SetGrepprgAg()
  else
    call s:SetGrepprgGrep()
  endif
endfunction

" FIXME/2018-05-06: (lb): Should probably function-ize everything
" and make a main().
call s:SetGrepprg()

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Setup Search Features
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

let s:simple_grep_last_i = 0

" ------------------------------------------------------
" GrepPrompt_Simple
" ------------------------------------------------------

"" Map <Leader>G0 to the Grep Prompt
"if !hasmapto('<Plug>DubsGrepSteady_GrepPrompt_Simple')
"  map <silent> <unique> <Leader>g
"    \ <Plug>DubsGrepSteady_GrepPrompt_Simple
"endif

" Map <Plug> to an <SID> function
map <silent> <unique> <script>
  \ <Plug>DubsGrepSteady_GrepPrompt_Simple
  \ :call <SID>GrepPrompt_Simple("", 0, 0, 0)<CR><CR>

" ***

" STOLEN! From vim-abolish. Shameless!!
" FIXME/2018-06-27/DRY: Make a util plugin for this!
"   These are duplicated in: vim-aboilsh; dubs_grep_steady; dubs_edit_juice

function! s:camelcase(word)
  let word = substitute(a:word, '-', '_', 'g')
  if word !~# '_' && word =~# '\l'
    return substitute(word,'^.','\l&','')
  else
    return substitute(word,'\C\(_\)\=\(.\)','\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
  endif
endfunction

function! s:snakecase(word)
  let word = substitute(a:word,'::','/','g')
  let word = substitute(word,'\(\u\+\)\(\u\l\)','\1_\2','g')
  let word = substitute(word,'\(\l\|\d\)\(\u\)','\1_\2','g')
  let word = substitute(word,'[.-]','_','g')
  let word = tolower(word)
  return word
endfunction

" A/k/a kebab-case | spinal-case | Train-Case | Lisp-case | dash-case
function! s:traincase(word)
  return substitute(s:snakecase(a:word),'_','-','g')
endfunction

function! s:uppercase(word)
  return toupper(s:snakecase(a:word))
endfunction

" ***

" And finally thunk to the script fcn.
""function <SID>GrepPrompt_Simple()
""  call s:GrepPrompt_Simple()
""endfunction

" Let the user map their own command to the
" toggle function by making it a <Plug>.
"   1. Make the <Plug>
""map <silent> <unique> <script>
""  \ <Plug>DubsGrepSteady_GrepPrompt_Simple
""  \ :call <SID>GrepPrompt_Simple()<CR>
"   2. Thunk the <Plug>
"
" GrepPrompt_Simple: term is the term to search, or
"                      "" if we should ask the user
"                    locat_index is the location index
"                      to search, or 0 to ask user for it
"                    case_sensitive enforces strict sensitivity
"                      (ag already enforces case if there 1+ uppers)
"                    limit_matches prints just the first match per file
" If the callee supplies both term and locat_index, we automatically complete
" the search. However, this bypasses input(), which means term doesn't get
" added to the input() history. This is annoying if you auto-search a lot and
" want to go back to a previous search term (though I suppose you could just
" use :cold to jump back in the quickfix history). I don't think we can add to
" the histories, and I can't think of a good solution (we could call input()
" with a default value, but that's probably annoying).
function s:GrepPrompt_Simple(term, locat_index, case_sensitive, limit_matches)
  call inputsave()
  let l:the_term = a:term
  if a:term == ""
    " There's a newline in the buffer, so call inputsave
    "call inputsave()
    let l:the_term = input("Search for: ")
    "call inputrestore()
    "echo "The term is" . l:the_term
    "let TBD = input("Hit any key to continue: ")
  endif
  " Check for <ESC> lest we dismiss a help
  " page (or something not in the buffer list)
  if l:the_term != ""
    " Ask the user to enter/confirm the search location
    let l:new_i = a:locat_index
    if l:new_i == 0
      "call inputsave()
      let l:new_i = inputlist(s:GrepPrompt_Simple_GetInputlist(
        \ s:simple_grep_last_i))
      "call inputrestore()
    endif
    "echo "=== new_i: " . l:new_i
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
    if l:new_i == 0
      let l:new_i = s:simple_grep_last_i
      if l:new_i == 0
        "call inputsave()
        let l:new_i = inputlist(s:GrepPrompt_Simple_GetInputlist(
          \ s:simple_grep_last_i))
        "call inputrestore()
      endif
    endif
    if l:new_i > 1
      let l:locat = g:ds_simple_grep_locat_lookup[l:new_i]
      let l:options = ''
      if s:using_rg == 1
        let l:options = get(g:ds_simple_grep_rg_options_map, l:new_i, '')
      elseif s:using_ag == 1
        let l:options = get(g:ds_simple_grep_ag_options_map, l:new_i, '')
      endif
      " Case (in)sensitive flags.
      if a:case_sensitive == 1
        if s:using_rg == 1 || s:using_ag == 1
          let l:options = l:options . " --case-sensitive"
        " else, egrep only defines -i
        endif
      else
        if s:using_rg == 1 || s:using_ag == 1
          let l:options = l:options . " --smart-case"
        else
          let l:options = l:options . " --ignore-case"
        endif
      endif
      " Limit matches flags.
      if s:using_ag == 1
        if a:limit_matches == 0
          " SYNC: set grepprg=ag...
          set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow
          " 2017-04-29: Ignore .gitignore files??
          set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ -U
        else
          " The Silver Search says "ERR: Too many matches" for each file
          " after printing one line, but the err come randomly from a thread
          " on stderr, and those messages and the search results end up being
          " interleaved. Since we can't easily pipe between two executables
          " using grepprg, and since Vim ends our grepprg with 2>&1, we have
          " to go through an external party to suppress the bad messages.
          "
          " 2015.06.11: ARGH: Cannot get any of these to work...
          "     set grepprg=ag_peek
          "     set grepprg=\(ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ 2>/dev/null\)
          "     set grepprg=(ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ 2>/dev/null)
          "     set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --max-count\ 1\ $*\ \\\|\ ag\ ".*"
          "     set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --max-count\ 1\ $*\ \\|\ ag\ ".*"
          "     set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --max-count\ 1\ "$*"\ 2\>\/dev\/null
          " so just punting: [2018-01-12: And I cannot remember the issue anymore]:
          set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --max-count\ 1\ "$*"
        endif
      else
        " RipGrep and Grep both support --max-count.
        if a:limit_matches != 0
          let l:options = l:options . " --max-count 1"
        endif
      endif

      " 2018-03-29: Crude implementation of caseless-grep.
      let l:new_term = l:the_term
      if g:DubsGrepSteady_GrepAllTheCases
        " Search on 3 casings: Camel, Snake, and Train.
        " NOTE: Converting to snakecase downcases it.
        let l:new_term = ''
          \ . tolower(s:camelcase(l:the_term)) . "\\|"
          \ . tolower(s:snakecase(l:the_term)) . "\\|"
          \ . tolower(s:traincase(l:the_term))
      endif

      " 2018-06-27: Whoa, how did I not know about histadd??! This is **AWESOME**!!
      "  Add the search term to the _input_ history. E.g., if user is on a work and
      "  presses [F4] to grep word-under-cursor, add that word to the input history,
      "  such that if the user later does a `\g` to initiate an interactive search,
      "  then that term is available in the input history list. SO OBVI!
      " NOTE: Use lower case, because --smart-case.
      " NOTE: This is similar to dubs_edit_juice's InstallHighlightOnEnter(),
      "       except that function bounds the terms with \b\b or \<\> word boundaries.
      call histadd("input", tolower(l:new_term))
      " Hrmmmm. We could do cross-history maintenance, too, so that the term is also
      " available in the `/` buffer search history list. AHAHAHAHA, I feel sorry for
      " my former, past selves having had to live without this killer feature!
      call histadd("/", tolower(l:new_term))
      " NOTE: If user greps for words matches, e.g., "\bword\b", the / history
      "       pattern won't work because of the difference in the word delimiters,
      "       e.g., the equivalent word history boundary in / is "\<word\>".

      " 2018-03-29: Crude implementation of caseless-grep.
      if g:DubsGrepSteady_GrepAllTheCases
        " Search on 3 casings: Camel, Snake, and Train.
        " NOTE: Converting to Snake_Case downcases it.
        let l:srch_term = "--ignore-case \"" . l:new_term . "\""
      else
        let l:srch_term = "\"" . l:new_term . "\""
      endif

      " HINT: Try: `:verbose set grepprg` and `:verbose gr` to see what happened.
      execute "silent gr! " . l:options . " " . l:srch_term . " " . l:locat
      "if s:using_ag == 1
      "  " SYNC: set grepprg=ag...
      "  set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow
      "endif
      let s:simple_grep_last_i = l:new_i
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

"map <silent> <unique> <Leader>g <Plug>DubsGrepSteady_GrepPrompt_Simple
noremap <silent> <Leader>g :call <SID>GrepPrompt_Simple("", 0, 0, 0)<CR>
inoremap <silent> <Leader>g <C-O>:call <SID>GrepPrompt_Simple("", 0, 0, 0)<CR>
"cnoremap <silent> <unique> <Leader>g <C-C>:call <SID>GrepPrompt_Simple("", 0, 0, 0)<CR>
" Can't do unique on onoremap 'cause it's already set?
" onoremap <silent> <unique> <Leader>g <C-C>:call <SID>GrepPrompt_Simple("", 0, 0, 0)<CR>
" Selected word
"vnoremap <silent> <Leader>g :<C-U>call <SID>GrepPrompt_Auto_Ask_Location(<C-R>)<CR>
"vnoremap <Leader>g :<C-U>echo "Hello ". @"

" NOTE I'm not sure we need to store registers like this but we do
"vnoremap <Leader>g :<C-U>
"  \ let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
"  \ gvy
"  \ :call <SID>GrepPrompt_Simple(@@, 0, 0, 0)<CR>
"  \ gV
"  \ :call setreg('"', old_reg, old_regtype)<CR>
" Better: (keeps stuff selected)
vnoremap <silent> <Leader>g :<C-U>
  \ <CR>gvy
  \ :call <SID>GrepPrompt_Simple(@@, 0, 0, 0)<CR>

"xnoremap <silent> <Leader>g <C-U>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R><C-R>")<CR>
"snoremap <silent> <Leader>g <C-U>:call <SID>GrepPrompt_Auto_Ask_Location("<C-R>")<CR>

" 2015.06.11: Early birthday present: Case-sensitive, for
"             when you want ag to recognize all-lowercase.
noremap <silent> <Leader>G :call <SID>GrepPrompt_Simple("", 0, 1, 0)<CR>
inoremap <silent> <Leader>G <C-O>:call <SID>GrepPrompt_Simple("", 0, 1, 0)<CR>
vnoremap <silent> <Leader>G :<C-U>
  \ <CR>gvy
  \ :call <SID>GrepPrompt_Simple(@@, 0, 1, 0)<CR>

" Limit search results to one per file, if you
" just want an idea which files contain matches.
noremap <silent> <Leader>C :call <SID>GrepPrompt_Simple("", 0, 0, 1)<CR>
inoremap <silent> <Leader>C <C-O>:call <SID>GrepPrompt_Simple("", 0, 0, 1)<CR>
vnoremap <silent> <Leader>C :<C-U>
  \ <CR>gvy
  \ :call <SID>GrepPrompt_Simple(@@, 0, 0, 1)<CR>

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
  call s:GrepPrompt_Simple("", s:simple_grep_last_i, 0, 0)
endfunction

function s:GrepPrompt_Auto_Prev_Location(term)
  if a:term != ""
    call s:GrepPrompt_Simple(a:term, s:simple_grep_last_i, 0, 0)
  endif
endfunction

function s:GrepPrompt_Auto_Ask_Location(term)
  if a:term != ""
    call s:GrepPrompt_Simple(a:term, 0, 0, 0)
  endif
endfunction

" Toggle GrepCase
" ------------------------------------------------------
" I.e., search for exact work; or include case permutations,
" e.g., search for FOO_BAR; or include fooBar, foo_bar, foo-bar.

"unmap <silent> <unique> <Leader>c
"map <silent> <unique> <Leader>c let g:DubsGrepSteady_GrepAllTheCases
"  \ = !g:DubsGrepSteady_GrepAllTheCases<CR>
"nnoremap <buffer> <silent> <LocalLeader>c :call <SID>Toggle_GrepAllTheCases()<CR>
"
"if !hasmapto('<SID>Toggle_GrepAllTheCases')
map <silent> <unique> <Leader>c :call <SID>Toggle_GrepAllTheCases()<CR>
"endif

let g:DubsGrepSteady_GrepAllTheCases = 0

function! s:Toggle_GrepAllTheCases()
  let g:DubsGrepSteady_GrepAllTheCases = !g:DubsGrepSteady_GrepAllTheCases
  if (g:DubsGrepSteady_GrepAllTheCases == 0)
    echomsg 'Grep back to normal'
  else
    echomsg 'Grep match-all-the-cases'
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

" Obsolete. Has since been extracted and templatized... [see previous block]
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

  " A map of ds_simple_grep_locat_lookup indices to ag --options.
  " E.g., let g:ds_simple_grep_ag_options_map = {
  "         \ '13': '--skip-vcs-ignores' }
  let g:ds_simple_grep_ag_options_map = {}

endif

" ------------------------------------------------------
" ------------------------------------------------------
" ------------------------------------------------------

