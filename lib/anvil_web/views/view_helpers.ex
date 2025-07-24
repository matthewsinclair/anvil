defmodule AnvilWeb.ViewHelpers do
  @moduledoc """
  Common view helper functions used across LiveViews and templates.
  """

  @doc """
  Returns the appropriate badge CSS class for an edit mode.
  """
  def badge_class_for_edit_mode(:live), do: "badge-success"
  def badge_class_for_edit_mode(:review), do: "badge-warning"
  def badge_class_for_edit_mode(:locked), do: "badge-error"
  def badge_class_for_edit_mode(_), do: "badge-ghost"

  @doc """
  Formats a datetime in a user-friendly way.
  """
  def format_date(nil), do: ""
  def format_date(datetime), do: Calendar.strftime(datetime, "%b %d, %Y")

  @doc """
  Formats a datetime with time in a user-friendly way.
  """
  def format_datetime(nil), do: ""
  def format_datetime(datetime), do: Calendar.strftime(datetime, "%b %d, %Y at %I:%M %p")

  @doc """
  Returns a retro icon for common actions.
  """
  def retro_icon(:add), do: "+"
  def retro_icon(:edit), do: "✎"
  def retro_icon(:delete), do: "✗"
  def retro_icon(:view), do: "→"
  def retro_icon(:back), do: "←"
  def retro_icon(:menu), do: "⋮"
  def retro_icon(:project), do: "▪"
  def retro_icon(:prompt), do: "▸"
  def retro_icon(:version), do: "◆"
  def retro_icon(:dashboard), do: "▶"
  def retro_icon(:settings), do: "⚙"
  def retro_icon(:help), do: "?"
  def retro_icon(:account), do: "◆"
  def retro_icon(:logout), do: "⬅"
  def retro_icon(:code), do: "{ }"
  def retro_icon(:remove), do: "−"
  def retro_icon(:check), do: "✓"
  def retro_icon(:team), do: "☰"
end
