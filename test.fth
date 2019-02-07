: nl 10 emit ;
: test ." This is a test of the pforth standalone binary" nl ;

: io-test s" ftest.txt" w/o open-file throw  >r
	s" This is a string literal"  r> dup >r write-file
	r> close-file ;

test
io-test
