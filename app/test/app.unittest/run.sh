#!/bin/bash
test_output=$(dotnet test --logger trx;LogFileName=test-results.trx)

echo "$test_output"

cp -r /testing/test/app.unittest/TestResults/* /reports

if echo "$test_output" | grep -q "Passed!"; then
  echo "All tests passed."
else
  echo "Some tests failed or an error has occured"
fi

echo "Saving test output..."
echo "$test_output" > /reports/test_output
echo "Saved to /reports/test_output"
