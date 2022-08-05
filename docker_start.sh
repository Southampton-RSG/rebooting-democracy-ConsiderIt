service mysql restart
bin/webpack &
bin/delayed_job restart
rails s -p 3001 -b 0.0.0.0