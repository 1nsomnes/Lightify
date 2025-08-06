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
Currently in early stage development, if and when an alpha version is realeased an installer and website will be created.
For the time being, you must install [Flutter](https://flutter.dev/) and run 

```flutter build macos```

After this you will be able to find Lightify through Spotlight or inside the releases 
folder for MacOS in the project directory. 

Additionally you will need to [create a Spoty client](https://developer.spotify.com/) and input the client ID when you run the application. 

## How does it work?
Once you have installed it, it's a simple matter of logging in. This is **NOT** a remote, you do not need to have an instance of Spotify
running to make this work. You will be able to easily search for, queue, and play music. Please note the Keybinds below for usage, particularly because none of the buttons work
right now. 

## Keybinds
| KeyBind | Action |
| - | - |
| Meta + Shift + S | Open/Close lightify (works anywhere on your Mac) |
| Esc | Close Lightify |
| Space | Play/Pause |
| H | Previous Song |
| L | Next Song |
| S | Change shuffle mode |
| R | Change repeat mode | 
| TAB | Navigate to search bar (when already not open) |
| T | Switch to track search mode |
| A | Switch to album search mode |
| P | Switch to playlist search mode |
| M | Switch to "my catalog" | 
| Enter | Run search or play selected song |
| Q | Queue selected song |
| J/Down Arrow | Navigate down list item |
| K/Up Arrow | Navigate up list item |
| Ctrl + R | Restart |
| Ctrl + D | Restart and delete cached data |


## Versions, Change Logs, Future Implementations
✅ = this version is published <br>
❌ = this version is not published

<details><summary> <h3>Future features</h3> </summary>

- [ ] Settings page
- [ ] Auto load next options when bottom of list is reached
- [ ] Auto size window when searching similar to spotlight
- [ ] Theme loader
- [ ] Consistency on tab click

</details>
<details><summary> <h3>Features for v0.1 ❌</h3> </summary>

- [x] ~Add a section to input client secrets and ids easily~
- [x] ~Add "my catalog" for tracks and albums~
- [x] ~Enable search in "my catalog"~
- [ ] Make the GUI buttons work (currently only keybinds work)
- [ ] Add a like button for songs
- [x] ~Make sure repeat mode works properly~
- [x] ~Add transfer playback shortcut~
- [ ] Create an installer 

</details>

<h3> Start of log (08/01/2025) </h3>

## Contributing
Contributions are welcome and encouraged. Document issues in the issues tab and submit PRs when you've fixed an issue. More info coming soon. 

## License
This software is distributed under the [Creative Commons Attribution-NonCommercial 4.0 International License (CC BY-NC 4.0)](LICENSE). You are granted permission to copy, modify, and personalize this code for your own non-commercial projects and experiments. However, any use of this work for commercial purposes—including selling, licensing, or incorporating it into products or services offered for profit—is expressly prohibited without obtaining a separate license.

© 2025 Cedric Claessens
