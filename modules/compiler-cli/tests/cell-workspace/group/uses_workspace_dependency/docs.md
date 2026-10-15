# uses_workspace_dependency

A cell two levels below its workspace's root (`group/*`) inherits the workspace's dependency, in place and in
`cell check`'s copy, which keeps the cell's path under the workspace root (decision 548, 144 B-113). {src/main.bp}
