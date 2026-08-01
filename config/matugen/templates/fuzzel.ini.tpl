[main]
namespace=launcher
font=Noto Sans:size=14,Symbols Nerd Font Mono:size=14
use-bold=yes
dpi-aware=auto
terminal=kitty
layer=overlay
anchor=center

width=50
lines=9
horizontal-pad=18
vertical-pad=12
inner-pad=8
line-height=24px
letter-spacing=0

prompt=
placeholder=Search applications
match-mode=fzf
fields=name,generic,keywords,categories,filename,exec
filter-desktop=yes
show-actions=yes
match-counter=yes
icons-enabled=yes
image-size-ratio=1

[colors]
background={{colors.surface_container.default.hex_stripped}}F0
text={{colors.on_surface.default.hex_stripped}}EE
prompt={{colors.primary.default.hex_stripped}}FF
placeholder={{colors.on_surface_variant.default.hex_stripped}}C8
input={{colors.on_surface.default.hex_stripped}}FF
match={{colors.tertiary.default.hex_stripped}}FF
selection={{colors.primary_container.default.hex_stripped}}E6
selection-text={{colors.on_primary_container.default.hex_stripped}}FF
selection-match={{colors.primary.default.hex_stripped}}FF
counter={{colors.on_surface_variant.default.hex_stripped}}D0
border={{colors.primary.default.hex_stripped}}90

[border]
width=1
radius=18
selection-radius=9

[dmenu]
exit-immediately-if-empty=yes
