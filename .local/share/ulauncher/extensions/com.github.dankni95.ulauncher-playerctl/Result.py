class Result:
    def __init__(self, icon, name, description, on_enter, desc={}):
        self.desc = desc  # whitelist items, if necessary
        self.icon = icon
        self.name = name
        self.description = description
        self.on_enter = on_enter

        def __str__(self):
            # invent our own "destructuring" syntax
            [icon, name, description, on_enter] = destructure(
                self.desc, "icon", "name", "description", "on_enter"
            )

            return f"{icon} {name} {description} {on_enter}"


def destructure(d, *keys):
    return [d[k] if k in d else None for k in keys]
