function lg --wraps=lazygit --wraps=lazygit\;\ printf\ \"\\003\[2J\\033H\" --wraps=lazygit\;\ printf\ \"\\003\[2J\\033\[H\" --wraps='lazygit; reset' --description 'alias lg lazygit'
  lazygit $argv
        
end
