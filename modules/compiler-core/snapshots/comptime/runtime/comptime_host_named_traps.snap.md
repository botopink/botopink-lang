clock_time_get (raised)
{"kind":"error","message":"a build has no clock: clock_time_get reads the time when the program runs","printed":"hi\n"}

clock_res_get (raised)
{"kind":"error","message":"a build has no clock: clock_res_get reads the time when the program runs","printed":"hi\n"}

poll_oneoff (raised)
{"kind":"error","message":"a build has no clock: poll_oneoff reads the time when the program runs","printed":"hi\n"}

bp_host.delay (raised)
{"kind":"error","message":"a build has no clock: bp_host.delay reads the time when the program runs","printed":"hi\n"}

random_get (raised)
{"kind":"error","message":"an unseeded draw: a build has no entropy, call `random.seed` first (decision 451)","printed":"hi\n"}

env.bp_random_f64 (raised)
{"kind":"error","message":"an unseeded draw: a build has no entropy, call `random.seed` first (decision 451)","printed":"hi\n"}

bp_fs.open (raised)
{"kind":"error","message":"a build has no file system: bp_fs.open reads a file when the program runs","printed":"hi\n"}

path_open (raised)
{"kind":"error","message":"a build has no file system: path_open reads a file when the program runs","printed":"hi\n"}

fd_read (raised)
{"kind":"error","message":"a build has no file system: fd_read reads a file when the program runs","printed":"hi\n"}

fd_write on fd 3 (raised)
{"kind":"error","message":"a build has no file system: fd_write reads a file when the program runs","printed":"hi\n"}

environ_get (raised)
{"kind":"error","message":"a build has no process: environ_get reads the environment when the program runs","printed":"hi\n"}

args_sizes_get (raised)
{"kind":"error","message":"a build has no process: args_sizes_get reads the environment when the program runs","printed":"hi\n"}

proc_exit (raised)
{"kind":"error","message":"a build does not exit the process","printed":"hi\n"}

sched_yield (reply)
{"ok":0}

deadline (raised)
{"kind":"error","message":"wasm trap: time limit reached","printed":"hi\n"}
