# TPLink Smart Home Manager

## Supported models

- HS100 Smart Plug
- HS110 Smart Plug with Energy Monitor
- KL60 Smart Bulb

## If you want support for more device

Contact me! I will ask for some Python output from your device.

## Requirements

Install the `pyHS100` Python library:

`pip install pyHS100`

This extension only works for devices on the local network. You can't remotely control your switches.

## Demo

<img aligh="center" src="https://raw.githubusercontent.com/sebw/ulauncher-tplink-home-manager/master/demo/demo.gif">

## Known Issues

- Limited to plugs with static IP.

## To Do

- Implement auto-discovery, but it doesn't work properly for me (maybe because my devices are in a large subnet).
