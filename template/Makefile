include .env

RUBY ?= ruby
FILES = Makefile Gemfile Gemfile.lock *.rb views public 

install:
	bundle install

develop:
	$(RUBY) cms.rb -e development -p $(PORT)

start: install
	$(RUBY) cms.rb -e production -p $(PORT)

deploy: test
	rsync -rvsp --delete $(FILES) $(APP_HOST):$(APP_DEST)
	ssh $(APP_HOST):$(APP_DEST) 'systemctl restart $(SERVICE)'

.PHONY: install develop start deploy
