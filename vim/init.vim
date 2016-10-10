" Tips, just note here to be referenced and edit easily {{{
"
" Y: copy from cursor to end of line (like C)
" <leader>cb (or cc): comment align (or without align) [nerdtree-commenter]
" vipga=: exaple of align paragraph by `=` [easyalign]
" htlm:5_: <c-y><leader>	[emmet]
" <leader>g: goto definition [ycm]
" <leader>G: go to references [ycm]
" <Visual>=: re-indent visual block (eg: ggVG= or gg=G)
" <C-n>: toggle relative/absolute number
"
" Snips:
"   #!<C-j> -> python header utf-8
" TernDef, TernRefs, TernRename for jump to def, find references, rename thing
" under cursor
"
" }}}

" Plugins {{{

call plug#begin('~/.config/nvim/plugged')

" themes, colors
Plug 'dracula/vim'

" text, align
Plug 'junegunn/vim-easy-align'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'scrooloose/nerdcommenter'
Plug 'nathanaelkane/vim-indent-guides'

" navigation
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] } | Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'mileszs/ack.vim'
Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
Plug 'powerline/fonts'
Plug 'majutsushi/tagbar'
Plug 'easymotion/vim-easymotion'

" git
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" python
Plug 'klen/python-mode', { 'for': 'python' }
Plug 'mitsuhiko/vim-python-combined', { 'for': 'python' }
call plug#end()

" }}}


" General {{{

" encode
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8

" require for plugins
set nocompatible        " Must be first line
syntax on               " syntax highlight
filetype plugin indent on      " Indent and plugins by filetype

" true color
set termguicolors

" copy/paste
if has('clipboard')
    " When possible use + register for copy-paste
    set clipboard=unnamed,unnamedplus
endif

" [keys mapping]
let mapleader = ','
let g:mapleader = ','

" Visual shifting (does not exit Visual mode)
vnoremap < <gv
vnoremap > >gv

" save as root w!!
cmap w!! w !sudo tee % >/dev/null<CR>:e!<CR><CR>

" [Tab]
" set noexpandtab " insert tabs rather than spaces for <Tab>
set smarttab " tab respects 'tabstop', 'shiftwidth', and 'softtabstop'
" insert spaces rather tabs
set shiftwidth=4 tabstop=4 softtabstop=4 expandtab autoindent
set shiftround " round indent to a multiple of 'shiftwidth'
set splitright                  " Puts new vsplit windows to the right of the current
set splitbelow                  " Puts new split windows to the bottom of the current


" [Linenumber]
set relativenumber " default is relative mode
set number

" [Text]
set ruler               " show current column
set showcmd             " show command in bottom bar
set cursorline          " highlight current line
set wildmenu            " visual autocomplete for command menu
set wildmode=list:longest,full  " Command <Tab> completion, list matches, then longest common part
set showmatch           " highlight matching [{()}]
set incsearch                   " Find as you type search
set hlsearch                    " Highlight search terms
set ignorecase          " Case insensitive search
set smartcase
nmap <silent> <leader><space> :set invhlsearch<CR>        " Toggle highlight search research
" highlight clear SignColumn      " SignColumn should match background
" highlight ColorColumn ctermbg=red ctermfg=red
set colorcolumn=81

" [Buffer]
" Most prefer to automatically switch to the current file directory when
" a new buffer is opened; no_auto_chdir
" Always switch to current file dir
autocmd BufEnter * if bufname("") !~ "^\[A-Za-z0-9\]*://" | lcd %:p:h | endif
" Allow buffer switching without saving
" Prevent message: no write since last change (add !)
set hidden                          "

" [Trailing]
" eol:¬
set listchars=tab:›\ ,trail:•,extends:#,nbsp:. " Highlight problematic whitespace
set list

" highlight conflicts
match ErrorMsg '^\(<\|=\|>\)\{7\}\([^=].\+\)\?$'

" [Theme]
colorscheme dracula

" }}}


" Programing {{{

" NerdTree
map <C-e> :NERDTreeToggle<CR>
map <leader>e :NERDTreeFind<CR>
nmap <leader>nt :NERDTreeFind<CR>
let NERDTreeShowBookmarks=1
let NERDTreeIgnore=['\.py[cd]$', '\~$', '\.swo$', '\.swp$', '^\.git$', '^\.hg$', '^\.svn$', '\.bzr$', 'build', 'venv', 'egg', 'egg-info/', 'dist', 'docs', '.coveragerc', '.dockerignore', '.editorconfig', '.gitattributes', '.gitignore', '.pylintrc', '.travis.yml']
let NERDTreeChDirMode=0
let NERDTreeQuitOnOpen=1
let NERDTreeMouseMode=2
let NERDTreeShowHidden=1
let NERDTreeKeepTreeInNewTab=1
let g:NERDShutUp=1
" let g:nerdtree_tabs_open_on_gui_startup=0


" Python mode
let g:pymode_virtualenv = 1
let g:pymode_trim_whitespaces = 0
" Use Jedi (ready in YouCompleteMe) instead of Rop python mode
" https://github.com/davidhalter/jedi-vim/issues/163
let g:pymode_options = 0
let g:pymode_rope = 0
let g:pymode_folding = 0

" Enable breakpoints plugin
let g:pymode_breakpoint = 1
let g:pymode_breakpoint_bind = '<leader>b'

" Disable if python support not present
if !has('python') && !has('python3')
    let g:pymode = 0
endif

" Fugitive
nnoremap <silent> <leader>gs :Gstatus<CR>
nnoremap <silent> <leader>gd :Gdiff<CR>
nnoremap <silent> <leader>gc :Gcommit<CR>
nnoremap <silent> <leader>gb :Gblame<CR>
nnoremap <silent> <leader>gl :Glog<CR>
nnoremap <silent> <leader>gp :Git push<CR>
nnoremap <silent> <leader>gr :Gread<CR>
nnoremap <silent> <leader>gw :Gwrite<CR>
nnoremap <silent> <leader>ge :Gedit<CR>
" Mnemonic _i_nteractive
nnoremap <silent> <leader>gi :Git add -p %<CR>
nnoremap <silent> <leader>gg :SignifyToggle<CR>


" Ack
if executable('ag')
    let g:ackprg = 'ag --nogroup --nocolor --column --smart-case'
elseif executable('ack-grep')
    let g:ackprg="ack-grep -H --nocolor --nogroup --column"
endif


" CtrlP
let g:ctrlp_match_window = 'bottom,order:ttb'
let g:ctrlp_switch_buffer = 0
let g:ctrlp_working_path_mode = 'ra'       " 'ra'
let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden -g ""'
let g:ctrlp_custom_ignore = {
    \ 'dir':  '\.git$\|\.hg$\|\.svn|\.env$',
    \ 'file': '\.exe$\|\.so$\|\.dll$\|\.pyc|\.class$' }

if executable('ag')
    let s:ctrlp_fallback = 'ag %s --nocolor -l -g ""'
elseif executable('ack-grep')
    let s:ctrlp_fallback = 'ack-grep %s --nocolor -f'
elseif executable('ack')
    let s:ctrlp_fallback = 'ack %s --nocolor -f'
endif


" Airline
let g:airline_theme = 'powerlineish'
let g:airline_powerline_fonts=1
" let g:airline_left_sep          = '▶'
let g:airline_left_alt_sep      = '»'
" let g:airline_right_sep         = '◀'
let g:airline_right_alt_sep     = '«'
let g:airline_left_sep='›'
let g:airline_right_sep='‹'
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#tagbar#enabled = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#whitespace#enabled = 1
let g:airline#extensions#hunks#non_zero_only = 1
let g:airline#extensions#virtualenv#enabled = 1

" }}}
