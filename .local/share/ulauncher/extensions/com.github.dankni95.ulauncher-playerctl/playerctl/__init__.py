import subprocess
import logging


logger = logging.getLogger(__name__)

# Run a command line command and returns stdout


def _run(command):
    result = subprocess.run(command, check=True, stdout=subprocess.PIPE, text=True)
    print(result.stdout)
    return result.stdout


def is_playing():

    result = subprocess.run(
        ["playerctl", "--player", "playerctld", "status"], capture_output=True
    )
    logger.debug(result.stdout)

    result = str(result.stdout)
    if result is not None and "Playing" in result:
        return "Playing"
    elif result is not None and "Paused" in result:
        return "Paused"
    else:
        return "No_Player_Found"


# Get current song


def get_current_song():
    return _run(
        [
            "playerctl",
            "metadata",
            "--format",
            "Now playing: {{ artist }} - {{ title }} | {{playerName}}",
        ]
    )


# Skip to next song


def next():
    _run(["playerctl", "--player", "playerctld", "next"])


def volume(amount, control_player):

    amount = str(amount)

    if control_player == "true":
        current_player = _run(["playerctl", "metadata", "--format", '"{{playerName}}"'])
        current_player = current_player.split("\n")

        command = (
            "pactl list sink-inputs | grep --ignore-case -B 18 'application.name = "
            + current_player[0]
            + "'"
        )
        sinks = subprocess.run(
            (command), shell=True, universal_newlines=True, stdout=subprocess.PIPE
        )
        sink_lines = sinks.stdout.splitlines()

        for line in sink_lines:
            if "Sink Input #" in line:
                player_id = line.split("#")[1]

        _run(["pactl", "set-sink-input-volume", player_id, amount + "%"])

    else:
        _run(["pactl", "set-sink-volume", "@DEFAULT_SINK@", amount + "%"])


def prev():
    _run(["playerctl", "--player", "playerctld", "previous"])


def playpause():
    _run(["playerctl", "--player", "playerctld", "play-pause"])


def mute(amount):
    _run(["pactl", "set-sink-volume", "0", amount + "%"])


def get_players():
    return _run(["playerctl", "-l"])


def change_player(player):
    _run(["playerctl", "--all-players", "pause"])
    _run(["playerctl", "--player=" + player, "play"])
    _run(["playerctl", "--player=" + player, "pause"])
    _run(["playerctl", "--player=" + player, "play-pause"])
