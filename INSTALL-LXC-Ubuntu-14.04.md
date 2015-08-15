# CLAHub installation instructions - LXC container

```
lxc-create -n myclahub.example.com -t download -- -d ubuntu -r trusty -a amd64
```

Inside container:
- install ruby 2.1.4 (see provision.sh or use rbenv)
--> ruby 2.1.4: if you did not install system ruby (1.9.*), no problems should be expected
--> configure omission of gem doc installation - cuts install time significantly

- install postgresql
--> 14.04 has postgres version 9.3
--> INFO: new databases are by default en_US.UTF-8

- configure postgresql authentication
--> change from peer to md5
--> diff /etc/postgresql/9.3/main/pg_hba.conf* -u

```diff
--- /etc/postgresql/9.3/main/pg_hba.conf.ORIG	2015-08-14 15:37:58.076708822 +0000
+++ /etc/postgresql/9.3/main/pg_hba.conf	2015-08-14 15:44:43.447819631 +0000
@@ -87,7 +87,7 @@
 # TYPE  DATABASE        USER            ADDRESS                 METHOD
 
 # "local" is for Unix domain socket connections only
-local   all             all                                     peer
+local   all             all                                     md5
 # IPv4 local connections:
 host    all             all             127.0.0.1/32            md5
 # IPv6 local connections:
```


- setup postgresql role and database
--> create role clahub_production login password 'FIXME-CHANGE';
--> create database clahub_production owner clahub_production;


Clone git repo:
```
git clone ...
cd clahub
```


Install gems:
```
bundle
```


Configure .env:
```
# Public port to bind to
PORT=3000

# Present self as this uri
# (useful if running behing Apache proxy in non-publicly-available LXC container)
HOST=http://myclahub.example.com/

# Secret token
#SECRET_TOKEN=VeryRandomString-commented-out-so-you-will-change-it

# Github credentials
GITHUB_KEY=abc123
GITHUB_SECRET=234897239872394832478
GITHUB_LIMITED_KEY=abc123
GITHUB_LIMITED_SECRET=234897239872394832478

# Disable newrelic
NEWRELIC_ENABLE=false
```


Configure application:
```
cp config/database.yml.sample config/database.yml
edit config/database.yml
# Remove test and development sections
# Enter your db credentials
```


Run database migrations
```
#rake RAILS_ENV=production db:create   # Step must be omitted, as DB is already created above
rake RAILS_ENV=production db:migrate
```


Test if everything works as expected:
```
# This does not work with production-only database.
# See original CLAHub's README.md on how to set this up.
rake RAILS_ENV=production
```


Install 'foreman' gem:
```
gem install foreman
```


Precompile assets:
```
rake RAILS_ENV=production assets:precompile
```


WORKAROUND: If you are not using Apache for static file serving, modify
config/environments/production.rb:
```
Clahub::Application.configure do
  # ...
  config.serve_static_assets = true
  #...
```


Start the application manually:
```
RAILS_ENV=production foreman start
```


If you wish to run this app as non-root user, you need to:
- create that user
- make sure it is secured (remove pwd auth)
- chmod 777 log/ tmp/ -R
- su - clahub
- RAILS_ENV=production foreman start



## Usage:

You have to register application on github, I think.

Do not try to add webhooks manually on github.
Instead go to myclahub.example.com, sign in with github and create new CLA.
