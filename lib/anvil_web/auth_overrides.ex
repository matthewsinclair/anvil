defmodule AnvilWeb.AuthOverrides do
  @moduledoc """
  UI customizations for AshAuthentication Phoenix components.
  Overrides default authentication UI with Anvil's 8-bit retro theme.
  """
  use AshAuthentication.Phoenix.Overrides

  # For complete reference, see https://hexdocs.pm/ash_authentication_phoenix/ui-overrides.html

  # Banner with Anvil logo
  override AshAuthentication.Phoenix.Components.Banner do
    set :image_url, "/images/anvil_logo.svg"
    set :dark_image_url, nil
    set :image_class, "w-20 h-20 md:w-24 md:h-24 pixelated"
    set :href_url, nil
    set :root_class, "flex justify-center mb-6"
  end

  # Show banner on sign-in page
  override AshAuthentication.Phoenix.Components.SignIn do
    set :show_banner, true

    set :root_class,
        "flex-1 flex flex-col justify-center py-8 px-4 sm:px-6 lg:flex-none lg:px-20 xl:px-24"

    set :strategy_class, "mx-auto w-full max-w-sm lg:w-96"
  end

  # Page layout - vertical centering for all auth pages
  override AshAuthentication.Phoenix.SignInLive do
    set :root_class, "grid h-screen place-items-center pt-0 -mt-10 bg-base-100"
  end

  override AshAuthentication.Phoenix.ResetLive do
    set :root_class, "grid h-screen place-items-center pt-0 -mt-10 bg-base-100"
  end

  override AshAuthentication.Phoenix.ConfirmLive do
    set :root_class, "grid h-screen place-items-center pt-0 -mt-10 bg-base-100"
  end

  override AshAuthentication.Phoenix.MagicSignInLive do
    set :root_class, "grid h-screen place-items-center pt-0 -mt-10 bg-base-100"
  end

  # Password component styling
  override AshAuthentication.Phoenix.Components.Password do
    set :interstitial_class,
        "flex flex-row justify-between content-between text-sm font-medium font-mono"

    set :toggler_class, "flex-none text-primary hover:text-primary/80 px-2 first:pl-0 last:pr-0"
    set :sign_in_toggle_text, "Already have an account?"
    set :register_toggle_text, "Need an account?"
    set :reset_toggle_text, "Forgot your password?"
  end

  # Form input styling to match Anvil's retro theme
  override AshAuthentication.Phoenix.Components.Password.Input do
    # Submit button styling - retro pixelated style
    set :submit_class, """
    w-full flex justify-center py-2 px-4 border-2 border-black
    text-sm font-medium text-primary-content bg-primary hover:bg-primary/90
    focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary
    mt-4 mb-4 uppercase font-mono tracking-wider
    shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]
    active:shadow-none active:translate-x-1 active:translate-y-1
    transition-all duration-100
    """

    # Input fields styling - retro terminal style
    set :input_class, """
    appearance-none block w-full px-3 py-2 border-2
    placeholder-base-content/50 focus:outline-none sm:text-sm
    border-primary focus:ring-primary focus:border-primary
    bg-base-100 font-mono
    """

    set :input_class_with_error, """
    appearance-none block w-full px-3 py-2 border-2
    placeholder-base-content/50 focus:outline-none sm:text-sm
    border-error focus:border-error focus:ring-error/30
    bg-base-100 font-mono
    """

    set :field_class, "space-y-1"

    set :label_class,
        "block text-sm font-medium text-base-content uppercase tracking-wider font-mono"

    set :error_ul, "mt-1 text-sm text-error font-mono"
    set :error_li, "list-disc list-inside"
  end

  # OAuth2 button styling
  override AshAuthentication.Phoenix.Components.OAuth2 do
    set :link_class, """
    w-full flex justify-center py-2 px-4 border-2 border-base-content
    text-sm font-medium bg-base-100 hover:bg-base-200
    focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary
    inline-flex items-center uppercase font-mono tracking-wider
    """
  end

  # Apple OAuth button styling
  override AshAuthentication.Phoenix.Components.Apple do
    set :link_class, """
    w-full flex justify-center py-2 px-4 border-2 border-base-content
    text-sm font-medium bg-base-100 hover:bg-base-200
    focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary
    inline-flex items-center uppercase font-mono tracking-wider
    """
  end

  # Form component styling
  override AshAuthentication.Phoenix.Components.Password.SignInForm do
    set :button_text, ">> LOGIN"
    set :disable_button_text, ">> LOGGING IN..."
    set :form_class, "space-y-6"

    set :label_class,
        "text-2xl font-bold text-center text-base-content mb-6 uppercase font-mono tracking-wider"
  end

  override AshAuthentication.Phoenix.Components.Password.RegisterForm do
    set :button_text, ">> REGISTER"
    set :disable_button_text, ">> REGISTERING..."
    set :form_class, "space-y-6"

    set :label_class,
        "text-2xl font-bold text-center text-base-content mb-6 uppercase font-mono tracking-wider"
  end

  override AshAuthentication.Phoenix.Components.Password.ResetForm do
    set :button_text, ">> RESET PASSWORD"
    set :disable_button_text, ">> SENDING RESET EMAIL..."
    set :form_class, "space-y-6"

    set :label_class,
        "text-2xl font-bold text-center text-base-content mb-6 uppercase font-mono tracking-wider"

    set :reset_flash_text, "If your email is in our system, we've sent you a password reset link."
  end

  # Magic Link styling
  override AshAuthentication.Phoenix.Components.MagicLink do
    set :button_text, ">> SEND MAGIC LINK"
    set :disable_button_text, ">> SENDING..."
    set :form_class, "space-y-6"

    set :label_class,
        "text-2xl font-bold text-center text-base-content mb-6 uppercase font-mono tracking-wider"

    set :request_flash_text, "If your email is in our system, we've sent you a magic link."
  end

  override AshAuthentication.Phoenix.Components.MagicLink.Input do
    set :submit_class, """
    w-full flex justify-center py-2 px-4 border-2 border-black
    text-sm font-medium text-primary-content bg-primary hover:bg-primary/90
    focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary
    mt-4 mb-4 uppercase font-mono tracking-wider
    shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]
    active:shadow-none active:translate-x-1 active:translate-y-1
    transition-all duration-100
    """
  end

  # Confirmation components
  override AshAuthentication.Phoenix.Components.Confirm do
    set :show_banner, true
    set :root_class, "flex-1 flex flex-col justify-center py-8 px-4 sm:px-6"
    set :strategy_class, "mx-auto w-full max-w-sm"
  end

  override AshAuthentication.Phoenix.Components.Confirm.Input do
    set :submit_class, """
    w-full flex justify-center py-2 px-4 border-2 border-black
    text-sm font-medium text-primary-content bg-primary hover:bg-primary/90
    focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary
    mt-4 mb-4 uppercase font-mono tracking-wider
    shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]
    active:shadow-none active:translate-x-1 active:translate-y-1
    transition-all duration-100
    """
  end

  # Reset components
  override AshAuthentication.Phoenix.Components.Reset do
    set :show_banner, true
    set :root_class, "flex-1 flex flex-col justify-center py-8 px-4 sm:px-6"
    set :strategy_class, "mx-auto w-full max-w-sm"
  end

  # Horizontal rule styling (for "or" between methods)
  override AshAuthentication.Phoenix.Components.HorizontalRule do
    set :root_class, "relative my-4"
    set :hr_outer_class, "absolute inset-0 flex items-center"
    set :hr_inner_class, "w-full border-t-2 border-primary"
    set :text_outer_class, "relative flex justify-center text-sm"
    set :text_inner_class, "px-2 bg-base-100 text-base-content font-mono uppercase tracking-wider"
    set :text, "or"
  end

  # Flash message styling to match retro theme
  override AshAuthentication.Phoenix.Utils.Flash do
    set :classes, %{
      info: "alert alert-info w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap border-2 font-mono",
      error: "alert alert-error w-80 sm:w-96 max-w-80 sm:max-w-96 text-wrap border-2 font-mono"
    }
  end
end
