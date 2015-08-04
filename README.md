[![Build Status](https://travis-ci.org/mauricioklein/docker-compose-api.svg?branch=develop)](https://travis-ci.org/mauricioklein/docker-compose-api)

# Docker Compose Api

DockerCompose provides an easy way to parse docker compose files and lift the whole environment easily.

## Installation

```ruby
gem 'docker-compose-api'
```

## Usage

```ruby
# Load a docker compose file content, download all necessary images from Docker Hub
# and instantiate all necessary containers
DockerCompose.load('path to your docker compose file')

# Acessing all containers created
# (will return a hash like {'container label' => container object}
DockerCompose.containers

# Starting all containers
DockerCompose.startContainers

# ...or specific containers by their labels
DockerCompose.startContainers(['label 1','label 2','label 3',...])

# Stoping all containers
DockerCompose.stopContainers

# ...or specific containers by their labels
DockerCompose.stopContainers(['label 1','label 2','label 3',...])

# docker-compose-api is built upon swipely/docker-client (https://github.com/swipely/docker-api).
# You can access Docker client anytime
DockerCompose.getDockerClient
```

## Contributing

1. Fork it ( https://github.com/mauricioklein/docker-compose-api/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
