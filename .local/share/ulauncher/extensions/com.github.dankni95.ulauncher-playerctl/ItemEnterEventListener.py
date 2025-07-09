import playerctl
from ulauncher.api.client.EventListener import EventListener


class ItemEnterEventListener(EventListener):
    def on_event(self, event, extension):

        data = event.get_data()
        extension.logger.debug(str(data))

        if data["action"] == "jump":
            playerctl.jump(data["pos"])
        elif data["action"] == "playpause":
            playerctl.playpause()
        elif data["action"] == "next":
            playerctl.next()
            return extension.render_main_page("next")
        elif data["action"] == "prev":
            playerctl.prev()
            return extension.render_main_page("prev")
        elif data["action"] == "mute":
            playerctl.mute("0")
        elif data["action"] == "set_vol":
            amount = int("".join(filter(str.isdigit, data["amount"])))
            control_volume = data["global_or_player"]

            if amount > 100:
                amount = 100
            playerctl.volume(amount, control_volume)

        elif data["action"] == "show_player":
            return extension.render_main_page("change_player")
        elif data["action"] == "change_players":
            player_chosen = data["player"]
            playerctl.change_player(player_chosen)
