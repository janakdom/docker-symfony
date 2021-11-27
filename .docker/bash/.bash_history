composer install
composer update
bin/console make:migration
bin/console doctrine:migrations:migrate
bin/console doctrine:fixtures:load
