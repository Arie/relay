# FakkelBrigade relay interface

A web-interface to start STV relays

## Requirements

* Ruby, preferbly 1.9, but other versions might work. You should use [ruby-build](https://github.com/sstephenson/ruby-build/) to install Ruby.
* GNU Screen
* A Source game dedicated server installation, only tested with TF2 on linux for now. 

## Installation
1. Make sure you've installed the requirements.
2. Review the yaml files in the `config` directory.
3. Install the required gems using bundler: `gem install bundler && bundle`
4. Start the webserver: `thin -C config/thin.yml start`
