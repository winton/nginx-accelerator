require "pp"
require "bundler"

Bundler.require(:development)

$root = File.expand_path('../../', __FILE__)

require "#{$root}/lib/accelerator"

def request(wait=nil)
  sleep(wait) if wait
  `curl -s http://localhost:8080/test#{"?blah" if Random.rand(2) == 0}`.strip.to_i
end

def response_tests(time)
  $last_time = time
  body, options = @accelerator.get("/test")
  body.strip.should == time.to_s
  options.should == {
    :ttl => 1,
    :status => 200,
    :header => { 
      :"Content-Length" => 11,
      :"Content-Type" => "text/plain"
    },
    :time => time
  }
  request.should == time
end