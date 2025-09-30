class UserMailer < ApplicationMailer
  def welcome_email(user)
    @user = user
    @profile = user.profile
    @dashboard_url = dashboard_url
    
    mail(
      to: user.email,
      subject: "Welcome to Agricultural Logistics Platform!"
    )
  end

  def verification_email(user)
    @user = user
    @verification_url = complete_profile_url
    
    mail(
      to: user.email,
      subject: "Please complete your profile"
    )
  end
end