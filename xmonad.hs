import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Util.Run

main :: IO ()
main = do
    -- Khởi tạo Xmobar
    xmproc <- spawnPipe "xmobar"
    
    -- Cấu hình XMonad với thanh trạng thái Xmobar
    xmonad $ def
        { terminal    = "alacritty"  -- Terminal mặc định
        , modMask     = mod4Mask      -- Sử dụng phím SUPER làm phím chính
        , borderWidth = 2             -- Độ dày viền cửa sổ
        , focusedBorderColor = "#ff0000" -- Màu viền cửa sổ đang được chọn
        , logHook     = dynamicLogWithPP xmobarPP { ppOutput = hPutStrLn xmproc }
        }
