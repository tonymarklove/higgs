FRAME_WIDTH = 80
FRAME_HEIGHT = 110

HORIZONTAL_FRAMES = 9
VERTICAL_FRAMES = 3

ATLAS_TEXTURE = "res://Player/player_spritesheet.png"

BASE_NAME = "player_frame"

FRAME_NAMES = [
    "idle",
    "jump",
    "hurt",
    "duck",
    "fall",
    "climb1",
    "climb2",
    "cheer1",
    "cheer2",
    "walk1",
    "walk2",
    "hold1",
    "hold2",
    "action1",
    "action2",
    "kick",
    "swim1",
    "swim2",
    "talk",
    "slide",
    "hang",
    "skid",
    "back",
    "stand",
]

# -----------------------------------------------------

VERTICAL_FRAMES.times.each do |y|
    HORIZONTAL_FRAMES.times.each do |x|
        xa = x * FRAME_WIDTH
        ya = y * FRAME_HEIGHT

        file_contents = <<~TRES
        [gd_resource type="AtlasTexture" load_steps=2 format=2]

        [ext_resource path="#{ATLAS_TEXTURE}" type="Texture" id=1]

        [resource]

        flags = 4
        atlas = ExtResource( 1 )
        region = Rect2( #{xa}, #{ya}, #{FRAME_WIDTH}, #{FRAME_HEIGHT} )
        margin = Rect2( 0, 0, 0, 0 )
        filter_clip = false
        TRES

        index = (y*HORIZONTAL_FRAMES) + x
        frame_name = FRAME_NAMES[index] || index

        File.open("#{BASE_NAME}_#{frame_name}.tres", 'w') { |file| file.write(file_contents) }
    end
end
