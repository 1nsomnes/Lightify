<h1 align="center">Lightify</h1>

<p align="center">
  <img src="https://github.com/user-attachments/assets/05d1a215-9486-4c38-8dd8-81f4b5f19e4e"
       alt="lightify gif"
       width="500" />
</p>

<h3 align="center">
  Spotlight style Spotify client with a clean glass theme and vim-like keybinds for MacOS.
</h3>

# Installing
Currently in early stage development, if and when an alpha version is realeased an installer and website will be created.
For the time being, you must install [Flutter](https://flutter.dev/) and run 

```flutter build macos```

After this you will be able to find Lightify through Spotlight or inside the releases 
folder for MacOS in the project directory. 

Additionally before building the application you will need to add your own client secret, in a `.env` file, this is because Spotify
no longer allows developers to easily create and share apps anymore. This is a painful process but coming soon I will add an easier place to
inut client secrents. Please visit the [Spotify Developer Portal](https://developer.spotify.com/dashboard) to learn more about how to create an app.

# How it works?
Once you have installed it, it's a simple matter of logging in. This is **NOT** a remote, you do not need to have an instance of Spotify
running to make this work. You will be able to easily search for, queue, and play music. Please note the Keybinds below for usage, particularly because none of the buttons work
right now. 

# Keybinds
| KeyBind | Action |
| - | - |
| Meta + Shift + S | Open/Close lightify (works anywhere on your Mac) |
| Esc | Close Lightify |
| Space | Play/Pause |
| H | Previous Song |
| L | Next Song |
| S | Navigate to search bar (when already not open) |
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

# Alpha Release TODOs 
- [ ] Add a section to input client secrets and ids easily
- [ ] Settings page
- [ ] Auto load next options when bottom of list is reached
- [ ] Add "my catalog" for tracks and albums
- [ ] Enable search in "my catalog"
- [ ] Make the buttons work (currently only keybinds work)
- [ ] Add a like button for songs
- [ ] Auto size window when searchingsimilar to spotlight 
- [ ] Theme loader
- [ ] Create an installer 

# Contributing
Contributions are welcome, document issues in the issues tab and submit PRs when you've fixed an issue. 
