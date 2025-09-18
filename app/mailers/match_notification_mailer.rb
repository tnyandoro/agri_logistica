class MatchNotificationMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.match_notification_mailer.new_match.subject
  #
  def new_match
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end
