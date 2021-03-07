.PHONY: run_confuzz build clean pin_confuzz print_env

run_confuzz: build
	export AFL_BENCH_UNTIL_CRASH=1; \
	export AFL_SKIP_CPUFREQ=1; \
	timeout 1h afl-fuzz -i ip/ -o op/ ./test.out @@ || true

build: print_env pin_confuzz
	@eval $$(cat ./config); \
	ocamlfind opt -thread -afl-instrument -linkpkg -package lwt.unix test_lwt_pick.ml -o test.out

clean:
	rm -rf op/ *.cm* *.o *.out

pin_confuzz:
	opam pin add lwt -y -k path ../

print_env:
	echo $$(opam env) > ./config

