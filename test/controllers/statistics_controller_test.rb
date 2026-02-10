require_relative '../test_helper'

class StatisticsControllerTest < ControllerTest
  def test_get_statistics_index
    m = create_member
    login_as(m)
    get '/statistics/'
    assert_equal 200, last_response.status
  end

  def test_get_data_studied
    m = create_member(studied: "F")
    login_as(m)
    get '/statistics/data/studied'
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert data.any? { |d| d['name'] == 'F' }
  end

  def test_get_data_started
    m = create_member(started: 2020)
    login_as(m)
    get '/statistics/data/started'
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert data.any? { |d| d['name'] == 2020 }
  end

  def test_get_data_city
    m = create_member(city: "Lund")
    login_as(m)
    get '/statistics/data/city'
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert data.any? { |d| d['name'] == 'Lund' }
  end
end
