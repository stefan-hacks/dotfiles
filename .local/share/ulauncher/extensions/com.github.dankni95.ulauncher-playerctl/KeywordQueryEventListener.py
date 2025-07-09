from ulauncher.api.client.EventListener import EventListener
from ulauncher.api.shared.action.RenderResultListAction import RenderResultListAction
from ulauncher.api.shared.action.ExtensionCustomAction import ExtensionCustomAction
from ulauncher.api.shared.action.DoNothingAction import DoNothingAction
from ulauncher.api.shared.item.ExtensionResultItem import ExtensionResultItem
from Result import Result


class KeywordQueryEventListener(EventListener):
    def on_event(self, event, extension):
        theme = str(extension.preferences["change_icon_theme"]).lower()
        volume_control_pref = extension.preferences["player_volume"]
        global_ = extension.preferences["player_volume"]

        args = event.get_argument()
        items = []

        if args is not None:

            items.append(
                make_result(
                    icon="images/" + theme + "_pause.png",
                    name="Pause",
                    description="Pause song",
                    on_enter=ExtensionCustomAction({"action": "playpause"}),
                )
            )
            items.append(
                make_result(
                    icon="images/" + theme + "_play.png",
                    name="Play",
                    description="Play song",
                    on_enter=ExtensionCustomAction({"action": "playpause"}),
                )
            )

            items.append(
                make_result(
                    icon="images/" + theme + "_next.png",
                    name="Next Song",
                    description="Skip current song and go to next song",
                    on_enter=ExtensionCustomAction(
                        {"action": "next"}, keep_app_open=True
                    ),
                )
            )
            items.append(
                make_result(
                    icon="images/" + theme + "_prev.png",
                    name="Previus Song",
                    description="Return to previus song",
                    on_enter=ExtensionCustomAction(
                        {"action": "prev"}, keep_app_open=True
                    ),
                )
            )

            # Volume control pref. @ manifest.json
            if volume_control_pref == "true":
                items.append(
                    make_result(
                        icon="images/" + theme + "_set_volume.png",
                        name="pvol",
                        description="Set player volume between 0 - 100%",
                        on_enter=ExtensionCustomAction(
                            {
                                "action": "set_vol",
                                "amount": args,
                                "global_or_player": volume_control_pref,
                            }
                        ),
                    )
                )

                items.append(
                    make_result(
                        icon="images/" + theme + "_set_volume.png",
                        name="gvol",
                        description="Set global volume between 0 - 100%",
                        on_enter=ExtensionCustomAction(
                            {
                                "action": "set_vol",
                                "amount": args,
                                "global_or_player": False,
                            }
                        ),
                    )
                )

            else:
                items.append(
                    make_result(
                        icon="images/" + theme + "_set_volume.png",
                        name="vol",
                        description="Set global volume between 0 - 100%",
                        on_enter=ExtensionCustomAction(
                            {
                                "action": "set_vol",
                                "amount": args,
                                "global_or_player": volume_control_pref,
                            }
                        ),
                    )
                )

            items.append(
                make_result(
                    icon="images/" + theme + "_mute.png",
                    name="Global mute",
                    description="Press enter to mute volume",
                    on_enter=ExtensionCustomAction({"action": "mute"}),
                )
            )

            items.append(
                make_result(
                    icon="images/" + theme + "_change_player.png",
                    name="Change player",
                    description="Press enter to change music player",
                    on_enter=ExtensionCustomAction(
                        {"action": "show_player"}, keep_app_open=True
                    ),
                )
            )

        for result in items:
            if (
                result.name.lower().startswith(args.lower())
                or args.lower() in result.name.lower()
                or result.name.lower() in args.lower()
            ):  # lol!
                return RenderResultListAction(
                    [
                        ExtensionResultItem(
                            icon=result.icon,
                            name=result.name,
                            description=result.description,
                            on_enter=result.on_enter,
                        )
                    ]
                )

        return extension.render_main_page(None)


def make_result(icon, name, description, on_enter):
    result = Result(icon=icon, name=name, description=description, on_enter=on_enter)
    return result
