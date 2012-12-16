require 'spec_helper'

describe Accelerator do

  before(:all) do
    @accelerator = Accelerator.new
    @accelerator.set("/test", "poop")
    # `curl http://localhost:8080/test`
  end

  it "should" do
    puts @accelerator.get("/test")
  end
end