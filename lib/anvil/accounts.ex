defmodule Anvil.Accounts do
  use Ash.Domain, otp_app: :anvil, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Anvil.Accounts.Token
    resource Anvil.Accounts.User
    resource Anvil.Accounts.ApiKey
  end
end
