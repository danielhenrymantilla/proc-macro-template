#!/bin/sh

set -euxo pipefail

cargo update -vw
[[ -z "$(git status --porcelain)" ]]

{% if proc_macros %}
(cd src/proc_macros
    cargo +stable publish
)
{% endif %}
cargo +stable publish
