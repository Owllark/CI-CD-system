#!/bin/bash
cypress_output=$(npx cypress run --browser chromium)

echo "$cypress_output"

cp -r /testing/reports/* /reports

if echo "$cypress_output" | grep -q "All specs passed"; then
  echo "All tests passed."
else
  echo "Some tests failed or an error has occured"
fi

echo "Saving test output..."
echo "$cypress_output" > /reports/test_output
echo "Saved to /reports/test_output"