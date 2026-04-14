# ====================================
# oh-my-zsh oh-my-zsh oh-my-zsh oh-my-zsh oh-my-zsh 
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh
# ====================================

# ==================================== 
# nvim nvim nvim nvim nvim nvim nvim nvim  
alias vim="nvim"
export EDITOR="vim"
export PATH=$PATH:$HOME/go/bin
# ==================================== 

# python
export PATH="/opt/homebrew/opt/python/libexec/bin:$PATH"

# node
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PATH="$HOME/fxpro/local_script/:$PATH"
export PATH="/opt/homebrew/opt/jupyterlab/bin/:$PATH"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fd
[ -f ~/.fd.zsh ] && source ~/.fd.zsh
export PATH="$HOME/.local/bin:$PATH"

