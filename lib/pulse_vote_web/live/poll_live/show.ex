defmodule PulseVoteWeb.PollLive.Show do
  use PulseVoteWeb, :live_view

  alias PulseVote.Polls

  on_mount {PulseVoteWeb.UserAuth, :mount_current_user}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    case socket.assigns.live_action do
      :edit ->
        {:noreply, apply_action(socket, :edit, params)}
      
      :show ->
        poll = Polls.get_poll!(id)
        user = socket.assigns.current_user
        
        # Subscribe to real-time updates for this poll
        if connected?(socket) do
          Phoenix.PubSub.subscribe(PulseVote.PubSub, "poll:#{poll.id}")
        end
        
        # Check if user has already voted
        user_vote = if user, do: Polls.get_user_vote(poll.id, user.id), else: nil
        
        {:noreply,
         socket
         |> assign(:page_title, page_title(socket.assigns.live_action))
         |> assign(:poll, poll)
         |> assign(:user_vote, user_vote)
         |> assign(:total_votes, Polls.get_total_votes(poll.id))
         |> assign(:show_results, false)}
    end
  end

  @impl true
  def handle_event("vote", %{"option_index" => option_index}, socket) do
    case socket.assigns.current_user do
      nil ->
        {:noreply, put_flash(socket, :error, "You must be logged in to vote")}
      
      user ->
        option_index = String.to_integer(option_index)
        
        case Polls.cast_vote(socket.assigns.poll.id, option_index, user.id) do
          {:ok, _vote} ->
            # Refresh poll data
            poll = Polls.get_poll!(socket.assigns.poll.id)
            user_vote = Polls.get_user_vote(poll.id, user.id)
            
            {:noreply,
             socket
             |> assign(:poll, poll)
             |> assign(:user_vote, user_vote)
             |> assign(:total_votes, Polls.get_total_votes(poll.id))
             |> put_flash(:info, "🎉 Thanks for voting!")}
          
          {:error, changeset} ->
            error_msg = 
              case changeset.errors do
                [poll_id: {"You have already voted on this poll", _}] -> 
                  "You have already voted on this poll"
                _ -> 
                  "Unable to cast vote"
              end
            {:noreply, put_flash(socket, :error, error_msg)}
        end
    end
  end

  @impl true
  def handle_event("toggle_results", _params, socket) do
    {:noreply, assign(socket, :show_results, !socket.assigns.show_results)}
  end

  @impl true
  def handle_info({:poll_updated, poll_id}, socket) do
    if socket.assigns.poll.id == poll_id do
      # Refresh poll data with new vote counts
      updated_poll = Polls.get_poll!(poll_id)
      total_votes = Polls.get_total_votes(poll_id)
      
      {:noreply,
       socket
       |> assign(:poll, updated_poll)
       |> assign(:total_votes, total_votes)}
    else
      {:noreply, socket}
    end
  end

  defp page_title(:show), do: "Poll"
  defp page_title(:edit), do: "Edit Poll"
  
  defp apply_action(socket, :edit, %{"id" => id}) do
    poll = Polls.get_poll!(id)
    current_user = socket.assigns.current_user
    
    if Polls.can_edit_poll?(poll, current_user) do
      socket
      |> assign(:page_title, "Edit Poll")
      |> assign(:poll, poll)
    else
      socket
      |> put_flash(:error, "You can only edit polls you created")
      |> push_patch(to: ~p"/polls/#{id}")
    end
  end
  
end
