" General
let mapleader = ","
set nobackup
set hidden
set modelines=0
set ttyfast
set mouse-=a

" Edit
set encoding=utf-8
set shiftwidth=4
set whichwrap=b,s,h,l,<,>,[,]
set backspace=indent,eol,start
set autoread
set noswapfile

" Search
set wrapscan
set ignorecase
set smartcase
set hlsearch

" Appearance
set number
set list
set tabstop=4
set scrolloff=5
set textwidth=0
set showmatch
set lazyredraw
set ruler
set laststatus=2
set showcmd
set showmode
set notitle
set background=dark
syntax enable
colorscheme iceberg
highlight ZenkakuSpace cterm=underline ctermfg=lightblue guibg=darkgray
match ZenkakuSpace /　/
