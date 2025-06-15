source $VIMRUNTIME/defaults.vim

set expandtab
set autoindent

try
  colorscheme slate " for some reason this is needed, otherwise retrobox is very bright
  colorscheme retrobox
  catch
  try
    colorscheme desert
    catch
  endtry
endtry

