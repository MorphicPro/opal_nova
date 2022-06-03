# lib/tutorial/presence.ex
defmodule OpalNova.Presence do
  use Phoenix.Presence, otp_app: :tutorial, pubsub_server: OpalNova.PubSub
end
