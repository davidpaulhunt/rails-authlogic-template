def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

gem 'authlogic'

environment "config.action_mailer.default_url_options = { host: '127.0.0.1:3000' }", env: 'development'

directory 'app'

application_controller_code = <<-CODE

  helper_method :current_user_session, :current_user

  private

  def current_user_session
    @current_user_session ||= UserSession.find
  end

  def current_user
    @current_user ||= (current_user_session && current_user_session.user)
  end

  protected

  def handle_unverified_request
    # raise an exception
    fail ActionController::InvalidAuthenticityToken
    # or destroy session, redirect
    if current_user_session
      current_user_session.destroy
    end
    redirect_to root_url
  end
CODE

inside 'app/controllers' do
  insert_into_file 'application_controller.rb', application_controller_code, after: "protect_from_forgery with: :exception\n"
end

router_code = <<-CODE

  resources :users, only: [:new, :create]
  get 'signup' => 'users#new'
  post 'signup' => 'users#create'

  resources :user_sessions, only: [:create, :destroy]
  get 'signin' => 'user_sessions#new'
  delete 'signout' => 'user_sessions#destroy'

  resources :password_resets, only: [:new, :create, :edit, :update]
  get 'forgot_password' => 'password_resets#new'

  root 'home#index'
CODE

inside 'config' do
  insert_into_file 'routes.rb', router_code, after: ".html\n"
end

application_view_code = <<-CODE
    <% flash.each do |key, value| %>
      <div>
        <%= value %>
      </div>
    <% end %>
    <% if current_user %>
      <%= link_to 'Signout', signout_path, method: :delete %>
    <% else %>
      <%= link_to 'Signin', signin_path %>
    <% end %>
CODE

inside 'app/views/layouts' do
  insert_into_file 'application.html.erb', application_view_code, after: "<body>\n"
end

comment_lines 'Gemfile', /gem 'coffee-rails', '~> [\.\d]+'/

migration_code = <<-CODE
    create_table :users do |t|
      t.string :username

      # Authlogic::ActsAsAuthentic::Email
      t.string    :email

      # Authlogic::ActsAsAuthentic::Password
      t.string    :crypted_password
      t.string    :password_salt

      # Authlogic::ActsAsAuthentic::PersistenceToken
      t.string    :persistence_token

      # Authlogic::ActsAsAuthentic::SingleAccessToken
      t.string    :single_access_token

      # Authlogic::ActsAsAuthentic::PerishableToken
      t.string    :perishable_token

      # Authlogic::Session::MagicColumns
      t.integer   :login_count, default: 0, null: false
      t.integer   :failed_login_count, default: 0, null: false
      t.datetime  :last_request_at
      t.datetime  :current_login_at
      t.datetime  :last_login_at
      t.string    :current_login_ip
      t.string    :last_login_ip

      t.timestamps
    end

    add_index :users, :username, unique: true
    add_index :users, :email, unique: true
    add_index :users, :persistence_token, unique: true
    add_index :users, :single_access_token, unique: true
    add_index :users, :perishable_token, unique: true
CODE

after_bundle do
  generate :migration, 'AuthlogicCreateUsers'

  inside('db/migrate') do |fullpath|
    migration_file_path = Dir.entries(fullpath).slice(2)
    insert_into_file migration_file_path, migration_code, after: "def change\n"
  end

  run 'spring stop'
end
