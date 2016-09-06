Lines that do not start with two spaces are comments.

Cram supports

- glob patterns

  $ echo "Hello World"
  Hell? * (glob)

- “unprintable” characters, and

  $ echo 'Fjørt'
  Fj\xc3\xb8rt (esc)

- regular expressions.

  $ python -c 'print(sorted([3, 1, 7, 3]))'
  \[(\d,\ ){3}7\] (re)

Longer commands start with two spaces followed by a `$` sign, and continue
with two spaces and a `>` sign.

  $ if [ "$TM_FILENAME" ]; then
  >   basename "$TM_FILENAME"
  > fi
  example.t
