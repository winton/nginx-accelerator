require 'spec_helper'

describe Accelerator do

  before(:all) do
    @accelerator = Accelerator.new
    @accelerator.delete("/test")
  end

  it "should create cache on first request" do
    `curl http://localhost:8080/test`
    time = Time.new.to_i
    body, options = @accelerator.get("/test")
    body.strip.should == time.to_s
    options.should == {
      :ttl => 5,
      :status => 200,
      :header => { 
        :"Content-Length" => 11,
        :"Content-Type" => "text/plain"
      },
      :time => time
    }
  end
end