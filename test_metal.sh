#!/bin/bash
# Test script to run Mini vMac with Metal rendering
# This will show renderer information in the console

echo "Running Mini vMac with Metal rendering..."
echo "Look for '=== Metal Rendering Enabled ===' in the output"
echo ""

./minivmac.app/Contents/MacOS/minivmac 2>&1 | grep -E "(Metal|OPENGL|RENDERER|Device|Pipeline)" || echo "App started (check console for renderer info)"

