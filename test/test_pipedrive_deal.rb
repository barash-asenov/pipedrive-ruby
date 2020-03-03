# frozen_string_literal: true

require 'helper'

class TestPipedriveDeal < Test::Unit::TestCase
  WebMock.allow_net_connect!

  def setup
    Pipedrive.authenticate('some-token')
  end

  body = {
    'currency' => 'EUR',
    'org_id' => '72312',
    'title' => 'Dope Deal',
    'value' => '37k'
  }

  should 'execute a valid deal request' do
    stub_request(:post, 'https://api.pipedrive.com/v1/deals?api_token=some-token')
      .with(body: body,
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => 'Ruby.Pipedrive.Api'
            })
      .to_return(
        status: 200,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'deal/create_deal_body.json')),
        headers: {
          'server' => 'nginx/1.2.4',
          'date' => 'Fri, 01 Mar 2020 14:01:03 GMT',
          'content-type' => 'application/json',
          'content-length' => '1260',
          'connection' => 'keep-alive',
          'access-control-allow-origin' => '*'
        }
      )

    deal = ::Pipedrive::Deal.create(body)

    assert_equal 'Dope Deal', deal.title
    assert_equal 37, deal.value
    assert_equal 'EUR', deal.currency
    assert_equal 72_312, deal.org_id
  end

  should 'add note for a deal' do
    deal_id = 15

    stub_request(:get, "https://api.pipedrive.com/v1/deals/#{deal_id}?api_token=some-token")
      .to_return(
        status: 200,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'deal/read_one_deal_body.json'))
      )

    deal = ::Pipedrive::Deal.find(deal_id)

    stub_request(:post, 'https://api.pipedrive.com/v1/notes?api_token=some-token')
      .to_return(
        status: 200,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'note/add_note_body.json'))
      )
    
    note = deal.add_note('some-note')

    assert_equal 'some-note', note.content
  end

  should 'get one deal' do
    deal_id = 15

    stub_request(:get, "https://api.pipedrive.com/v1/deals/#{deal_id}?api_token=some-token")
      .to_return(
        status: 200,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'deal/read_one_deal_body.json'))
      )

    deal = ::Pipedrive::Deal.find(deal_id)

    assert_equal 'Dope Deal', deal.title
    assert_equal 37, deal.value
    assert_equal 'EUR', deal.currency
    assert_equal 72_312, deal.org_id
  end

  should 'get all deals' do
    stub_request(:get, 'https://api.pipedrive.com/v1/deals?api_token=some-token')
      .to_return(
        status: 200,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'deal/read_all_deals_body.json'))
      )

    deals = ::Pipedrive::Deal.all

    assert_equal 28, deals.count
    assert_equal 'Einsvier-Nullacht-Charlotte-Einszwo KGaA  deal', deals[0].title
  end

  should 'update a deal' do
    deal_id = 337
    update_title = 'example title'

    stub_request(:get, "https://api.pipedrive.com/v1/deals/#{deal_id}?api_token=some-token")
      .to_return(
        status: 200,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'deal/read_one_deal_body.json'))
      )

    deal = ::Pipedrive::Deal.find(deal_id)

    stub_request(:put, "https://api.pipedrive.com/v1/deals/#{deal_id}?api_token=some-token")
      .with(body: { title: update_title },
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/x-www-form-urlencoded',
              'User-Agent' => 'Ruby.Pipedrive.Api'
            })
      .to_return(
        status: 200,
        body: File.read(File.join(File.dirname(__FILE__), 'data', 'deal/update_deal_body.json'))
      )

    updated_deal = deal.update({ title: update_title })

    assert_equal update_title, updated_deal.title
  end

  should 'raises response error' do
    stub_request(:post, 'https://api.pipedrive.com/v1/deals?api_token=some-token')
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

    assert_raises(HTTParty::ResponseError) { ::Pipedrive::Deal.create(body) }
  end
end
