module TestFramework
  def self.init
    @@failed_tests = []
    @@test_count = 0
  end

  def self.check(test_no: -1, should_be: nil, &block)
    result = block.call
    
    if result.is_a?(Array)
      result.collect! {|x| x.is_a?(Float) ? x.round(5) : x}
    end

    if should_be.is_a?(Array)
      should_be.collect! {|x| x.is_a?(Float) ? x.round(5) : x}
    end

    @@test_count += 1

    if should_be == result
      puts "\e[32m[Test #{test_no}] passed with result #{result.inspect}.\e[0m"
    else
      @@failed_tests.push test_no
      puts "\e[31m*** FAILURE: [Test #{test_no}] was expected to return #{should_be.inspect}, but returned #{result.inspect}.\e[0m"
    end
  end

  def self.results
    if @@failed_tests.empty?
      puts "\e[32mA total number of #{@@test_count} tests was done without issues.\e[0m"
    else
      puts "\e[31m*** FAILURE: #{@@failed_tests.size} out of #{@@test_count} tests failed.\e[0m"
      puts "\e[31m*** FAILURE: The following tests failed: #{@@failed_tests.inspect}.\e[0m"
    end
  end
end