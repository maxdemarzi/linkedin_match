cb_match
========

POC for Career Builder Matching.


Pre-Requisites
--------------

You will need to get a Linked In Consumer Key and Secret on https://www.linkedin.com/secure/developer
You will need Neo4j in order for your database.
You will need Redis in order to use Sidekiq for background jobs.

Installation
----------------

    git clone git@github.com:maxdemarzi/cb_match.git
    bundle install
    sudo apt-get install redis-server or brew install redis
    rake neo4j:install['enterprise','1.8.M06']
    rake neo4j:start
    export SESSION_SECRET="Vfnnp Nfvzbi jebgr gur Sbhaqngvba Frevrf juvpu vf ner zl snibevgr obbxf."
    export CONSUMER_KEY="udmw68f7t3om"
    export CONSUMER_SECRET="41OHptpc1oFOnI9n"
    export REDISTOGO_URL="redis://127.0.0.1:6379/"
    foreman start
    rake cbm:seed

On Heroku
---------

    git clone git@github.com:maxdemarzi/cb_match.git
    heroku apps:create --stack cedar
    heroku config:add SESSION_SECRET="Vfnnp Nfvzbi jebgr gur Sbhaqngvba Frevrf juvpu vf ner zl snibevgr obbxf."
    heroku config:add CONSUMER_KEY="udmw68f7t3om"
    heroku config:add CONSUMER_SECRET="41OHptpc1oFOnI9n"
    heroku addons:add neo4j
    heroku addons:add redistogo
    git push heroku master
    heroku ps:scale workers=1
    heroku run rake cbm:seed



See it running live at http://cbmatch.heroku.com