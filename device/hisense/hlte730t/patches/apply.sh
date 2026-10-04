#!/bin/bash
# SPDX-License-Identifier: Apache-2.0
# Apply the hlte730t patches to a LineageOS 18.1 tree (run from its top).
# Already applied patches are skipped.
set -e
top="${1:-$PWD}"
here="$(cd "$(dirname "$0")" && pwd)"
for dir in "${here}"/*/; do
    project="$(basename "${dir}" | tr _ /)"
    for p in "${dir}"*.patch; do
        if git -C "${top}/${project}" apply --reverse --check "${p}" 2>/dev/null; then
            echo "already applied: ${project} $(basename "${p}")"
        else
            git -C "${top}/${project}" apply "${p}"
            echo "applied: ${project} $(basename "${p}")"
        fi
    done
done
