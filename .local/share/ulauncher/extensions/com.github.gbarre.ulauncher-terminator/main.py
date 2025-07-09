import os
import subprocess
from ulauncher.api.client.EventListener import EventListener
from ulauncher.api.client.Extension import Extension
from ulauncher.api.shared.event import KeywordQueryEvent, ItemEnterEvent
from ulauncher.api.shared.item.ExtensionResultItem import ExtensionResultItem
from ulauncher.api.shared.action.RenderResultListAction import (
    RenderResultListAction,
)
from ulauncher.api.shared.action.ExtensionCustomAction import (
    ExtensionCustomAction,
)


# Main extension class
class TerminatorExtension(Extension):
    def __init__(self):
        super().__init__()
        # Subscribe to events
        self.subscribe(KeywordQueryEvent, KeywordQueryEventListener())
        self.subscribe(ItemEnterEvent, ItemEnterEventListener())


# Listener for keyword query events
class KeywordQueryEventListener(EventListener):
    def on_event(self, event, extension):
        # Get the folder path from the user's query
        query = event.get_argument() or ""
        base_path = os.path.expanduser(query) if query else os.getcwd()

        # Get the max_results setting from preferences
        max_results = int(extension.preferences.get("max_results", 5))

        # List matching directories
        items = []
        if os.path.isdir(base_path):
            # Filter and sort directories
            directories = sorted(
                [
                    item
                    for item in os.listdir(base_path)
                    if os.path.isdir(os.path.join(base_path, item))
                    and not item.startswith(".")
                ]
            )
            # Limit the number of results
            for item in directories[:max_results]:
                item_path = os.path.join(base_path, item)
                items.append(
                    ExtensionResultItem(
                        name=item,
                        icon="images/icon.png",
                        description=f"Open {item_path}...",
                        on_enter=ExtensionCustomAction(
                            {"path": item_path},
                        ),
                    )
                )
        return RenderResultListAction(items)


# Listener for item enter events
class ItemEnterEventListener(EventListener):
    def on_event(self, event, extension):
        # Get the folder path from the event data
        folder_path = event.get_data()["path"]
        if os.path.isdir(folder_path):
            # Open Terminator in the specified folder
            subprocess.Popen(
                ["terminator", "--working-directory", folder_path]
            )
        else:
            # Notify the user if the folder is invalid
            subprocess.Popen(
                [
                    "notify-send",
                    "Invalid folder",
                    f"The folder '{folder_path}' does not exist.",
                ]
            )


# Entry point for the extension
if __name__ == "__main__":
    TerminatorExtension().run()
