MAKEFLAGS=--no-builtin-rules --no-builtin-variables --always-make
ROOT := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))

init-flow-emulator:
	cd flow-emulator && flow init

run-flow-emulator:
	cd flow-emulator && flow emulator

generate-flow-keys:
	cd flow-emulator && flow keys generate

generate-flow-account:
	cd flow-emulator && flow accounts create \
    --key b47665c14639302863372aa9b8d33d0c599358b76be81bb72bc2283427a3f1c0287b275c215a83f936dd4a02afee200047104f3b60d0cc611d199c4514909e9b

reset-flow-emulator:
	cd flow-emulator && flow init --reset