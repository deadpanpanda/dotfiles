function prmi --description 'Push branch, open PR linked to issue #N, queue auto-merge (squash)'
    if test (count $argv) -lt 1
        echo "prmi: usage: prmi <issue-number> [extra gh pr create args...]" >&2
        return 1
    end

    set -l issue $argv[1]
    set -l rest $argv[2..-1]

    if not string match -qr '^[0-9]+$' -- $issue
        echo "prmi: first argument must be an issue number, got: $issue" >&2
        return 1
    end

    set -l branch (git symbolic-ref --short HEAD)
    if test "$branch" = main -o "$branch" = master
        echo "prmi: refusing to run on $branch" >&2
        return 1
    end

    git push -u origin HEAD; or return $status

    set -l title (git log -1 --pretty=%s)
    set -l body "Closes #$issue when merged."

    gh pr create --title "$title" --body "$body" $rest; or return $status
    gh pr merge --auto --squash
end
