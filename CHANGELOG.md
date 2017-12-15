# Changelog
All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)

## [1.0.7] - 2017-12-15

### Added
- "restart" command to restart a container
- "stop" alias command to clean

## [1.0.6] - 2017-11-02

### Added
- "build" command to build or rebuild the docker image

## [1.0.4] - 2017-07-26

### Added
- A quick "database.yml" info at the end of the init process

### Changed
- Updated docker-sync dependency to ~> 0.4.0 (cf [changelog](https://github.com/EugenMayer/docker-sync/wiki/5.-Changelog))

### Fixed
- [Dockrails start fails to start because of docker-sync API change](https://github.com/gmontard/dockrails/issues/2)
