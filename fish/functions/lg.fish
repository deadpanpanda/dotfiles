function lg --wraps=lazygit --wraps='lazygit; reset' --wraps=lazygit\;\ printf\ \"\\033\[2J\\033\[H\" --description 'alias lg lazygit'
  lazygit $argv
        
end
