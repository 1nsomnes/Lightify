<h1 align="center">Lightify</h1>
<p align="center">
  
  <a href="https://creativecommons.org/licenses/by-nc/4.0/">
	    <img src="https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey.svg" />
	</a> 

</p> 

<p align="center">
  <img src="https://github.com/user-attachments/assets/05d1a215-9486-4c38-8dd8-81f4b5f19e4e"
       alt="lightify gif"
       width="500" />
</p>

<h3 align="center">
  Spotlight style Spotify client with a clean glass theme and vim-like keybinds for MacOS.
</h3>

## Table of Contents
1. [Installation](#installation)
2. [How does it work?](#how-does-it-work)
3. [Keybinds](#keybinds)
4. [Versions, Change Logs, Future Implementations](#versions-change-logs-future-implementations)
5. [Contributing](#contributing)
6. [License](LICENSE)

## Installation
1. Download the `.dmg` from the [latest release](https://github.com/1nsomnes/Lightify/releases/latest).
2. Open it and drag Lightify into your Applications folder.
3. Create an app on the [Spotify developer dashboard](https://developer.spotify.com/dashboard) with the redirect URI `http://127.0.0.1:3434` and the Web API and Web Playback SDK enabled.
4. Launch Lightify, paste in your app's client ID, and log in. After that, Meta + Shift + S opens and closes it from anywhere.

Why your own client ID? Spotify limits each developer app to a small number of users, so one shared ID can't work for everyone. Playback requires Spotify Premium.

## How does it work?
Lightify is a real Spotify player, not a remote: music plays from Lightify itself, so you don't need the Spotify app open. Press Meta + Shift + S anywhere to bring it up, search, play or queue something, and it gets out of your way when you click elsewhere. It's built to be driven from the keyboard, see the keybinds below. Ctrl + T moves playback over from another device.

## Keybinds
| KeyBind | Action |
| - | - |
| Meta + Shift + S | Open/Close lightify (works anywhere on your Mac) |
| Esc | Close the current pop up page, or Lightify if none is open |
| Space | Play/Pause |
| H | Previous Song |
| L | Next Song |
| S | Change shuffle mode |
| R | Change repeat mode | 
| TAB | Navigate to search bar (when already not open) |
| T | Show/hide tracks in the results |
| A | Show/hide albums in the results |
| P | Show/hide playlists in the results |
| M | Switch to "my catalog" | 
| Enter | Run search or play selected song |
| Q | Queue selected song |
| Shift + Q | Open the queue |
| Shift + C | Select the currently playing song |
| Shift + H / Shift + L | Seek back / forward (hold to keep seeking; step in settings) |
| Shift + S | Open settings (J/K select, H/L adjust, R reset) |
| Shift + A | Open the selected item's album (tracks/albums) |
| Shift + O | Open the selected playlist or album |
| Shift + P | Open the selected item's artist (tracks/albums) or owner's profile (playlists) |
| J/Down Arrow | Navigate down list item |
| K/Up Arrow | Navigate up list item |
| Ctrl + T | Move playback from another device to Lightify |
| Ctrl + R | Restart |
| Ctrl + D | Restart and delete cached data |

## Contributing
Contributions are welcome and encouraged. 

Please visit the issues tab to see what needs to be done. Check to see if anyone has been working on it so you don't do redundant work.

Send in a PR when you've fixed an issue and I might or might not merge it.

This is a small project so if anyone sends in a review I will probably code review everything. 

## License
This software is distributed under the [Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)](LICENSE). You are granted permission to copy, modify, and personalize this code for your own non-commercial projects and experiments. However, any use of this work for commercial purposes—including selling, licensing, or incorporating it into products or services offered for profit—is expressly prohibited without obtaining a separate license.

© 2026 Cedric Claessens
