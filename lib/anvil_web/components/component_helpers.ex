defmodule AnvilWeb.Components.ComponentHelpers do
  @moduledoc """
  Helper functions for UI components used throughout the application.
  """

  @doc """
  Generate a Gravatar URL from an email address.

  ## Parameters
  - `email`: The email address to use for the Gravatar
  - `size`: The pixel size of the Gravatar image (default: 200)

  ## Examples
      iex> gravatar_url("user@example.com")
      "https://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af?d=retro&s=200"
      
      iex> gravatar_url("user@example.com", 80)
      "https://www.gravatar.com/avatar/b58996c504c5638798eb6b511e6f49af?d=retro&s=80"
      
      iex> gravatar_url(nil)
      "https://www.gravatar.com/avatar/034e48d1a5355126203e248a91523938?d=retro&s=200"
  """
  def gravatar_url(email, size \\ 200)

  def gravatar_url(email, size) when is_nil(email), do: gravatar_url("no-email@example.com", size)

  def gravatar_url(email, size) do
    # Convert the email to a string (in case it's an Ash.CiString)
    email_str = to_string(email)

    # Trim and lowercase the email
    email_str =
      email_str
      |> String.trim()
      |> String.downcase()

    # Calculate MD5 hash of the email
    hash =
      :crypto.hash(:md5, email_str)
      |> Base.encode16(case: :lower)

    # Build Gravatar URL with retro 8-bit style default
    # d=retro: Use pixelated retro avatars if no Gravatar exists
    # s=size: Request image at the specified size
    "https://www.gravatar.com/avatar/#{hash}?d=retro&s=#{size}"
  end
end
