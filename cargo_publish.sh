#!/bin/sh

set -euxo pipefail
{% if proc_macros %}
(cd src/proc_macros
    cargo +stable publish
)
{% endif %}
for i in $(seq 10)
do
    cargo +stable publish && break
    sleep 5
done
cargo +stable publish
