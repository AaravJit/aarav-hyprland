[main]
namespace=launcher
font=Noto Sans:size=15,Symbols Nerd Font Mono:size=15
use-bold=yes
dpi-aware=auto
terminal=kitty
layer=overlay
anchor=center

width=58
lines=10
horizontal-pad=28
vertical-pad=22
inner-pad=14
line-height=30px
letter-spacing=0.2

message=Applications
message-mode=expand
prompt=  
placeholder=Search apps, actions, and commands
match-mode=fzf
fields=name,generic,keywords,categories,filename,exec
filter-desktop=yes
show-actions=yes
match-counter=yes
icons-enabled=yes
image-size-ratio=1

[colors]
background={{colors.surface_container.default.hex_stripped}}F2
text={{colors.on_surface.default.hex_stripped}}E8
message={{colors.primary.default.hex_stripped}}FF
prompt={{colors.tertiary.default.hex_stripped}}FF
placeholder={{colors.on_surface_variant.default.hex_stripped}}B8
input={{colors.on_surface.default.hex_stripped}}FF
match={{colors.tertiary.default.hex_stripped}}FF
selection={{colors.primary_container.default.hex_stripped}}CC
selection-text={{colors.on_primary_container.default.hex_stripped}}FF
selection-match={{colors.primary.default.hex_stripped}}FF
counter={{colors.on_surface_variant.default.hex_stripped}}B8
border={{colors.outline_variant.default.hex_stripped}}C0

[border]
width=1
radius=24
selection-radius=12

[dmenu]
exit-immediately-if-empty=yes
