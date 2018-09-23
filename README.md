# crysh

A Unix shell written in Crystal.

`crysh` is very alpha right now. I first implemented a basic shell with process forking and everything, before I realized a parser was necessary for the nitty gritty. The parser is currently being worked on but you're free to play around with what's here already.

## Installation

Crysh currently needs to be built from source. To do that, you must install [Crystal](https://crystal-lang.org/).

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
