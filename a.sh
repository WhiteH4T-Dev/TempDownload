

sudo pacman -S base-devel
sudo pacman -S git
cd /opt
sudo git clone https://aur.archlinux.org/yay.git
sudo chown -R user ./yay
cd yay
makepkg -si
cd /home/user/
clear
yay -S bspwm polybar sxhkd eww dunst rofi lsd jq checkupdates-aur \
playerctl mpd ncmpcpp mpc picom-arian8j2-git xtitle termite betterlockscreen \
ttf-jetbrains-mono nerd-fonts-jetbrains-mono ttf-terminus-nerd ttf-inconsolata \
ttf-joypixels nerd-fonts-cozette-ttf scientifica-font \
feh maim pamixer libwebp webp-pixbuf-loader xorg-xkill papirus-icon-theme
mkdir .config/
mkdir .config/alacritty
mkdir .local/share/fonts
git clone --depth=1 https://github.com/gh0stzk/dotfiles.git
cd dotfiles
cp -r config/bspwm ~/.config/bspwm
cp -r config/termite ~/.config/termite
cp -r misc/fonts/* ~/.local/share/fonts/
cp -r misc/bin ~/.local/
cp -r misc/applications ~/.local/share/
cp -r misc/asciiart ~/.local/share/
fc-cache -rv
cp -r home/.zshrc ~/.zshrc
cp -r config/zsh ~/.config/zsh
cd ..
# For automatically launching mpd on login
systemctl --user enable mpd.service
systemctl --user start mpd.service
chmod +x ~/.config/bspwm/bspwmrc
chown $USER ~/.config/bspwm/rice.cfg
chmod +x ~/.config/bspwm/scripts/{external_rules,getSongDuration,music,RandomWall,hu-polybar,LaunchWorld,RiceSelector,screenshoter,updates.sh,WeatherMini}
# In Cristina, Pamela, Andrea & z0mbi3 Rices, you need to give execution permissions to the shell scripts too.
chmod +x ~/.config/bspwm/rices/pamela/widgets/{calendar,calendarlauncher,mplayer-launcher,power-launcher,profile-sys-launcher}
chmod +x ~/.config/bspwm/rices/andrea/arin/sidedar/toggle_sidebar
chmod +x ~/.config/bspwm/rices/andrea/arin/scripts/{battery,check-network,music_info,quotes,sys_info,system,volume.sh,widget_apps,widget_search}
chmod +x ~/.config/bspwm/rices/cristina/widgets/mplayer-launcher
chmod +x ~/.config/bspwm/rices/z0mbi3/bar/scripts/{battery,calendar,popup,volume.sh,wifi,workspace}
chmod +x ~/.config/bspwm/rices/z0mbi3/dashboard/LaunchInfoCenter.sh
chmod +x ~/.config/bspwm/rices/z0mbi3/dashboard/scripts/weather
rm -r dotfiles
#https://gitlab.com/dwt1/dotfiles/-/raw/master/.config/alacritty/alacritty.yml
yay -S picom-jonaburg-git
