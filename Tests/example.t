[Cram][] is a a functional testing framework for command line applications.

[Cram]: https://bitheap.org/cram

To test a command just start a line with two spaces and a `$` sign. After that
write down the command and start the next line with two spaces and the output
you expect.

  $ echo 'Hello, Cram.'
  Hello, Cram.

Cram also supports

- glob patterns

  $ echo 'Hello 😘.'
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

To test the current file just press `⌘` + `R` inside TextMate.
