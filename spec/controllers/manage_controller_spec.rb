require 'spec_helper'

describe ManageController do

  describe "GET 'users'" do
    it "returns http success" do
      get 'users'
      response.should be_success
    end
  end

  describe "GET 'spaces'" do
    it "returns http success" do
      get 'spaces'
      response.should be_success
    end
  end

  describe "GET 'institutions'" do
    it "returns http success" do
      get 'institutions'
      response.should be_success
    end
  end

  describe "GET 'spam'" do
    it "returns http success" do
      get 'spam'
      response.should be_success
    end
  end

end
