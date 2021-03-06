# ConFuzz
ConFuzz is a directed concurrency bug-finding tool for event-driven Lwt based OCaml programs. 
ConFuzz combines QuickCheck-style property-based testing with coverage-guided fuzzing for finding concurrency bugs in event-driven programs.
ConFuzz is based on property-based testing library [crowbar](https://github.com/stedolan/crowbar) and uses AFL to find concurrency bugs.

Refer paper titled [ConFuzz: Coverage-guided Property Fuzzing for Event-driven Programs](https://link.springer.com/chapter/10.1007%2F978-3-030-67438-0_8) published at PADL 2021 for more technical details.

## Dependencies
1. Requires an opam switch with AFL instrumentation enabled(4.08.0+afl & above).
2. `libev` package. It is often called libev-dev or libev-devel
3. ConFuzz can work with Lwt-4.x.x based programs. Lwt-5.x.x based programs might not work well

## Set Up
- Pin lwt
```
opam pin lwt .
```

## Writing test
- To test Lwt programs, write [Crowbar tests](https://github.com/stedolan/crowbar#writing-tests) that calls into Lwt concurrent code. For examples, refer to  ```examples``` directory.

## Running test
- Fuzz as usual with afl-fuzz
```
afl-fuzz -i ip/ -o op/ ./program @@
```
