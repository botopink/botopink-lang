clock_time_get (raised: clock wasi_snapshot_preview1.clock_time_get)
{"kind":"error","message":"a build has no clock","frames":[],"loc":"","printed":"hi\n"}

clock_res_get (raised: clock wasi_snapshot_preview1.clock_res_get)
{"kind":"error","message":"a build has no clock","frames":[],"loc":"","printed":"hi\n"}

poll_oneoff (raised: clock wasi_snapshot_preview1.poll_oneoff)
{"kind":"error","message":"a build has no clock","frames":[],"loc":"","printed":"hi\n"}

bp_host.delay (raised: clock bp_host.delay)
{"kind":"error","message":"a build has no clock","frames":[],"loc":"","printed":"hi\n"}

random_get (raised: entropy wasi_snapshot_preview1.random_get)
{"kind":"error","message":"an unseeded draw: a build has no entropy, call `random.seed` first","frames":[],"loc":"","printed":"hi\n"}

env.bp_random_f64 (raised: entropy env.bp_random_f64)
{"kind":"error","message":"an unseeded draw: a build has no entropy, call `random.seed` first","frames":[],"loc":"","printed":"hi\n"}

bp_fs.open (raised: files bp_fs.open)
{"kind":"error","message":"a build has no file system","frames":[],"loc":"","printed":"hi\n"}

path_open (raised: files wasi_snapshot_preview1.path_open)
{"kind":"error","message":"a build has no file system","frames":[],"loc":"","printed":"hi\n"}

fd_read (raised: files wasi_snapshot_preview1.fd_read)
{"kind":"error","message":"a build has no file system","frames":[],"loc":"","printed":"hi\n"}

fd_write on fd 3 (raised: print wasi_snapshot_preview1.fd_write)
{"kind":"error","message":"a build has no file system","frames":[],"loc":"","printed":"hi\n"}

environ_get (raised: environment wasi_snapshot_preview1.environ_get)
{"kind":"error","message":"a build has no process","frames":[],"loc":"","printed":"hi\n"}

args_sizes_get (raised: environment wasi_snapshot_preview1.args_sizes_get)
{"kind":"error","message":"a build has no process","frames":[],"loc":"","printed":"hi\n"}

proc_exit (raised: exit wasi_snapshot_preview1.proc_exit)
{"kind":"error","message":"a build does not exit the process","frames":[],"loc":"","printed":"hi\n"}

sched_yield (reply)
{"ok":0}

frames (raised: clock wasi_snapshot_preview1.clock_time_get)
{"kind":"error","message":"a build has no clock","frames":[{"module":"std@io@clock","function":"std@io@clock.now"},{"module":"std@io@clock","function":"app@main.body"}],"loc":""}

deadline (raised)
{"kind":"error","message":"wasm trap: time limit reached","frames":[],"loc":"","printed":"hi\n"}
