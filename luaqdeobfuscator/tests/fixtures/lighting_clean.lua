local tweenService = game:GetService("TweenService")
local lighting = game:GetService("Lighting")

local morning = {
    Ambient = Color3.fromRGB(128, 128, 128),
    OutdoorAmbient = Color3.fromRGB(150, 150, 170),
    Brightness = 3,
    TimeOfDay = "12:00:00",
}

local nightfall = {
    Ambient = Color3.fromRGB(30, 30, 50),
    OutdoorAmbient = Color3.fromRGB(20, 20, 40),
    Brightness = 0.5,
    TimeOfDay = "00:00:00",
}

local function transitionTo(settings, duration)
    local tweenInfo = TweenInfo.new(
        duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )
    local goals = {
        Ambient = settings.Ambient,
        OutdoorAmbient = settings.OutdoorAmbient,
        Brightness = settings.Brightness,
    }

    lighting.TimeOfDay = settings.TimeOfDay
    local tween = tweenService:Create(lighting, tweenInfo, goals)
    tween:Play()
    tween.Completed:Wait()
end

task.spawn(function()
    local duration = 10
    while true do
        print("☀️ Transitioning to Morning...")
        transitionTo(morning, duration)
        task.wait(duration)

        print("🌙 Transitioning to Nightfall...")
        transitionTo(nightfall, duration)
        task.wait(duration)
    end
end)
