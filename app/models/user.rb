require "net/http"
require "uri"
require "json"

class User < ApplicationRecord
  has_many :tickets
  validates :cclogin,
            presence: true,
            length: { minimum: 1, maximum: 12 },
            format: { with: /\A[A-Za-z]+\z/ },
            uniqueness: true
  attr_accessor :password
  before_create :user_realname
  validate :valid_login?

  def valid_login?
    if password.class.to_s != "String"
      return errors.add(:password, "must be a string")
    end
    uri = URI.parse("https://dashboard.pclub.in/api/user/login")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(uri.path)
    data = { "username" => cclogin, "password" => password }.to_json
    request.body = data.to_s
    response = https.request(request)
    return true if response.code == "200"
    errors.add(:password, "username/password combination may not be valid")
  end

  def user_realname
    # This method is never entered if the cclogin is repeated, so, no worries
    # about wasted GET requests
    uri = URI.parse("https://search.pclub.in/api/student?username=#{cclogin}")
    response = Net::HTTP.get_response(uri)
    return unless response.code == "200"
    self.name = JSON.parse(response.body)["n"]
  end
end
