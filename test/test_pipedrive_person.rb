# frozen_string_literal: true

require 'helper'

class TestPipedrivePerson < Test::Unit::TestCase
  def setup
    Pipedrive.authenticate('some-token')
  end

  body = {
    'email' => ['john@dope.org'],
    'name' => 'John Dope',
    'org_id' => '404',
    'phone' => ['0123456789']
  }

  should 'execute a valid person request' do
    stub_request(:post, 'https://api.pipedrive.com/v1/persons?api_token=some-token')
      .with(body: body, headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => 'Ruby.Pipedrive.Api'
            })
      .to_return(
        status: 200,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'create_person_body.json')),
        headers: {
          'server' => 'nginx/1.2.4',
          'date' => 'Fri, 01 Mar 2013 13:34:23 GMT',
          'content-type' => 'application/json',
          'content-length' => '1164',
          'connection' => 'keep-alive',
          'access-control-allow-origin' => '*'
        }
      )

    person = ::Pipedrive::Person.create(body)

    assert_equal 'John Dope', person.name
    assert_equal 404, person.org_id
    assert_equal 'john@dope.org', person.email.first.fetch('value')
    assert_equal '0123456789', person.phone.first.fetch('value')
  end

  should 'return bad_response on errors' do
    stub_request(:post, 'https://api.pipedrive.com/v1/persons?api_token=some-token')
      .with(body: body,
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => 'Ruby.Pipedrive.Api'
            })
      .to_return(
        status: 401,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'error_response.json')),
        headers: {
          'server' => 'nginx/1.2.4',
          'date' => 'Fri, 01 Mar 2020 14:01:03 GMT',
          'content-type' => 'application/json',
          'content-length' => '1260',
          'connection' => 'keep-alive',
          'access-control-allow-origin' => '*'
        }
      )

    assert_raise(HTTParty::ResponseError) { Pipedrive::Deal.create(body) }
  end
end
