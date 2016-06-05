[![Build Status](https://travis-ci.org/mauricioklein/docker-compose-api.svg?branch=develop)](https://travis-ci.org/mauricioklein/docker-compose-api)
[![Code Climate](https://codeclimate.com/github/mauricioklein/docker-compose-api/badges/gpa.svg)](https://codeclimate.com/github/mauricioklein/docker-compose-api)
[![Test Coverage](https://codeclimate.com/github/mauricioklein/docker-compose-api/badges/coverage.svg)](https://codeclimate.com/github/mauricioklein/docker-compose-api/coverage)
[![Gem Version](https://badge.fury.io/rb/docker-compose-api.svg)](https://badge.fury.io/rb/docker-compose-api)
[![Dependency Status](https://gemnasium.com/badges/github.com/mauricioklein/docker-compose-api.svg)](https://gemnasium.com/github.com/mauricioklein/docker-compose-api)

# Docker Compose Api

Docker Compose API provides an easy way to parse docker compose files and lift the whole environment.

## Instalation

Install the gem in whole environment

```ruby
gem install docker-compose-api
```

... or using Bundler

```ruby
# Add the line below on your Gemfile...
gem 'docker-compose-api'

# ... and run bundle install
bundle install
```

## Usage

```ruby
require 'docker-compose'

# Docker compose is simply a layer running over Docker client (https://github.com/swipely/docker-api).
# So, all Docker specific configurations, such URL, authentication, SSL, etc, must be made directly on
# Docker client.
#
# Docker compose provides an easy way to access this client:
DockerCompose.docker_client

# Gem version
DockerCompose.version

# Loading a compose file
compose = DockerCompose.load('[path to docker compose file]')

# 'Load' method accepts a second argument, telling to do load or not
# containers started previously by this compose file.
#
# So, loading a compose file + containers started by this compose previously
compose = DockerCompose.load('[path to docker compose file]', true)

# Accessing containers
compose.containers                                   # access all containers
compose.containers['container_label']                # access a container by its label (DEPRECATED)
compose.get_containers_by(label: 'foo', name: 'bar') # Returns an array of all containers with label = 'foo' and name = bar

# Containers names are generated using the pattern below:
#  [Directory name]_[Container label]_[Sequential ID]
#
# So, you can access a container by its full name...
compose.get_containers_by(name: 'myawessomedir_foobar_1')

# ... or by its given name (ignores both prefix and suffix)
compose.get_containers_by_given_name('foobar')

# Starting containers (and their dependencies)
compose.start                                    # start all containers
compose.start(['container1', 'container2', ...]) # start a list of specific containers

# Stopping containers
# (ps: container dependencies will keep running)
compose.stop                                    # stop all containers
compose.stop(['container1', 'container2', ...]) # stop a list of specific containers

# Killing containers
# (ps: container dependencies will keep running)
compose.kill                                    # kill all containers
compose.kill(['container1', 'container2', ...]) # kill a list of specific containers

# Deleting containers
# (ps: container dependencies will keep running)
compose.delete                                    # delete all containers
compose.delete(['container1', 'container2', ...]) # delete a list of specific containers

# Checking if a container is running or not
a_container = compose.get_containers_by(name: 'a_container').first
a_container.running?

# Accessing container informations
a_container.stats
```

## Contributing

1. Fork it ( https://github.com/mauricioklein/docker-compose-api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
