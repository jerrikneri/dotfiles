source-all() {
    for dir in $ALIASES $FUNCTIONS $MODULES; do
        for file in "$dir"/.*.sh; do
        [ -f "$file" ] && source $file
        done
    done
}