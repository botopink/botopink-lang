# stamp_record_spread

Decision 821: a component built with a record spread (`Card(..base, n: 1)`) is a call answering a
component like any other, so each written one is numbered and stamped: `a` and `b` are two cells, each
made once, and nothing is made again on the second render.

[src/main.bp](src/main.bp)
