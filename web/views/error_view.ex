defmodule Democracy.ErrorView do
  use Democracy.Web, :view

  def render("error.json", %{message: message}) do
    %{errors: [message]}
  end
end
