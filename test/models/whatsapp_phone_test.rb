require "test_helper"

class WhatsappPhoneTest < ActiveSupport::TestCase
  {
    "+54 9 11 1234-5678" => "5491112345678",
    "5491112345678" => "5491112345678",
    "54 11 1234 5678" => "5491112345678",
    "011 1234-5678" => "5491112345678",
    "011 15 1234-5678" => "5491112345678",
    "11 15 1234 5678" => "5491112345678",
    "1112345678" => "5491112345678",
    "0054 9 11 1234 5678" => "5491112345678",
    "0351 15 123-4567" => "5493511234567",
    "(0341) 15-512-3456" => "5493415123456",
    "02966 15 12 3456" => "5492966123456"
  }.each do |raw, expected|
    test "normalizes #{raw.inspect}" do
      assert_equal expected, WhatsappPhone.normalize(raw)
    end
  end

  [ nil, "", "   ", "abc", "555-0100", "123", "+1 415 555 2671", "54 9 11 1234", "15 1234-5678", "1512345678", "15 1234 5678" ].each do |raw|
    test "returns nil for #{raw.inspect}" do
      assert_nil WhatsappPhone.normalize(raw)
    end
  end

  test "Client#whatsapp_phone normalizes the stored phone without changing it" do
    client = Client.new(phone: "011 15 1234-5678")
    assert_equal "5491112345678", client.whatsapp_phone
    assert_equal "011 15 1234-5678", client.phone
  end
end
