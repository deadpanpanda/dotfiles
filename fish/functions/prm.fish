function prm --description 'Push branch, open PR, queue auto-merge (squash)'
    set -l branch (git symbolic-ref --short HEAD)
    if test "$branch" = main -o "$branch" = master
        echo "prm: refusing to run on $branch" >&2
        return 1
    end

    git push -u origin HEAD; or return $status
    gh pr create --fill $argv; or return $status
    gh pr merge --auto --squash
end
