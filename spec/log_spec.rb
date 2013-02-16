# require 'spec_helper'

describe GitPusshuTen::Log do
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("[message] ".color(:green) + "heavenly message")
    GitPusshuTen::Log.message("heavenly message")
  end
  
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("[warning] ".color(:yellow) + "heavenly message")
    GitPusshuTen::Log.warning("heavenly message")
  end
  
  it "should log a message" do
    GitPusshuTen::Log.expects(:puts).with("[error] ".color(:red) + "heavenly message")
    GitPusshuTen::Log.error("heavenly message")
  end
end