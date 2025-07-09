from ulauncher.api.client.Extension import Extension
from ulauncher.api.client.EventListener import EventListener
from ulauncher.api.shared.event import KeywordQueryEvent, ItemEnterEvent
from ulauncher.api.shared.item.ExtensionResultItem import ExtensionResultItem
from ulauncher.api.shared.action.RenderResultListAction import RenderResultListAction
from ulauncher.api.shared.action.HideWindowAction import HideWindowAction
from ulauncher.api.shared.action.OpenUrlAction import OpenUrlAction
import json
import os

class VmExtension(Extension):

    def load_vim_commands(self):
        """Load Vim commands from JSON file."""
        package_dir = os.path.dirname(os.path.abspath(__file__))
        full_path = os.path.join(package_dir, 'db', 'commands.json')   
        with open(full_path, 'r') as file:
            return json.load(file)

    def __init__(self):
        super().__init__()
        self.vim_commands = self.load_vim_commands()
        self.subscribe(KeywordQueryEvent, KeywordQueryEventListener())

class KeywordQueryEventListener(EventListener):

    def on_event(self, event, extension):
        query = event.get_argument() or ""
        items = []

        # If no query, show all commands (limited to first 8)
        commands_to_show = extension.vim_commands
        
        # If there's a query, filter commands
        if query:
            commands_to_show = [
                cmd for cmd in extension.vim_commands
                if query.lower() in cmd['command'].lower() or 
                   query.lower() in cmd['description'].lower()
            ]

        # Limit results to first 8 matches
        for cmd in commands_to_show[:8]:
            url = f"https://vim.rtorr.com/#:~:text={cmd['rtorr_description']}"
            items.append(ExtensionResultItem(
                icon='images/icon.png',
                name=cmd['command'],
                description=f"{cmd['name']} - {cmd['description']}",
                on_enter=OpenUrlAction(url)
            ))

        return RenderResultListAction(items)

if __name__ == '__main__':
    VmExtension().run()
