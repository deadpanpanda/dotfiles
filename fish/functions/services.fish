function services --wraps='bash ~/dotfiles/dev-services.sh' --wraps='bash /projects/dotfiles/dev-services.sh' --description 'alias services bash /projects/dotfiles/dev-services.sh'
  bash /projects/dotfiles/dev-services.sh $argv
        
end
