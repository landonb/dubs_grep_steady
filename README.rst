##############################
Dubs Vim |em_dash| Grep Steady
##############################

.. |em_dash| unicode:: 0x2014 .. em dash

About This Plugin
=================

This plugin sets up a powerful text search utility.

Installation
============

Installation is easy using the packages feature (see ``:help packages``).

To install the package so that it will automatically load on Vim startup,
use a ``start`` directory, e.g.,

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/start
    cd ~/.vim/pack/landonb/start

If you want to test the package first, make it optional instead
(see ``:help pack-add``):

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/opt
    cd ~/.vim/pack/landonb/opt

Clone the project to the desired path:

.. code-block:: bash

    git clone https://github.com/landonb/dubs_grep_steady.git

If you installed to the optional path, tell Vim to load the package:

.. code-block:: vim

   :packadd! dubs_grep_steady

Just once, tell Vim to build the online help:

.. code-block:: vim

   :Helptags

Then whenever you want to reference the help from Vim, run:

.. code-block:: vim

   :help dubs-grep-steady

Prerequisites
-------------

This script uses an external grep utility.

The author prefers
`ripgrep <https://github.com/BurntSushi/ripgrep>`__
(``rg``),
but you can also use
`The Silver Searcher <http://geoff.greer.fm/ag/>`__
(``ag``),
or, alternatively, if neither of those is installed,
the plugin falls back on ``egrep``.

Why ripgrep? It's blazing fast
and does a good job honoring ``.ignore`` files.

You can download and install ripgrep from the list of
`ripgrep releases <https://github.com/BurntSushi/ripgrep/releases>`__
(just add its binary to your ``$PATH``, or symlink it from a directory
already on your user's path).

This plugin also requires
`Pathogen <https://github.com/tpope/vim-pathogen>`__
(but just for the simple ``pathogen#split`` command;
you're not expected to manage this plugin with Pathogen).

Plugin Setup
------------

You can search like normal, e.g.,::

  :grep "search-phrase" "path/to/search"

And you can also wire frequently-searched locations,
to make searching frequently-accessed projects quicker.

- After installing this plugin and first running Vim,
  Dubs Vim will copy the ``dubs_projects.vim.template``
  file to ``dubs_grep_steady/dubs_projects.vim``.

- Find and open the file and follow the instructions therein.
  Basically, add your project paths to the file, and when you
  search, you'll be asked to choose one of the project paths
  you defined as the base of the search.

You can still search any arbitrary directory when grepping,
but if you find yourself searching the same project folders
often, setting up the ``dubs_projects.vim`` file can save you
from repeating yourself anytime you search.

Searching Files
===============

===========================  ============================  ==============================================================================================
Key Mapping                  Description                   Notes
===========================  ============================  ==============================================================================================
``\g``                       Search in Project Files       Press backslash and then 'g' to start a new egrep search.
                                                           If you've selected text, that'll be used for the search, otherwise,
                                                           you'll be asked for the term you want to search.
                                                           Next, you'll be asked which project folders to search.
                                                           Finally, you'll see the results of your search in the Quickfix window.
                                                           Hint: The search uses regular expressions, so you might have to escape certain symbols.
                                                           Double hint: If you're using ``ag``, The Silver Searcher, then the search is
                                                           case-insensitive if your search term is all lowercase; otherwise, if the
                                                           search term contains one or more uppercase characters, the search is case-sensitive.
---------------------------  ----------------------------  ----------------------------------------------------------------------------------------------
``\g {up and down}``         Peruse-Iterate                Cycles through your search history so you can re-search a previously-searched term.
                             Search History
---------------------------  ----------------------------  ----------------------------------------------------------------------------------------------
``<Shift-F4>``               Search Selected               If there's a selection, searches that, otherwise selects the word under the
                             or Under Cursor               cursor and searches that; prompts you for the project location to search.
                             w/ Location Prompt
---------------------------  ----------------------------  ----------------------------------------------------------------------------------------------
``<F4>``                     Fast Search Selected          If there's a selection, searches that, otherwise selects the word under the
                             or Under Cursor               cursor and searches that; does not prompt you for the project location to
                                                           search but uses the last-searched location (or prompts you for the location
                                                           if you haven't done a project search yet since you started Vim).
---------------------------  ----------------------------  ----------------------------------------------------------------------------------------------
``<Ctrl-F4>``                Search New without            Asks you for the search term and then searches the last-searched project location.
                             Location Prompt               Caveat: You'll probably find yourself using ``\g`` more often than this command.
---------------------------  ----------------------------  ----------------------------------------------------------------------------------------------
``:gr! "<regex>" "<dir>"``   Search in Any Location        To search locations that are not in the project list, use the raw grep command.
---------------------------  ----------------------------  ----------------------------------------------------------------------------------------------
``\c``                       Toggle Alternative Casing     When enabled, searches alternative casings, e.g., a search for a camelCase
                                                           word, such as ``fooBar``, would also includes results for that word in train-case,
                                                           ``foo-bar``, as well as snake_case, ``foo_bar``.
===========================  ============================  ==============================================================================================

Tips 'n Tricks
==============

Find Non-Ascii Characters
-------------------------

To exclude ASCII values when searching, use the search query:

.. code-block:: vim

    /[^\x00-\x7F]

Find Whole Words
----------------

When using The Silver Searcher to search multiple documents,
e.g., after typing ``\g``, use the boundary identifer, ``\b``.

For example, ``\bthing\b`` finds instances of 'thing' but not 'things'
or 'something', etc.

However, when searching within a file, e.g., after typing ``/``,
use the boundary identifiers, ``\<`` and ``\>.``

For example, ``\<thing\>`` finds uses of the whole word, 'thing'.

Find Alternative Casings
------------------------

You might find yourself working on codebases where similar
constructs might be named the same except for casing,

You can use ``\c`` to toggle between searching for exactly your search phrase,
and searching on case mutations of the phrase (camelCase, snake_case, and train-case).

Keeping Long Result Lines from the Quickfix
-------------------------------------------

Configure the ``DUBS_VIM_RG_MAX_COLS`` environment
in ``bin/vim-grepprg-rg-sort`` to limit the length
of search results when using ripgrep (``rg``).

It defaults to 200, so that long results lines are kept out of the quickfix
results, which this author finds makes scanning the results more difficult.

