#!/bin/bash

echo "=== Docker Image Optimization Results ==="
echo "========================================"
echo

echo "Image Sizes:"
echo "------------"
docker images | grep sample-app | sort -k7 -h

echo
echo "Detailed Size Analysis:"
echo "----------------------"

for tag in unoptimized multistage alpine optimized production final minimal; do
    if docker images sample-app:$tag &>/dev/null; then
        size=$(docker images sample-app:$tag --format "{{.Size}}")
        echo "sample-app:$tag - $size"
    fi
done

echo
echo "Layer Analysis (Top 3 optimized images):"
echo "----------------------------------------"

for tag in production final minimal; do
    if docker images sample-app:$tag &>/dev/null; then
        echo "Layers in sample-app:$tag:"
        docker history sample-app:$tag --format "table {{.Size}}\t{{.CreatedBy}}" | head -10
        echo
    fi
done
