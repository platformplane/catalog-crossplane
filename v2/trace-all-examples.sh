#!/bin/bash

# Script to run crossplane beta trace for all examples in v2/examples folder

EXAMPLES_DIR="v2/examples"

echo "Running crossplane beta trace for all examples..."
echo "=================================================="
echo ""

# Loop through all YAML files in the examples directory
for file in "$EXAMPLES_DIR"/*.yaml; do
    if [ -f "$file" ]; then
        # Extract kind and name from the YAML file
        kind=$(grep "^kind:" "$file" | awk '{print $2}')
        name=$(grep -A 5 "^metadata:" "$file" | grep "  name:" | awk '{print $2}')

        if [ -n "$kind" ] && [ -n "$name" ]; then
            echo "📋 File: $(basename "$file")"
            echo "   Kind: $kind"
            echo "   Name: $name"
            echo "   Running: crossplane beta trace $kind $name"
            echo "   ----------------------------------------"

            crossplane beta trace "$kind" "$name"

            echo ""
            echo ""
        else
            echo "⚠️  Could not extract kind/name from $(basename "$file")"
            echo ""
        fi
    fi
done

echo "=================================================="
echo "Trace complete!"
