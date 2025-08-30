source $VIMRUNTIME/defaults.vim

" Basic settings
set expandtab
set autoindent
set number
set hlsearch
set incsearch

" Color scheme configuration
try
  colorscheme slate " for some reason this is needed, otherwise retrobox is very bright
  colorscheme retrobox
  catch
  try
    colorscheme desert
    catch
  endtry
endtry