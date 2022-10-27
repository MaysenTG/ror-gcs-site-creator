require "test_helper"

class BulkMailerTest < ActionMailer::TestCase
  test "bulk_send" do
    mail = BulkMailer.bulk_send
    assert_equal "Bulk send", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
