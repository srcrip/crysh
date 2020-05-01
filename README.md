<h1 align="center">crysh shell</h1>

<p align="center">
<a href="https://crystal-lang.org/"><img src="https://img.shields.io/badge/crystal-v0.34-success"/></a>
<a href="https://github.com/Sevensidedmarble/crysh/actions?query=workflow%3A%22Crystal+CI%22"><img src="https://github.com/Sevensidedmarble/crysh/workflows/Crystal%20CI/badge.svg"/></a>
</p>

> A Linux shell written in Crystal.

## Installation

Crysh needs to be built from source for now. To do that, you must install [Crystal](https://crystal-lang.org/).

1. Clone this repo: `git clone https://github.com/Sevensidedmarble/crysh.git && cd crysh`

2. Install dependencies: run: `shards install` (`shards` might be a seperate package in your package manager. Make sure you have it. You could try `crystal deps install` as well.)

3. Build: `crystal build src/crysh.cr --release`.

4. You can run crysh right from this directory with `./crysh`

5. You can now symlink to your bin folder (make sure /usr/local/bin is on your path, or use /usr/bin):

* In bash/zsh: `sudo ln -sf $(pwd)/crysh /usr/local/bin/crysh`

* In fish: `sudo ln -sf (pwd)/crysh /usr/local/bin/crysh`


## Usage

Follow the instructions above. Crysh can be used like any other unix shell. It does not aim to be 100% POSIX complete, but it should be as POSIX complete as fish when 1.0 is released.

## Development

I've collected some very helpful resources about programming shells in the wiki, [available here.](https://github.com/Sevensidedmarble/crysh/wiki/Important-Links-for-Making-Shells)

## Contributing

1. Fork it ( https://github.com/Sevensidedmarble/crysh/fork )
2. Open a PR
3. Profit
