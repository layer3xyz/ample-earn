# See https://just.systems/man/en/settings.html
set shell := ["bash", "-euo", "pipefail", "-c"]
set unstable

# ---------------------------------------------------------------------------- #
#                                 DEPENDENCIES                                 #
# ---------------------------------------------------------------------------- #

forge := require("forge")

# ---------------------------------------------------------------------------- #
#                                   CONSTANTS                                  #
# ---------------------------------------------------------------------------- #

GLOBS_CLEAN := "artifacts artifacts-* broadcast cache cache_hardhat-zk coverage docs out out-* lcov.info"
GLOBS_SOLIDITY := "{script,src,test}/**/*.sol"

ECHIDNA_CONTRACT := "Tester"
ECHIDNA_CONFIG := "./test/enigma-dark-invariants/_config/echidna_config.yaml"
ECHIDNA_CORPUS := "./test/enigma-dark-invariants/_corpus/echidna/default/_data/corpus"
ECHIDNA_REPLAY := "./test/enigma-dark-invariants/replays"

# ---------------------------------------------------------------------------- #
#                                     AMPLE                                    #
# ---------------------------------------------------------------------------- #

# Run all Ample tests
[group("ample")]
test-ample:
    forge test --match-path "test/ample/**/*.sol" -vv
alias ta := test-ample

# Run all Ample fork tests
[group("ample")]
test-ample-fork:
    forge test --match-path "test/ample/fork/**/*.sol" -vv
alias taf := test-ample-fork

# ---------------------------------------------------------------------------- #
#                                    FOUNDRY                                   #
# ---------------------------------------------------------------------------- #

# Build contracts
[group("foundry")]
build:
    forge build
alias b := build

# Generate code coverage report, excluding tests
[group("foundry")]
coverage:
    forge coverage --exclude-tests --no-match-coverage "(script|scripts|external|node_modules)"
alias cov := coverage

# Generate code coverage report, including tests
[group("foundry")]
coverage-full:
    forge coverage
alias covf := coverage-full

# Dump code coverage to an html file
[group("foundry")]
[script]
coverage-report:
    if ! command -v genhtml >/dev/null 2>&1; then
        echo "✗ genhtml CLI not found"
        echo "Install it with Homebrew: https://formulae.brew.sh/formula/lcov"
        exit 1
    fi
    forge coverage --report lcov
    genhtml --branch-coverage --ignore-errors inconsistent --output-dir coverage lcov.info
alias covr := coverage-report

# Generate gas snapshot
[group("foundry")]
snapshot:
    forge snapshot
alias snap := snapshot

# Check code with Forge formatter
[group("foundry")]
fmt-check:
    forge fmt --check
alias fc := fmt-check

# Fix code with Forge formatter
[group("foundry")]
fmt-write:
    forge fmt
alias fw := fmt-write

# Performs a gas report
[group("foundry")]
gas-report:
    forge test --gas-report
alias gr := gas-report

# Run tests with optional arguments
[group("foundry")]
test *args:
    forge test {{ args }}
alias t := test

# Run specific test by name pattern
[group("foundry")]
test-match pattern:
    forge test --match-test {{ pattern }}
alias tm := test-match

# Run tests for a specific contract
[group("foundry")]
test-contract contract:
    forge test --match-contract {{ contract }}
alias tc := test-contract

# Run tests in a specific file
[group("foundry")]
test-path path:
    forge test --match-path {{ path }}
alias tp := test-path

# ---------------------------------------------------------------------------- #
#                               INVARIANT TESTING                              #
# ---------------------------------------------------------------------------- #

# Run Echidna invariant tests
[group("invariants")]
echidna:
    echidna test/enigma-dark-invariants/Tester.t.sol \
        --contract {{ ECHIDNA_CONTRACT }} \
        --config {{ ECHIDNA_CONFIG }} \
        --corpus-dir {{ ECHIDNA_CORPUS }}
alias e := echidna

# Run Echidna in assertion mode
[group("invariants")]
echidna-assert:
    echidna test/enigma-dark-invariants/Tester.t.sol \
        --contract {{ ECHIDNA_CONTRACT }} \
        --test-mode assertion \
        --config {{ ECHIDNA_CONFIG }} \
        --corpus-dir {{ ECHIDNA_CORPUS }}
alias ea := echidna-assert

# Run Echidna in exploration mode
[group("invariants")]
echidna-explore:
    echidna test/enigma-dark-invariants/Tester.t.sol \
        --contract {{ ECHIDNA_CONTRACT }} \
        --test-mode exploration \
        --config {{ ECHIDNA_CONFIG }} \
        --corpus-dir {{ ECHIDNA_CORPUS }}
alias ee := echidna-explore

# Run Medusa fuzzer
[group("invariants")]
medusa:
    medusa fuzz --config ./medusa.json
alias m := medusa

# Convert Echidna corpus to replay tests
[group("invariants")]
runes:
    runes convert {{ ECHIDNA_CORPUS }}/reproducers --output {{ ECHIDNA_REPLAY }}
alias r := runes

# ---------------------------------------------------------------------------- #
#                                   SCRIPTS                                    #
# ---------------------------------------------------------------------------- #

# Generate merkle root for prize pool testing
[group("scripts")]
generate-merkle:
    forge script script/ample/GenerateMerkleRoot.s.sol -vvv
alias gm := generate-merkle

# ---------------------------------------------------------------------------- #
#                                    UTILITY                                   #
# ---------------------------------------------------------------------------- #

# Clean build artifacts
[group("utility")]
clean globs=GLOBS_CLEAN:
    rm -rf {{ globs }}
alias c := clean