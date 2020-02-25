#/bin/bash


source ../libimport.bash
bash_import ../libtest.bash
bash_import ../libhsm.bash
bash_import ./hsm_example.bash





testsuite_1_setup() {
	declare -g EXPECTED="$(cat <<- EOF
		topState-INIT;s-ENTRY;s2-ENTRY;s2-INIT;s21-ENTRY;s211-ENTRY;
		A:s21-A;s211-EXIT;s21-EXIT;s21-ENTRY;s21-INIT;s211-ENTRY;
		B:s21-B;s211-EXIT;s211-ENTRY;
		D:s211-D;s211-EXIT;s21-INIT;s211-ENTRY;
		E:s-E;s211-EXIT;s21-EXIT;s2-EXIT;s1-ENTRY;s11-ENTRY;
		I:s1-I;
		F:s1-F;s11-EXIT;s1-EXIT;s2-ENTRY;s21-ENTRY;s211-ENTRY;
		I:s2-I;
		I:s-I;
		F:s2-F;s211-EXIT;s21-EXIT;s2-EXIT;s1-ENTRY;s11-ENTRY;
		A:s1-A;s11-EXIT;s1-EXIT;s1-ENTRY;s1-INIT;s11-ENTRY;
		B:s1-B;s11-EXIT;s11-ENTRY;
		D:s1-D;s11-EXIT;s1-EXIT;s-INIT;s1-ENTRY;s11-ENTRY;
		D:s11-D;s11-EXIT;s1-INIT;s11-ENTRY;
		E:s-E;s11-EXIT;s1-EXIT;s1-ENTRY;s11-ENTRY;
		G:s11-G;s11-EXIT;s1-EXIT;s2-ENTRY;s21-ENTRY;s211-ENTRY;
		H:s211-H;s211-EXIT;s21-EXIT;s2-EXIT;s-INIT;s1-ENTRY;s11-ENTRY;
		H:s11-H;s11-EXIT;s1-EXIT;s-INIT;s1-ENTRY;s11-ENTRY;
		C:s1-C;s11-EXIT;s1-EXIT;s2-ENTRY;s2-INIT;s21-ENTRY;s211-ENTRY;
		G:s21-G;s211-EXIT;s21-EXIT;s2-EXIT;s1-ENTRY;s1-INIT;s11-ENTRY;
		C:s1-C;s11-EXIT;s1-EXIT;s2-ENTRY;s2-INIT;s21-ENTRY;s211-ENTRY;
		C:s2-C;s211-EXIT;s21-EXIT;s2-EXIT;s1-ENTRY;s1-INIT;s11-ENTRY;
		EOF
	)"

}

testsuite_1_teardown() {
	unset EXPECTED
}

testsuite_1_test_run() {
	local OUT="$(example_machine)"
	test_assert
	[[ -n $OUT ]] || test_assert
	[[ "$OUT" == "$EXPECTED" ]] || test_assert
	test_assert '[[ $OUT == "$EXPECTED" ]]'
}


run_tests
print_test_results
