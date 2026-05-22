# piadapter-edgecmd

piadapter-edgecmd is a powershell script for working with PI adapters (only OPCUA for now),
It helps you configure and manage adapter commands from the terminal.

## What it does

- Shows adapter settings.
- Changes adapter configuration.
- Starts and stops adapter services.
- Helps with setup tasks.
- Makes repeat jobs easier.

## Why it matters

Some industrial tools are quicker to manage from the command line than from a screen.

It makes scaling a lot easier and the service footprint is also smaller

This repo puts that work together in a more user-friendly way.

## How it works

1. Read a command from the user.
2. Send it to the adapter or edge system.
3. Return the result in the terminal.
4. Let the user repeat the same steps later.

## Tech stack

- Windows Powershell
- EdgeCmd (from OSISOFT)

## Quick start (some example of the edgecmd commands)

```bash
edgecmd get version
edgecmd get components
```
