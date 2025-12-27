require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # Helper method to sign in a user (Spanish localized)
  def sign_in_user(user, password = "password123")
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: password
    click_button "Iniciar sesión"
    assert_text "Sesión iniciada exitosamente", wait: 5
  end
end
