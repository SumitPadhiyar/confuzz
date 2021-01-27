# Lwt fuzzing with AFL
Requires 4.08.0+afl & above. For examples, refer ```examples``` directory.

### Steps to run
- Checkout lwt_afl branch
```
git checkout lwt_afl
```
- Pin lwt
```
opam pin lwt .
```
- Fuzz as usual with AFL-Fuzz
```
afl-fuzz -i ip/ -o op/ ./program @@
```
