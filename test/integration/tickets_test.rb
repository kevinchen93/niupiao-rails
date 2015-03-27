require 'test_helper'
require 'integration/integration_helper_test'

class TicketsTest < ActionDispatch::IntegrationTest
  include IntegrationHelperTest

  def setup
    @event = Event.create!(
                           name: 'TestEvent',
                           date: DateTime.now,
                           organizer: 'TestOrganizer',
                           location: 'Williamstown, MA',
                           description: 'TestDescription',
                           image_path: 'TestImagePath',
                           link: 'TestLink',
                           total_tickets: 0,
                           tickets_sold: 0
                           )
    @general = TicketStatus.create!(name: "General", max_purchasable: 3, price: 50)
    @vip = TicketStatus.create!(name: "VIP", max_purchasable: 2, price: 150)
    @event.ticket_statuses << @general
    @event.ticket_statuses << @vip
    @event.save!

    @user1 = User.create(email: 'kmc3@williams.edu', password: 'foobar', name: 'Kevin Chen', first_name: 'Kevin', last_name: 'Chen')
    @user2 = User.create(email: 'rhk1@williams.edu', password: 'foobar', name: 'Ryan Kwon',  first_name: 'Ryan',  last_name: 'Kwon')
    login @user1
  end

  test "should buy ticket" do

    # Create a ticket that NO ONE owns
    ticket = Ticket.create!(event: @event, ticket_status: @general)

    # Buy the ticket
    assert_not_nil @user1.api_key.access_token
    post "/events/#{@event.id}/tickets/#{ticket.id}/buy.json"#, nil, headers
    puts prettify(json)
    assert_equal @user1.id, json['ticket']['user_id']
    
  end
  
  test "MyTickets should only show tickets you own" do

    # Create a ticket that we User1 owns
    assert_difference('Ticket.count') do
      post "/events/#{@event.id}/tickets", ticket: {
        event_id: @event.id,
        user_id: @user1.id,
        ticket_status_id: @general.id
      }
    end

    # Create a ticket that NO ONE owns
    assert_difference('Ticket.count') do
      post "/events/#{@event.id}/tickets", ticket: {
        event_id: @event.id,
        ticket_status_id: @general.id
      }
    end

    # Get my tickets
    #    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Token.encode_credentials(token)
    token = @user1.api_key.access_token
    headers = { 'Authorization' => "Token token=\"#{token}\"" }
    get '/me/tickets.json', {}, headers
    
    assert_equal JSON.pretty_generate(@user1.my_tickets), prettify(json)
    
  end

end
