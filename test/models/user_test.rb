# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "default role is general" do
    user = User.new(email: "new@example.com", password: "password123")
    assert_predicate user, :general?
  end

  test "all role values are accepted" do
    %w[general admin stock_loader].each do |role|
      user = User.new(email: "new_#{role}_test@example.com", password: "password123", role: role)
      assert user.valid?, "#{role} should be a valid role"
    end
  end

  test "role predicates work" do
    assert_predicate users(:admin), :admin?
    assert_predicate users(:stock_loader), :stock_loader?
    assert_predicate users(:one), :general?
  end

  test "invalid role is rejected" do
    user = User.new(email: "x@example.com", password: "password123", role: "superuser")
    assert_not user.valid?
  end
end
