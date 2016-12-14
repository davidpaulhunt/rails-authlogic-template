class PasswordResetsController < ApplicationController
  def new
  end

  def create
    @user = User.find_by(email: params[:email])
    if @user
      @user.deliver_password_reset_instructions!
    end
    flash[:success] = "You will receive an email shortly to reset your password. Thanks!"
    redirect_to root_url
  end

  def edit
    @user = User.find_by(perishable_token: params[:id])
  end

  def update
    @user = User.find_by(perishable_token: params[:id])
    if @user.update_attributes(password_reset_params)
      flash[:success] = 'Password successfully updated!'
      redirect_to root_url
    else
      render :edit
    end
  end

  private

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
