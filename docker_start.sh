rake db:schema:load && rake db:migrate
bin/webpack &  # This is inefficient unless you're doing PyCharm dev in docker container stuff
bin/delayed_job restart
rails s -p 80 -b 0.0.0.0