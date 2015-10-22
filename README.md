[![Build Status](https://travis-ci.org/mauricioklein/docker-compose-api.svg?branch=develop)](https://travis-ci.org/mauricioklein/docker-compose-api)
[![Code Climate](https://codeclimate.com/github/mauricioklein/docker-compose-api/badges/gpa.svg)](https://codeclimate.com/github/mauricioklein/docker-compose-api)
[![Test Coverage](https://codeclimate.com/github/mauricioklein/docker-compose-api/badges/coverage.svg)](https://codeclimate.com/github/mauricioklein/docker-compose-api/coverage)

# Docker Compose Api

Docker Compose API provides an easy way to parse docker compose files and lift the whole environment.

## Instalation

```sh
$ gem install docker-compose-api
```

## Usage

```ruby
require 'docker-compose'

# Gem version
DockerCompose.version

# Loading a compose file
compose = DockerCompose.load('[path to docker compose file]')

# Accessing all containers
all_containers = compose.containers

# Acessing an specific container
a_single_container = compose.containers['[container name]']

# Starting all containers and their dependencies
compose.start

# ... or starting a list of specific containers
compose.start(['container1', 'container2', ...])

# Stopping all containers
compose.stop

# ... or stopping a list of specific containers
compose.stop(['container1', 'container2', ...])

# Checking if a container is running or not
a_container = compose.container('a_container')
a_container.running?

# ... and for checking container complete informations
a_container.stats

# Accessing Docker client directly
DockerCompose.docker_client
```

## Contributing

1. Fork it ( https://github.com/mauricioklein/docker-compose-api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
