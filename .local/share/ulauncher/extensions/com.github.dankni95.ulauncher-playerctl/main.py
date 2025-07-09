import playerctl
from ulauncher.api.client.Extension import Extension
from ulauncher.api.shared.event import KeywordQueryEvent, ItemEnterEvent
from KeywordQueryEventListener import KeywordQueryEventListener
from ItemEnterEventListener import ItemEnterEventListener
from ulauncher.api.shared.item.ExtensionResultItem import ExtensionResultItem
from ulauncher.api.shared.action.DoNothingAction import DoNothingAction
from ulauncher.api.shared.action.ExtensionCustomAction import ExtensionCustomAction
from ulauncher.api.shared.action.RenderResultListAction import RenderResultListAction
from ulauncher.api.shared.action.SetUserQueryAction import SetUserQueryAction


class PlayerMain(Extension):
    def __init__(self):
        super(PlayerMain, self).__init__()
        self.logger.info("Inializing Extension")
        self.subscribe(KeywordQueryEvent, KeywordQueryEventListener())
        self.subscribe(ItemEnterEvent, ItemEnterEventListener())

    def render_main_page(self, action):
        theme = str(self.preferences["change_icon_theme"]).lower()
        volume_control_pref = self.preferences["player_volume"]


        status = playerctl.is_playing()

        if action == "prev":
            return previous(theme)
        elif action == "next":
            return next(theme)

        if status == "No_Player_Found":
            return RenderResultListAction([render_no_player()])

        items = []

        current_song = playerctl.get_current_song()

        if action == "change_player":
            player_items = []
            players = playerctl.get_players()

            for player in players.splitlines(0):

                player_items.append(
                    ExtensionResultItem(
                        icon="images/" + theme + "_change_player.png",
                        name=player.split(".")[0],
                        description="Press enter to play this player",
                        on_enter=ExtensionCustomAction(
                            {"action": "change_players", "player": player}
                        ),
                    )
                )
            return RenderResultListAction(player_items)

        items.append(
            ExtensionResultItem(
                icon="images/" + theme + "_song.png",
                name="Current Playing",
                description=current_song,
                on_enter=DoNothingAction(),
            )
        )

        if status == "Paused":
            items.append(
                ExtensionResultItem(
                    icon="images/" + theme + "_play.png",
                    name="Play",
                    on_enter=ExtensionCustomAction({"action": "playpause"}),
                )
            )
        if status == "Playing":
            items.append(
                ExtensionResultItem(
                    icon="images/" + theme + "_pause.png",
                    name="Pause",
                    on_enter=ExtensionCustomAction({"action": "playpause"}),
                )
            )

        items.append(
            ExtensionResultItem(
                icon="images/" + theme + "_next.png",
                name="Next Song",
                description="Skip current song and go to the next song",
                on_enter=ExtensionCustomAction({"action": "next"}, keep_app_open=True),
            )
        )
        items.append(
            ExtensionResultItem(
                icon="images/" + theme + "_prev.png",
                name="Previus Song",
                description="Return to previus song",
                on_enter=ExtensionCustomAction({"action": "prev"}, keep_app_open=True),
            )
        )

        # Volume control pref. @ manifest.json
        if volume_control_pref == "true":
            items.append(
                ExtensionResultItem(
                    icon="images/" + theme + "_set_volume.png",
                    name="Player volume",
                    description="Type: 'pvol 0 - 100' to set PLAYER volume",
                    on_enter=SetUserQueryAction("msc pvol "),
                )
            )

            items.append(
                ExtensionResultItem(
                    icon="images/" + theme + "_set_volume.png",
                    name="Global volume ",
                    description="Type: 'gvol 0 - 100' to set GLOBAL volume",
                    on_enter=SetUserQueryAction("msc vol "),
                )
            )
        else:
            items.append(
                ExtensionResultItem(
                    icon="images/" + theme + "_set_volume.png",
                    name="Global volume ",
                    description="Type: 'vol 0 - 100' to set volume",
                    on_enter=SetUserQueryAction("msc vol "),
                )
            )

        items.append(
            ExtensionResultItem(
                icon="images/" + theme + "_mute.png",
                name="Global mute",
                description="Press enter to mute volume",
                on_enter=ExtensionCustomAction({"action": "mute"}),
            )
        )

        items.append(
            ExtensionResultItem(
                icon="images/" + theme + "_change_player.png",
                name="Change player",
                description="Press enter to change music player",
                on_enter=ExtensionCustomAction(
                    {"action": "show_player"}, keep_app_open=True
                ),
            )
        )

        return RenderResultListAction(items)


def render_no_player():
    return ExtensionResultItem(
        icon="images/icon.png",
        name="Not playing",
        description="Please start a music player",
        on_enter=DoNothingAction(),
    )


def previous(theme):
    return RenderResultListAction(
        [
            ExtensionResultItem(
                icon="images/" + theme + "_prev.png",
                name="Previus Song",
                description="Return to previus song",
                on_enter=ExtensionCustomAction({"action": "prev"}, keep_app_open=True),
            )
        ]
    )


def next(theme):
    return RenderResultListAction(
        [
            ExtensionResultItem(
                icon="images/" + theme + "_next.png",
                name="Next Song",
                description="Skip current song and go to the next song",
                on_enter=ExtensionCustomAction({"action": "next"}, keep_app_open=True),
            )
        ]
    )


if __name__ == "__main__":
    PlayerMain().run()
