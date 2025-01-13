#Laravel
alias art="php artisan"
alias ci="composer install"
alias cu="composer update"
alias cda="composer dumpautoload"
alias migrate-main="php artisan migrate --path=database/migrations/main"
alias migrate-test="DB_DATABASE=test migrate-main"
alias route="php artisan route:list | grep -i"
alias tinker="php artisan tinker"

#PHPUnit
alias pucc="phpunit --coverage-html ./public/coverage"
