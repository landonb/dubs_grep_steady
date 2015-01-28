Dubsacks Vim — Grep Steady
==========================

About This Plugin
-----------------

This plugin sets up a powerful text search utility.

Installation
------------

Standard Pathogen installation:

.. code-block:: bash

   cd ~/.vim/bundle/
   git clone https://github.com/landonb/dubs_grep_steady.git

Or, Standard submodule installation:

.. code-block:: bash

   cd ~/.vim/bundle/
   git submodule add https://github.com/landonb/dubs_grep_steady.git

Online help:

.. code-block:: vim

   :Helptags
   :help dubs-grep-steady

Prerequisities
^^^^^^^^^^^^^^

This script uses an external grep utility, preferably
`The Silver Searcher <http://geoff.greer.fm/ag/>`__
(``/usr/bin/ag``) but alternatively
falls back on ``egrep``.
The former is a tad faster and it honors ``.agignore``
and ``.gitignore`` files, which makes it easy to filter
out the cruft.

Run ``sudo apt-get install -y ag`` to install Silver Searcher.

Plugin Setup
^^^^^^^^^^^^

After installing this plugin and first running Vim,
Dubsacks will copy the ``dubs_projects.vim.template``
file to ``dubs_grep_steady/dubs_projects.vim``.

Find and open the file and follow the instructions therein.
Basically, add your project paths to the file, and when you
search, you'll be asked to choose one of the project paths
you defined as the base of the search.

You can still search any arbitrary directory when grepping,
but if you find yourself searching the same project folders
often, setting up the ``dubs_projects.vim`` file can save you
from repeating yourself anytime you search.

Searching Files
---------------

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
===========================  ============================  ==============================================================================================

