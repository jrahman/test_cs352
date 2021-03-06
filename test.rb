# test.rb
# - Jon Egeland, 2015
#
# Error-based testing for CS 352, Project 1.
#
# This script runs a set of tests, saying they passed as long as stderr is blank. Negated tests
# are also supported, such that tests that are designed to fail will show up as "passed" if they do.
#
#
# Works off of naming conventions:
#   Files in the `tests` directory that start with `test_` are test cases.
#   Files starting with `err_` will have its validity negated (i.e., passes on failure)
#   Names must:
#     - Not contain spaces
#     - Separate words with underscores (not dashes)
#
# Tests are passed to the program using their file name as the first argument, for example:
#     ./parser test_something_broken
#     => something simple: failed
#     ./parser err_test_something_broken
#     => something simple: passed



#####
### CONFIGURATION ###
#####

# The name of the program to test with
TESTER = './parser'

# The location of the tests. Used as a glob pattern.
TEST_DIR = './test/tests/*'

# The name of the file to log test results in.
# The file will be rewritten every time this tester is run.
ERR_FILE = 'test_failures.log'





#####
### SOURCE
#####

# Provides a way to read stdout and stderr.
require 'open3'

# Colorization
class String
  def colorize!(color_code); self.replace "\e[#{color_code}m#{self}\e[0m"; end
  def red!; colorize!(31); end
  def green!; colorize!(32); end
  def yellow!; colorize!(33); end
end

# Initial notification
version = 'CS 352 Project Test Script [Ruby v0.9] - Jon Egeland, 2015'
puts version
puts "\nSetup:"
puts "------"
puts "Tester:   #{TESTER}"
puts "Test dir: #{TEST_DIR}"



# Ensure the program exists
`make`

# Open the log file
log = File.open(ERR_FILE, 'w')



# Keep track of passed vs. total
test_count = pass_count = 0

# Run the tests
puts "\n\nTests:"
puts "------"
Dir.glob(TEST_DIR).each do |t|
  # Skips `.`, `..`, and any folders.
  # Needs to be changed to support complex file structures
  next unless File.file?(t)

  # Determine if the test is supposed to pass or fail
  should_fail = !!t.split('/')[-1][/^err_/]

  # Extract the test name
  name = t.split('/')[-1].sub(/^(err_)*test_/, '').tr('_', ' ')

  # Run the test
  Open3.popen3("#{TESTER} #{t}") do |cin, cout, cerr, cwait|
    # Get the output
    output = cerr.read
    failed = output != ''

    # Determine whether or not it passed
    result = failed == should_fail ? 'passed' : 'FAILED'

    # Write failures to the log
    if failed != should_fail
      if should_fail
        log.write("Expected 'fail' for \"#{name}\" (got 'pass')")
      else
        log.write("Expected 'pass' for \"#{name}\" (got 'fail'): \n#{output}\n\n")
      end
    end

    # Print the result
    if result == 'passed'
      puts "#{result}: #{name}".green!
    else
      puts "#{result}: #{name}".red!
    end

    # Iterate the counters
    test_count+=1
    pass_count+=1 if result == 'passed'
  end
end

# Close the log file
log.close


if test_count > 0
  ratio = pass_count / test_count
else
  ratio = 0
end
passed_text = "#{pass_count}/#{test_count} tests passed."
if ratio >= 1
  passed_text.green!
elsif ratio >= 0.8
  passed_text.yellow!
else
  passed_text.red!
end


# Final notification
puts "\n\nResults:"
puts "--------"
puts passed_text
puts "Errors have been logged in: #{ERR_FILE}"
