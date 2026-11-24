function slack --wraps='WAYLAND_DISPLAY= /snap/slack/224/usr/lib/slack/slack --no-sandbox --ozone-platform=x11' --description 'alias slack=WAYLAND_DISPLAY= /snap/slack/224/usr/lib/slack/slack --no-sandbox --ozone-platform=x11'
  WAYLAND_DISPLAY= /snap/slack/224/usr/lib/slack/slack --no-sandbox --ozone-platform=x11 $argv
        
end
