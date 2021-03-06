#lang racket/base
(require unstable/cat
         rackunit
         racket/math)

(define-syntax-rule (tc expr expected)
  (test-equal? (format "~s" 'expr) expr expected))

(define-syntax-rule (tcrx expr len rx)
  (test-case (format "~s" 'expr)
    (let ([v expr])
      (when len (check-equal? (string-length v) len))
      (check-regexp-match rx v))))

;; cat

(tc (cat "north")
    "north")
(tc (cat 'south)
    "south")
(tc (cat #"east")
    "east")
(tc (cat #\w "e" 'st)
    "west")
(tc (cat (list "red" 'green #"blue"))
    "(red green blue)")
(tc (cat 17)
    "17")
(tc (cat #e1e20)
    (number->string #e1e20))
(tc (cat pi)
    (number->string pi))
(tc (cat (expt 6.1 87))
    (number->string (expt 6.1 87)))

(tc (cat "a" "b" "c" #:width 5)
    "abc  ")

(tc (cat "abcde" #:limit 5)
    "abcde")
(tc (cat "abcde" #:limit 4)
    "a...")
(tc (cat "abcde" #:limit 4 #:limit-marker "*")
    "abc*")
(tc (cat "abcde" #:limit 4 #:limit-marker "")
    "abcd")
(tc (cat "The quick brown fox" #:limit 15 #:limit-marker "")
    "The quick brown")
(tc (cat "The quick brown fox" #:limit 15 #:limit-marker "...")
    "The quick br...")

(tcrx (cat "apple" #:pad-to 20 #:align 'left)
      20 #rx"^apple( )*$")
(tcrx (cat "pear" #:pad-to 20 #:align 'left #:right-padding " x")
      20 #rx"^pear(x)?( x)*$")
(tcrx (cat "plum" #:pad-to 20 #:align 'right #:left-padding "x ")
      20 #rx"^(x )*(x)?plum$")
(tcrx (cat "orange" #:pad-to 20 #:align 'center
           #:left-padding "- " #:right-padding " -")
      20 #rx"^(- )*(-)?orange(-)?( -)*$")

(tc (cat "short" #:width 6)
    "short ")
(tc (cat "loquacious" #:width 6)
    "loq...")

;; catp

(tc (catp "north")
    "\"north\"")
(tc (catp 'south)
    "'south")
(tc (catp #"east")
    "#\"east\"")
(tc (catp #\w)
    "#\\w")
(tc (catp (list "red" 'green #"blue"))
    "'(\"red\" green #\"blue\")")

;; catw

(tc (catw "north")
    "\"north\"")
(tc (catw 'south)
    "south")
(tc (catw #"east")
    "#\"east\"")
(tc (catw #\w)
    "#\\w")
(tc (catw (list "red" 'green #"blue"))
    "(\"red\" green #\"blue\")")

;; catn

(tc (catn pi)
    "3.142")
(tc (catn pi #:precision 4)
    "3.1416")
(tc (catn pi #:precision 0)
    "3")
(tc (catn 1.5 #:precision 4)
    "1.5")
(tc (catn 1.5 #:precision '(= 4))
    "1.5000")
(tc (catn 50 #:precision 2)
    "50")
(tc (catn 50 #:precision '(= 2))
    "50.00")
(tc (catn 50 #:precision '(= 0))
    "50.")

(tc (catn 17)
    "17")
(tc (catn 17 #:pad-digits-to 4)
    "  17")
(tc (catn -42 #:pad-digits-to 4)
    "-  42")
(tc (catn 1.5 #:pad-digits-to 4)
    " 1.5")
(tc (catn 1.5 #:precision 4 #:pad-digits-to 10)
    "       1.5")
(tc (catn 1.5 #:precision '(= 4) #:pad-digits-to 10)
    "    1.5000")

(tc (catn -42 #:pad-digits-to 4)
    "-  42")

(tc (catn 17 #:pad-digits-to 4 #:digits-padding "0")
    "0017")
(tc (catn -42 #:pad-digits-to 4 #:digits-padding "0")
    "-0042")

(tc (for/list ([x '(17 0 -42)]) (catn x))
    '("17" "0" "-42"))
(tc (for/list ([x '(17 0 -42)]) (catn x #:sign '+))
    '("+17" "0" "-42"))
(tc (for/list ([x '(17 0 -42)]) (catn x #:sign '++))
    '("+17" "+0" "-42"))
(tc (for/list ([x '(17 0 -42)]) (catn x #:sign 'parens))
    '("17" "0" "(42)"))
(tc (let ([sign-table '(("" " up") "an even " ("" " down"))])
      (for/list ([x '(17 0 -42)]) (catn x #:sign sign-table)))
    '("17 up" "an even 0" "42 down"))

(tc (catn 100 #:base 7)
    "202")
(tc (catn 4.5 #:base 2)
    "100.1")
(tc (catn 3735928559 #:base 16)
    "deadbeef")
(tc (catn 3735928559 #:base '(up 16))
    "DEADBEEF")

(tc (catn 999 #:pos/exp-range '(0 3))
    "999")
(tc (catn 1000 #:pos/exp-range '(0 3))
    "1e+03")
(tc (catn 0.9876 #:pos/exp-range '(0 3))
    "9.876e-01")

(tc (catn 100 #:base 2 #:pos/exp-range '(0 3))
    "1.1001×2^+06")

(tc (catn 1234 #:pos/exp-range '(0 3) #:exp-format-exponent "E")
    "1.234E+03")

(tc (catn 12345 #:pos/exp-range '(0 3) #:exp-precision 3)
    "1.235e+04")
(tc (catn 12345 #:pos/exp-range '(0 3) #:exp-precision 2)
    "1.23e+04")
(tc (catn 10000 #:pos/exp-range '(0 3) #:exp-precision 2)
    "1e+04")
(tc (catn 10000 #:pos/exp-range '(0 3) #:exp-precision '(= 2))
    "1.00e+04")

(tc (catn 12345 #:pos/exp-range '(0 3) 
          #:pad-digits-to 12 #:digits-padding " ")
    "  1.2345e+04")

;; catnp

(tc (catnp pi)
    "3.142")
(tc (catnp pi #:precision 4)
    "3.1416")
(tc (catnp pi #:precision 0)
    "3")
(tc (catnp 1.5 #:precision 4)
    "1.5")
(tc (catnp 1.5 #:precision '(= 4))
    "1.5000")
(tc (catnp 50 #:precision 2)
    "50")
(tc (catnp 50 #:precision '(= 2))
    "50.00")
(tc (catnp 50 #:precision '(= 0))
    "50.")

(tc (catnp 17)
    "17")
(tc (catnp 17 #:pad-digits-to 4)
    "  17")
(tc (catnp -42 #:pad-digits-to 4)
    "-  42")
(tc (catnp 1.5 #:pad-digits-to 4)
    " 1.5")
(tc (catnp 1.5 #:precision 4 #:pad-digits-to 10)
    "       1.5")
(tc (catnp 1.5 #:precision '(= 4) #:pad-digits-to 10)
    "    1.5000")

(tc (catnp -42 #:pad-digits-to 4)
    "-  42")

(tc (catnp 17 #:pad-digits-to 4 #:digits-padding "0")
    "0017")
(tc (catnp -42 #:pad-digits-to 4 #:digits-padding "0")
    "-0042")

(tc (for/list ([x '(17 0 -42)]) (catnp x))
    '("17" "0" "-42"))
(tc (for/list ([x '(17 0 -42)]) (catnp x #:sign '+))
    '("+17" "0" "-42"))
(tc (for/list ([x '(17 0 -42)]) (catnp x #:sign '++))
    '("+17" "+0" "-42"))
(tc (for/list ([x '(17 0 -42)]) (catnp x #:sign 'parens))
    '("17" "0" "(42)"))
(tc (let ([sign-table '(("" " up") "an even " ("" " down"))])
      (for/list ([x '(17 0 -42)]) (catnp x #:sign sign-table)))
    '("17 up" "an even 0" "42 down"))

(tc (catnp 100 #:base 7)
    "202")
(tc (catnp 4.5 #:base 2)
    "100.1")
(tc (catnp 3735928559 #:base 16)
    "deadbeef")
(tc (catnp 3735928559 #:base '(up 16))
    "DEADBEEF")

;; catne

(tc (catne 1000)
    "1e+03")
(tc (catne 0.9876)
    "9.876e-01")

(tc (catne 100 #:base 2)
    "1.1001×2^+06")

(tc (catne 1234 #:format-exponent "E")
    "1.234E+03")

(tc (catne 12345 #:precision 3)
    "1.235e+04")
(tc (catne 12345 #:precision 2)
    "1.23e+04")
(tc (catne 10000 #:precision 2)
    "1e+04")
(tc (catne 10000 #:precision '(= 2))
    "1.00e+04")

(tc (catne 12345 #:pad-digits-to 12 #:digits-padding " ")
    "  1.2345e+04")
