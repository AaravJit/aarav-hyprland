[main]
font=Noto Sans:size=14
terminal=kitty
layer=overlay
anchor=center

width=48
lines=12

horizontal-pad=22
vertical-pad=14
inner-pad=10

prompt=Search >
placeholder=Applications and commands
match-mode=fzf

[colors]
background={{colors.surface_container.default.hex_stripped}}EB
text={{colors.on_surface.default.hex_stripped}}FF
prompt={{colors.primary.default.hex_stripped}}FF
placeholder={{colors.on_surface_variant.default.hex_stripped}}FF
input={{colors.on_surface.default.hex_stripped}}FF
match={{colors.tertiary.default.hex_stripped}}FF
selection={{colors.primary_container.default.hex_stripped}}A8
selection-text={{colors.on_primary_container.default.hex_stripped}}FF
selection-match={{colors.primary.default.hex_stripped}}FF
border={{colors.outline_variant.default.hex_stripped}}A0

[border]
width=1
radius=14

[dmenu]
exit-immediately-if-empty=yes
