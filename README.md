# Mini Redis

Minimal Redis implementation in the Elixir programming language. Partially
supports the RESP protocol and inline commands. Implements GET, SET, DEL, PING,
and a custom EVAL (completely unsafe command that allows to execute arbitrary
Elixir code on a node).

This app was created to demonstrate how to build and deploy a distributed Elixir
application backed by the Distributed Erlang System,
[DeltaCrdt](https://github.com/derekkraan/delta_crdt_ex),
[libcluster](https://github.com/bitwalker/libcluster) and Kubernetes.
