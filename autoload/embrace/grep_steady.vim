" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/dubs_grep_steady#🧐
" License: GPLv3
"   Copyright © 2009, 2015, 2017, 2020, 2024-2025 Landon Bouma.
" Summary: Dubs Vim Text Search Commands

" ------------------------------------------------------
" Choose the Best Search Utility
" ------------------------------------------------------

" In order of preference, this script prefers to use ripgrep,
" then The Silver Searcher, and then egrep.
" - On large projects, you should notice that ripgrep is
"   noticeably faster then ag, and that ag is faster than
"   egrep.
" - On Windows (which hasn't been verified in over 10
"   years), the default searcher is findstr, so this code
"   ensures we use Cygwin's grep.

let s:using_ag = -1
let s:using_rg = -1

" (lb) Some history:
"
" - 2017-09-13: I switched from `ag` to `rg`.
"   - The API differences are: `ag -U` → `rg --no-ignore-vcs`;
"     and if not in a tty, ripgrep doesn't spit out line numbers
"     (so specify --line-number).
" - 2018-05-06: I enabled sorted search results.
"   - This produces deterministic results, i.e.,
"     now when you repeat the same search, the quickfix window
"     not only shows the same results, but in the same order.
"   - Note that using ripgrep's sort affects speed. Says ripgrep:
"       'Sort ... disables ... parallelism and runs ... in a single thread.'
"   - Note that `rg --sort-files` sorts the results, but not alphabetically.
"       set grepprg=rg\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --no-ignore-vcs\
"         \ --line-number\ --no-heading\ --with-filename\ --sort-files
"   - To sort alphabetically, we'll instead use the system `sort` command.
"     - But note that Vim doesn't pipe, so we use an external script.

function! s:SetGrepprgRg() abort
  let s:using_ag = 0
  let s:using_rg = 1

  " Use the path to this script to find the grep script.
  " - CXREF:
  "   ~/.kit/nvim/landonb/start/dubs_grep_steady/bin/vim-grepprg-rg-sort
  " - Note it's :h:h:h to remove 'autoload/embrace/grep_steady.vim':
  "   ~/.kit/nvim/landonb/start/dubs_grep_steady/autoload/embrace/grep_steady.vim
  let l:ripgrep_shim = expand('<script>:h:h:h') .. '/bin/vim-grepprg-rg-sort'

  if exists("g:DUBS_GREP_STEADY_GREPPRG_SCRIPT")
    let l:ripgrep_shim = g:DUBS_GREP_STEADY_GREPPRG_SCRIPT
  endif

  if executable(l:ripgrep_shim)
    execute 'set grepprg=' . l:ripgrep_shim
  else
    " SYNC: set grepprg=rg
    set grepprg=rg\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --no-ignore-vcs\ --line-number\ --no-heading\ --with-filename
  endif
endfunction

function! s:SetGrepprgAg() abort
  let s:using_ag = 1
  let s:using_rg = 0

  " The Silver Searcher options:
  "   -A --after [LINES]      Print lines before match (Default: 2).
  "   -B --before [LINES]     Print lines after match (Default: 2).
  "   -S --smart-case         Match case insensitively unless
  "                           PATTERN contains uppercase characters.
  "   -f --follow             Follow symlinks.
  "   -U --skip-vcs-ignores   Ignore VCS ignore files
  "                           (.gitignore, .hgignore; still obey .ignore)
  " SYNC: set grepprg=ag
  set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ -U
endfunction

function! s:SetGrepprgGrep() abort
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
  " REFER: --exclude-from file (grep-exclude) only specifies files to ignore.
  " - Use --exclude-dir to ignore directories by name (but not path), e.g.,
  "         set grepprg=egrep\ --exclude-dir=\"build\"\ ...
  " DUNNO: egrep let's you specify basenames to ignore using a file, but
  "        directories to ignore must be specified on the command line, and
  "        there's no way to exclude files based on a more complete path?
  if filereadable($HOME . "/.vim/grep-exclude")
    " *nix w/ egrep
    set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"$HOME/.vim/grep-exclude\"
  elseif filereadable($USERPROFILE . "/vimfiles/grep-exclude")
    " Windows w/ egrep
    set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"$USERPROFILE/vimfiles/grep-exclude\"
  else
    let l:files = s:FindFile('grep-exclude')
    if !empty(l:files)
      execute 'set grepprg=egrep\ -n\ -R\ -i\ --exclude-from=\"' . l:files[0] . '\"'
    else
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

function! s:SetGrepprg() abort
  if executable("rg")
    call s:SetGrepprgRg()
  elseif executable("ag")
    call s:SetGrepprgAg()
  else
    call s:SetGrepprgGrep()
  endif
endfunction

call s:SetGrepprg()

" -------------------------------------------------------------------

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Setup Search Features
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" STOLEN! From vim-abolish. Shameless!!
" - MAYBE/2018-06-27: DRY this: Make a shared #autoload plugin?
" USYNC: Not DRY: Found in: vim-abolish, dubs_grep_steady, and vim-blinky-search.

function! s:camelcase(word) abort
  let word = substitute(a:word, '-', '_', 'g')
  if word !~# '_' && word =~# '\l'
    return substitute(word,'^.','\l&','')
  else
    return substitute(word,'\C\(_\)\=\(.\)','\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
  endif
endfunction

function! s:snakecase(word) abort
  let word = substitute(a:word,'::','/','g')
  let word = substitute(word,'\(\u\+\)\(\u\l\)','\1_\2','g')
  let word = substitute(word,'\(\l\|\d\)\(\u\)','\1_\2','g')
  " This substitute is too naive, and converts escaped dots, e.g.,
  "     let word = substitute(word,'[.-]','_','g')
  " would convert a search on, say, `3\.7`, to `3\_7`,
  " which confuses grepprg when |'d with the other case snippets.
  " So use a negative look-behind to ensure no preceeding escape!
  " - The syntax for look-behind -- \@<! -- comes after the thing
  "   behind sought, which here is an escaped escape -- \\ -- so
  "   the full look-behind is \\\@<!
  let word = substitute(word,'\\\@<![.-]','_','g')
  let word = tolower(word)
  return word
endfunction

" A/k/a kebab-case | spinal-case | Train-Case | Lisp-case | dash-case
function! s:traincase(word) abort
  return substitute(s:snakecase(a:word),'_','-','g')
endfunction

function! s:uppercase(word) abort
  return toupper(s:snakecase(a:word))
endfunction

" ***

let s:simple_grep_last_i = 0

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
function g:embrace#grep_steady#GrepPrompt_Simple(term, locat_index, case_sensitive, limit_matches) abort
  call inputsave()

  let l:the_term = a:term

  if l:the_term == ''
    " There's a newline in the buffer, so call inputsave
    "call inputsave()
    let l:the_term = input("Search for: ")
    "call inputrestore()
    "echo "The term is" . l:the_term
    "let TBD = input("Hit any key to continue: ")
    " Ensure the "Search in:" starts on new line.
    echo "\n"
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
        if !exists("g:ds_simple_grep_rg_options_map")
          let l:options = ''
        else
          let l:options = get(g:ds_simple_grep_rg_options_map, l:new_i, '')
        endif
      elseif s:using_ag == 1
        if !exists("g:ds_simple_grep_ag_options_map")
          let l:options = ''
        else
          let l:options = get(g:ds_simple_grep_ag_options_map, l:new_i, '')
        endif
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

      " [lb]: Be aware of another option to ignore .ignore files up a
      "   path's hierarchy -- --no-ignore-parent -- which only makes
      "   tracking down why a file is being ignored a little harder,
      "   but is not a behavior we should enable.
      " Limit matches flags.
      if s:using_ag == 1
        if a:limit_matches == 0
          " SYNC: set grepprg=ag
          set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ -U
        else
          " The Silver Search says "ERR: Too many matches" for each file
          " after printing one line, but the errs come randomly from a thread
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
          " SYNC: set grepprg=ag
          set grepprg=ag\ -A\ 0\ -B\ 0\ --hidden\ --follow\ --max-count\ 1\ "$*"
        endif
      else
        " RipGrep and Grep both support --max-count.
        if a:limit_matches != 0
          let l:options = l:options . " --max-count 1"
        endif
      endif

      " Enable multiline if there's a newline escape sequence in the query.
      " - Note we use single quotes because query shouldn't contain actual
      "   newline, just the literal representation.
      " - User must double-escape literal newline, which we sub-out so we
      "   don't confuse our check.
      " - Note that to match a single backslash \, user must input four \\\\
      "   of them, because the input() prompt will resolve \\ → \ and \\ → \,
      "   and then grep prompt resolves \\ → \ (at least that's what I think).
      if s:using_rg && stridx(substitute(l:the_term, '\\\\n', '', 'g'), '\n') >= 0
        let l:options = l:options . " --multiline"
      endif

      " 2018-03-29: Crude implementation of caseless-grep.
      " - 2021-01-31: Updated to only add simple query to the history lists,
      "   and not the complicated query.
      "   - For a while, this had been calling histadd() on both l:the_term
      "     (the simple query) and also on l:new_term (the complicated
      "     `camel|snake|train` query). Besides the fact that I never used the
      "     complicated query from history, if you did, you'd end up with the
      "     complicated query having the 3 casings regex applied again, e.g.,
      "     this would be searched on and what you'd see this in history:
      "       `camel|snake|train|camel|snake|train|camel|snake|train`
      "   - We could check if pipe character in the term, e.g.,
      "       stridx(l:the_term, '|') == -1
      "     but we also don't need the complicated query in history,
      "     as this function will just run again and reformulate it
      "     when you choose the simple query term from the history.
      let l:new_term = l:the_term

      if a:case_sensitive == 0 && g:DubsGrepSteady_GrepAllTheCases
        " Search on 3 casings: Camel, Snake, and Train. Only for \g, not \G.
        " NOTE: Converting to snakecase downcases it.
        let l:new_term = ''
          \ . tolower(l:the_term) . "\\|"
          \ . tolower(s:camelcase(l:the_term)) . "\\|"
          \ . tolower(s:snakecase(l:the_term)) . "\\|"
          \ . tolower(s:traincase(l:the_term))

        call histadd("input", l:new_term)
        call histadd("search", l:new_term)
      else
        " 2018-06-27: Whoa, how did I not know about histadd??! This is **AWESOME**!!
        "  Add the search term to the _input_ history. E.g., if user is on a word and
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
        call histadd("search", tolower(l:new_term))
        " NOTE: If user greps for words matches, e.g., "\bword\b", the / history
        "       pattern won't work because of the difference in the word delimiters,
        "       e.g., the equivalent word history boundary in / is "\<word\>".
      endif

      " Ensure user's raw search term is MRU by adding last.
      call histadd("input", l:the_term)
      call histadd("search", l:the_term)

      " 2018-03-29: Crude implementation of caseless-grep.
      if a:case_sensitive == 0 && g:DubsGrepSteady_GrepAllTheCases
        " Search on 3 casings: Camel, Snake, and Train. Only for \g, not \G.
        " NOTE: Converting to Snake_Case downcases it.
        let l:srch_term = "--ignore-case \"" . l:new_term . "\""
      else
        let l:srch_term = "\"" . l:new_term . "\""
      endif

      " Change Vim's working directory to the root of the search directory,
      " so that Vim shows partial paths relative to that path.
      exec "cd " . split(l:locat)[0]

      " HINT: Try: `:verbose set grepprg` and `:verbose gr` to see what happened.
      execute "silent gr! " . l:options . " " . l:srch_term . " " . l:locat

      cd -

      let s:simple_grep_last_i = l:new_i

      if exists(':QFix')
        " CXREF: https://github.com/landonb/dubs_quickfix_wrap#🌯
        :QFix!(0)
      else
        " ALTLY: We could let user specify default height, e.g.:
        "  execute "botright copen " . g:grep_steady_qf_height
        botright copen
      endif
    endif
  endif

  call inputrestore()
endfunction

function s:GrepPrompt_Simple_GetInputlist(i_highlight) abort
  let ilist = [g:ds_simple_grep_locat_lookup[0]]

  for i in range(1, g:ds_simple_grep_locat_lookup_len - 1)
    let ilist = add(ilist, s:GrepPrompt_Simple_GetInputlistItem(
      \ i, i == a:i_highlight))
  endfor

  return ilist
endfunction

function s:GrepPrompt_Simple_GetInputlistItem(idx, do_highlight) abort
  let l:listitem = "    "
  if a:do_highlight
    let l:listitem = "(*) "
  endif

  " Pad the list item numbers using the number of digits in the list len.
  " E.g., if there are 42 list entries, the length of '42' is '2'.
  let l:num_digits = len(g:ds_simple_grep_locat_lookup_len)
  " https://stackoverflow.com/questions/4964772/string-formatting-padding-in-vim
  " POSTPADDING: let l:posit_cnt = printf('Line: %-*u ==>> %-*s ==>> FilePath %s', 8, linenum, 12, errmsg, path)
  let l:posit_cnt = printf('%*u', l:num_digits, a:idx)

  let l:listitem .= l:posit_cnt . ". " . g:ds_simple_grep_locat_lookup[a:idx]

  return l:listitem
endfunction

" -------------------------------------------------------------------

" ------------------------------------------------------
" Search Mappings
" ------------------------------------------------------

function g:embrace#grep_steady#GrepPrompt_Term_Prev_Location(term)
  call g:embrace#grep_steady#GrepPrompt_Simple("", s:simple_grep_last_i, 0, 0)
endfunction

function g:embrace#grep_steady#GrepPrompt_Auto_Prev_Location(term)
  if a:term != ""
    call g:embrace#grep_steady#GrepPrompt_Simple(a:term, s:simple_grep_last_i, 0, 0)
  endif
endfunction

function g:embrace#grep_steady#GrepPrompt_Auto_Ask_Location(term)
  if a:term != ""
    call g:embrace#grep_steady#GrepPrompt_Simple(a:term, 0, 0, 0)
  endif
endfunction

" -------------------------------------------------------------------

let g:DubsGrepSteady_GrepAllTheCases = 0

function! g:embrace#grep_steady#Toggle_GrepAllTheCases() abort
  let g:DubsGrepSteady_GrepAllTheCases = !g:DubsGrepSteady_GrepAllTheCases
  if (g:DubsGrepSteady_GrepAllTheCases == 0)
    echom 'Grep back to normal'
  else
    echom 'Grep match-all-the-cases'
  endif
endfunction

" -------------------------------------------------------------------

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Default Search Directory Choices
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
" DEVS: Override this list using a dubsgrep_blah.vim script,
"       or dubs_grep_steady/dubs_projects.vim.
" ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

" Hint: For locations searched frequently, avoid numbers '6' through '0'
"       so you can type it out using just the left hand.

" NOTE: If you want to map two or more directories to the same number,
"       use spaces, e.g.,
"         \ "/path/to/foo "
"         \ . "/path/to/bar "
"         \ . "/baz/bat ",
"       or, better yet, to align the paths, start with empty string, e.g.,
"         \ ""
"         \ . "/path/to/foo "
"         \ . "/path/to/bar "
"         \ . "/baz/bat ",

" NOTE: The numbers are just placeholders. Replace them with
"       project directories, leave them alone, or delete them.
"       However, because of the line continuation backslash,
"       you cannot use comments to indicate the number mappings
"       in the array definition (so if you fill the whole array
"       with paths, you won't easily be able to tell what paths
"       are at which index).

function! s:LoadDefaultGrepProjectsLookup() abort
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

  let g:ds_simple_grep_rg_options_map = {}
  let g:ds_simple_grep_ag_options_map = {}
endfunction

function! s:EnsureGrepProjectsLookupSetup() abort
  let g:ds_simple_grep_locat_lookup_len =
    \ len(g:ds_simple_grep_locat_lookup)

  " It's okay if these maps are left undefined.
  "   let g:ds_simple_grep_rg_options_map = {}
  "   let g:ds_simple_grep_ag_options_map = {}
endfunction

" ***

" MAYBE/2025-01-24: Rather than search rtp's for file, have user specify path,
"                   e.g., relocate everything to autoload# then have user call,
"                   e.g., `call embrace#grep_stready#load(<path>)` from their
"                   own plugin or plugin manager plugin specs.
let s:user_projs_name = 'dubs_projects.vim'
let s:projs_template = 'dubs_projects.vim.template'

function! s:FindUsersGrepProjects() abort
  " Look for user's projects file.
  let l:files = s:FindFile(s:user_projs_name)
  call s:AlertIfMultipleUsersGrepProjectsFiles(l:files, 'file')

  if !empty(l:files)
    let l:user_projs = l:files[0]
  else
    " No file, but there should be a template we can copy.
    let l:tmplate = ''

    let l:files = s:FindFile(s:projs_template)
    call s:AlertIfMultipleUsersGrepProjectsFiles(l:files, 'template')

    if !empty(l:files)
      let l:tmplate = l:files[0]
    endif

    let l:user_projs = s:DeployUsersGrepProjectsTemplate(l:tmplate)
  endif

  return l:user_projs
endfunction

" COPYD/2025-02-02: FindFile et al shared between two plugins:
"   ~/.kit/nvim/landonb/start/dubs_grep_steady/plugin/dubs_grep_steady.vim
"   ~/.kit/nvim/landonb/start/dubs_project_tray/plugin/dubs_project_tray.vim

function! s:FindFile(fname) abort
  if a:fname == ''

    return []
  endif

  if has('nvim')
    let l:files = s:FindFileAnywhereOnRuntimepath_Nvim(a:fname)
  elseif v:version < 900
    " expand('<script>') is empty
    let l:files = s:FindFileAnywhereOnRuntimepath_Vim(a:fname)
  else
    " FTREQ: Or better yet: Add ~/.config path option.
    let l:files = s:FindFileInProjectOrRuntimeRoot_Vim(a:fname)
  endif

  return l:files
endfunction

function! s:FindFileAnywhereOnRuntimepath_Nvim(fname) abort
  let l:all = 1

  let l:files = nvim_get_runtime_file(a:fname, l:all)

  return l:files
endfunction

" SAVVY: Assumes split(&rtp)[0] is ~/.vim, which is generally the case.
" - ASIDE: In Neovim, root path on &rtp is ~/.config/nvim.
function! s:FindFileInProjectOrRuntimeRoot_Vim(fname) abort
  if pathogen#split(&rtp)[0] == ''
    " Unreachable path.

    return ''
  endif

  let l:fpath = findfile(a:fname, pathogen#split(&rtp)[0] . '/**')

  if l:fpath == ''
    let l:proj_root = expand('<script>:h:h')

    if l:proj_root != ''
      let l:fpath = findfile(a:fname, l:proj_root . '/**')
    endif
  endif

  let l:user_projs = []

  if l:fpath != ''
    " Turn into a full path. See :h filename-modifiers
    let l:user_projs = [fnamemodify(l:fpath, ':p')]
  endif

  return l:user_projs
endfunction

" SAVVY: Alternative to previous fcn, though may take longer.
" - 2025-02-02: Notes from years ago suggest checking every
"   directory takes a while (think someone with 100 plugins
"   and no dubs_projects.vim file therein), but when tested
"   just now, it ran fine (though only checked ~10 paths).
function! s:FindFileAnywhereOnRuntimepath_Vim(fname) abort
  let l:fpath = ""

  for l:rtp_dir in pathogen#split(&rtp)
    let l:try_file = l:rtp_dir . '/' . a:fname

    if filereadable(l:try_file)
      let l:fpath = l:try_file

      break
    endif
  endfor

  let l:user_projs = []

  if l:fpath != ''
    " Turn into a full path. See :h filename-modifiers
    let l:user_projs = [fnamemodify(l:fpath, ':p')]
  endif

  return l:user_projs
endfunction

" ***

function! s:AlertIfMultipleUsersGrepProjectsFiles(matches, what) abort
  if len(a:matches) <= 1

    return
  endif
  
  echom 'ALERT: dubs_grep_steady: Found more than one user projects ' .. a:what .. ':'
  for l:path in a:matches
    echom '  ' .. l:path
  endfor
endfunction

function! s:DeployUsersGrepProjectsTemplate(tmplate) abort
  let l:user_projs = ''

  if a:tmplate != ''
    " Get the full path (:p), and drop the '.template'
    " extension, aka get the filename root (:r).
    let l:user_projs = fnamemodify(a:tmplate, ':p:r')

    if getftype(l:user_projs) != ''
      echom 'ALERT: dubs_grep_steady: Cannot expand grep projects template: Target exists (broken symlink?): ' . l:user_projs

      let l:user_projs = ''
    else
      " Make a copy of the template.
      execute '!command cp ' . a:tmplate . ' ' . l:user_projs

      echom 'dubs_grep_steady: Created user grep projects from template: ' . l:user_projs
    endif
  else
    " This is more of a GAFFE, i.e., more likely it's our error than users's.
    " - I.e., if this script is running, the project root should be on &rtp,
    "   and the template should be within the project directory (and we should
    "   have found it).
    echom 'ALERT: dubs_grep_steady: Could not find grep projects template: ' .. s:projs_template
  endif

  return l:user_projs
endfunction

" ***

function! g:embrace#grep_steady#LoadUsersGrepProjects(echo_on_success) abort
  let s:d_projs = s:FindUsersGrepProjects()

  if s:d_projs != ''
    execute 'source ' . s:d_projs

    if g:ds_simple_grep_default_list_i
      let s:simple_grep_last_i = g:ds_simple_grep_default_list_i
    endif
  else
    echom 'Warning: Dubs Vim could not find dubs_projects.vim'
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
    call s:LoadDefaultGrepProjectsLookup()
  endif
  call s:EnsureGrepProjectsLookupSetup()

  if a:echo_on_success
    echom 'Reloaded grep-steady lookup!'
  endif
endfunction

function! g:embrace#grep_steady#OpenUsersGrepProjects() abort
  let s:d_projs = s:FindUsersGrepProjects()

  exe 'edit ' .. s:d_projs
endfunction

